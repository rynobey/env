classdef Remote < handle

  properties
    hostName;
    hostPort;
    ftpTemp; % must be on accessible ftp path
    remoteWD;
    remoteFtp;
    ftpObj;
    msgArr = renv.Message.empty(1,0);
    sendTimer;
    rcvTimer;
    schedTimer;
    socket;
    iStream;
    dInputStream;
    oStream;
    dOutputStream;
  end
  
  methods
    function rem = Remote(hostName, hostPort)        
        %function imports
        import java.io.*;
        import java.net.Socket;
        rem.hostName = hostName;
        rem.hostPort = hostPort;
        rem.loadConfig;
        uname = input('FTP Username: ', 's');
        %uname = 'Ryno';
        pass = input('FTP Password: ', 's');
        %pass = 'ftppass';
        rem.ftpObj = ftp(rem.hostName, uname, pass);
        cd(rem.ftpObj, rem.ftpTemp);
        rem.sendTimer = timer('StartDelay', 0, 'BusyMode', 'queue', ...
            'ExecutionMode', 'fixedSpacing', 'TasksToExecute', 1);
        rem.rcvTimer = timer('StartDelay', 0, 'BusyMode', 'queue', ...
            'ExecutionMode', 'fixedSpacing', 'TasksToExecute', 1);
        rem.schedTimer = timer('StartDelay', 0.1, 'BusyMode', 'queue', ...
            'ExecutionMode', 'fixedSpacing', 'TasksToExecute', 1);
        rem.setupTimer;
        %connect to the socket host
        try
            rem.socket = Socket(rem.hostName, rem.hostPort);
            rem.socket.setSendBufferSize(8192000);
            %get data io streams
            rem.iStream   = rem.socket.getInputStream;
            rem.dInputStream = DataInputStream(rem.iStream);
            rem.oStream   = rem.socket.getOutputStream;
            rem.dOutputStream = DataOutputStream(rem.oStream);
        catch
            disp('Unable to connect to server!');
        end
    end
    function setupTimer(rem)        
        rem.sendTimer.TimerFcn = {@renv.SendCallback, rem};
        rem.sendTimer.StopFcn = {@renv.SetupSchedTimer, 'Send', rem};
        start(rem.sendTimer);
    end
    function Send(rem, msg)
        wait(rem.sendTimer);
        rem.msgArr{end + 1} = msg;
    end
    function response = Request(rem, msg)
      rem.stopTimers;
      renv.ReceiveCallback([], [], rem);
      commandText = '<Tx>';
      commandText = sprintf('%s\n%s', commandText, msg.GetRawXML);
      commandText = sprintf('%s\n%s', commandText, '</Tx>');
      rem.dOutputStream.writeBytes(char(commandText));
      rem.dOutputStream.flush;
      NBytes = rem.iStream.available;
      while NBytes <= 1
        pause(0.1);
        NBytes = rem.iStream.available;
      end
      RawResponse = zeros(1, NBytes, 'uint8');
      index = 1;
      for i = 1:NBytes
        byte = rem.dInputStream.readByte;
        if byte ~= 0
          RawResponse(index) =  byte;
          offset = find(RawResponse == '<', 1, 'first') + 40;
          c1 = length(strfind(char(RawResponse(offset:end)), '<Message'));
          c2 = length(strfind(char(RawResponse(offset:end)), '</Message>'));
          c3 = length(strfind(char(RawResponse(offset:end)), '<Message/>'));
          c4 = length(strfind(char(RawResponse(offset:end)), '<Message />'));
          if (c1 > 0 && c2 > 0) || c3 > 0 || c4 > 0
            response = renv.Message(char(RawResponse(offset:end)));
            RawResponse = [];
            index = 0;
            break;
          end
        else
          index = index - 1;
        end
        index = index + 1;
      end            
      rem.setupTimer;
    end
    function Upload(rem, sourcePath, destPath, varargin)
      overwrite = 0;
      if length(varargin) == 1
        overwrite = varargin{1};
      end
      if sourcePath(end) == filesep
        sourcePath = sourcePath(1:end-1);
      end
      newPath = sourcePath;
      tempPath = rem.remoteFtp;
      if length(find(sourcePath == filesep, 1, 'last')) > 0
        newPath = sourcePath(find(sourcePath == filesep, 1, 'last')+1:end);
      end
      tempPath = sprintf('%s\\%s', tempPath, newPath);
      newPath = sprintf('%s\\%s', destPath, newPath);
      mput(rem.ftpObj, sourcePath);
      if exist(sourcePath, 'dir') == 7 % if source is a folder
        msg = renv.Message.New('DirExists', destPath);
        response = rem.Request(msg);
        cond1 = (overwrite == 0 && strcmp(response.Msg, 'False'));
        cond2 = (overwrite == 1);
        if cond1 || cond2
          if overwrite == 1
            msg = renv.Message.New('CopyDir', sprintf('%s;%s;True', tempPath, destPath));
          else
            msg = renv.Message.New('CopyDir', sprintf('%s;%s;False', tempPath, destPath));
          end
          rem.Request(msg);
          msg = renv.Message.New('RMDir', tempPath);
          rem.Request(msg);
          msg = renv.Message.New('DirExists', tempPath);
          if strcmp(rem.Request(msg).Msg, 'True')
            disp('Temporary files were not deleted');
          end
          msg = renv.Message.New('DirExists', newPath);
          if strcmp(rem.Request(msg).Msg, 'False')
            disp('Files were not copied');
          end
        else
          disp('Upload failed: destination file/folder already exists!');
        end
      elseif exist(sourcePath, 'file') == 2 % if source is a file
        msg = renv.Message.New('FileExists', destPath);
        response = rem.Request(msg);
        cond1 = (overwrite == 0 && strcmp(response.Msg, 'False'));
        cond2 = (overwrite == 1);
        if cond1 || cond2
          if overwrite == 1
            msg = renv.Message.New('CopyFile', sprintf('%s;%s;True', tempPath, destPath));
          else
            msg = renv.Message.New('CopyFile', sprintf('%s;%s;False', tempPath, destPath));
          end
          rem.Request(msg);
          msg = renv.Message.New('RMFile', tempPath);
          rem.Request(msg);
          msg = renv.Message.New('FileExists', tempPath);
          if strcmp(rem.Request(msg).Msg, 'True')
            disp('Temporary file was not deleted');
          end
          msg = renv.Message.New('FileExists', newPath);
          if strcmp(rem.Request(msg).Msg, 'False')
            disp('File was not copied');
          end
        else
          disp('Upload failed: destination file/folder already exists!');
        end
      end
    end
    function Download(rem, sourcePath, destPath)
      if sourcePath(end) == '\'
        sourcePath = sourcePath(1:end-1);
      end
      if destPath(end) == filesep
        destPath = destPath(1:end-1);
      end
      newPath = sourcePath;
      tempPath = rem.remoteFtp;
      if length(find(sourcePath == '\', 1, 'last')) > 0
        newPath = sourcePath(find(sourcePath == '\', 1, 'last')+1:end);
      end
      tempPath = sprintf('%s\\%s', tempPath, newPath);
      ftpPath = strrep(strrep(tempPath, rem.remoteFtp, ''), '\', '');
      newPath = sprintf('%s%s%s', destPath, filesep, newPath);
      msgDir = renv.Message.New('DirExists', sourcePath);
      msgFile = renv.Message.New('FileExists', sourcePath);
      if strcmp(rem.Request(msgDir).Msg, 'True') % if source is a folder
        msg = renv.Message.New('CopyDir', sourcePath, rem.remoteFtp, 'True');
        rem.Request(msg);
        mget(rem.ftpObj, ftpPath, destPath);
        msg = renv.Message.New('RMDir', tempPath);
        rem.Request(msg);
        msg = renv.Message.New('DirExists', tempPath);
        if strcmp(rem.Request(msg).Msg, 'True')
          disp('Temporary files were not deleted');
        end
      elseif strcmp(rem.Request(msgFile).Msg, 'True') % if source is a file
        msg = renv.Message.New('CopyFile', sourcePath, rem.remoteFtp, 'True');
        rem.Request(msg);
        mget(rem.ftpObj, ftpPath, destPath);
        msg = renv.Message.New('RMFile', tempPath);
        rem.Request(msg);
        msg = renv.Message.New('FileExists', tempPath);
        if strcmp(rem.Request(msg).Msg, 'True')
          disp('Temporary file was not deleted');
        end
      else
        disp('Source does not exist!');
      end
    end
    function ListWorkers(rem)
      msg = renv.Message.New('ListWorkers');
      disp(rem.Request(msg).Msg);
    end
    function ListProcs(rem)
      msg = renv.Message.New('ListProcs');
      disp(rem.Request(msg).Msg);
    end
    function stopTimers(rem) 
      try
        wait(rem.sendTimer);
        stop(rem.schedTimer);
        stop(rem.sendTimer);
        stop(rem.rcvTimer);
      end
    end
    function delete(rem)
      try
        rem.stopTimers();
        delete(rem.sendTimer);
        delete(rem.rcvTimer);
        delete(rem.schedTimer);
      end
      %release objects / cleanup
      rem.socket.shutdownInput;
      rem.socket.shutdownOutput;
      rem.iStream.close;
      rem.dInputStream.close;
      rem.dOutputStream.flush;
      rem.oStream.close;
      rem.dOutputStream.close;
      rem.socket.close;
    end
  end
  methods (Hidden)
    function loadConfig(rem)
      if strcmp(rem.hostName, 'localhost')
        % running matlab and cst on same machine
        rem.remoteFtp = 'D:\\ryno\Documents\2012\Uni\m\ftpTemp';
        rem.ftpTemp = '/2012/Uni/m/ftpTemp';
        rem.remoteWD = 'D:\\ryno\Documents\2012\Uni\m\simwd';
      elseif strcmp(rem.hostName, 'ee423328.ee.sun.ac.za')
        % running cst on tusker
        rem.remoteFtp = 'D:\\ftproot\work\Backup\Ryno\ftpTemp';
        rem.ftpTemp = '/Backup/Ryno/ftpTemp';
        rem.remoteWD = 'D:\\ftproot\work\Backup\Ryno\simwd';
      elseif strcmp(rem.hostName, 'ee430030.ee.sun.ac.za')
        % running cst on marvin
        rem.remoteFtp = 'D:\\ftproot\work\Ryno\ftpTemp';
        rem.ftpTemp = '/Ryno/ftpTemp';
        rem.remoteWD = 'D:\\ftproot\work\Ryno\simwd';
      elseif strcmp(rem.hostName, '192.168.1.101')
        % running cst on laptop @ flat
        rem.remoteFtp = 'D:\\ryno\Documents\2012\Uni\m\ftpTemp';
        rem.ftpTemp = '/2012/Uni/m/ftpTemp';
        rem.remoteWD = 'D:\\ryno\Documents\2012\Uni\m\simwd';
      elseif strcmp(rem.hostName, '192.168.1.202')
        % running cst on laptop @ office
        rem.remoteFtp = 'D:\\ryno\Documents\2012\Uni\m\ftpTemp';
        rem.ftpTemp = '/2012/Uni/m/ftpTemp';
        rem.remoteWD = 'D:\\ryno\Documents\2012\Uni\m\simwd';
      end
    end
  end
  
end
