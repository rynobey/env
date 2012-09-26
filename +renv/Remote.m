classdef Remote < handle

  properties
    hostName;
    hostPort;
    ftpTemp; % must be on accessible ftp path
    remoteWD;
    remoteFtp;
    ftpObj;
  end
  
  methods
    function rem = Remote(hostName, hostPort)
      rem.hostName = hostName;
      rem.hostPort = hostPort;
      rem.loadConfig;
      uname = input('FTP Username: ', 's');
      pass = input('FTP Password: ', 's');
      rem.ftpObj = ftp(rem.hostName, uname, pass);
      cd(rem.ftpObj, rem.ftpTemp);
    end
    function response = Request(rem, msgArr)
      %function imports
      import java.io.*;
      import java.net.Socket;
      for n = 1:length(msgArr)
        msg = msgArr(n);
        %connect to the socket host
        socket = Socket(rem.hostName, rem.hostPort);
        %get data io streams
        iStream   = socket.getInputStream;
        dInputStream = DataInputStream(iStream);
        oStream   = socket.getOutputStream;
        dOutputStream = DataOutputStream(oStream);
        %send data
        commandText = msg.GetRawXML;
        dOutputStream.writeBytes(char(commandText));
        dOutputStream.flush;
        %get response data
        NBytes = iStream.available;
        while NBytes == 0
            pause(0.1);
            NBytes = iStream.available;
        end
        RawResponse = zeros(1, NBytes, 'uint8');
        for i = 1:NBytes
            RawResponse(i) = dInputStream.readByte;
        end
        RawResponse = char(RawResponse(41:end));
        response(n) = renv.Message(RawResponse);
        c1 = strcmp(response(n).Msg, 'True');
        c2 = strcmp(response(n).Msg, 'False');
        if ~(strcmp(response(n).Msg, '') == 1) && c1 && c2
          disp(response(n).Msg)
        end
        %release objects / cleanup
        iStream.close;
        dInputStream.close;
        dOutputStream.flush;
        oStream.close;
        dOutputStream.close;
        socket.close;
      end
    end
    function Send(rem, msgArr)
      %function imports
      import java.io.*;
      import java.net.Socket;
      for n = 1:length(msgArr)
        msg = msgArr(n);
        %connect to the socket host
        socket = Socket(rem.hostName, rem.hostPort);
        %get data io streams
        iStream   = socket.getInputStream;
        dInputStream = DataInputStream(iStream);
        oStream   = socket.getOutputStream;
        dOutputStream = DataOutputStream(oStream);
        %send data
        commandText = msg.GetRawXML;
        dOutputStream.writeBytes(char(commandText));
        dOutputStream.flush;
        %release objects / cleanup
        iStream.close;
        dInputStream.close;
        dOutputStream.flush;
        oStream.close;
        dOutputStream.close;
        socket.close;
      end
    end
    function Upload(rem, sourcePath, destPath)
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
        msg = renv.Message.New('CopyDir', sprintf('%s;%s', tempPath, destPath));
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
      elseif exist(sourcePath, 'file') == 2 % if source is a file
        msg = renv.Message.New('CopyFile', sprintf('%s;%s', tempPath, destPath));
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
        rem.ftpRoot = 'D:\\ftproot\work\Backup\Ryno\ftpTemp';
        rem.ftpTemp = '/Backup/Ryno/ftpTemp';
        rem.remoteWD = 'D:\\ftproot\work\Backup\Ryno\simwd';
      elseif strcmp(rem.hostName, 'ee430030.ee.sun.ac.za')
        % running cst on marvin
        rem.ftpRoot = 'D:\\ftproot\work\Ryno\ftpTemp';
        rem.ftpTemp = '/Ryno/ftpTemp';
        rem.remoteWD = 'D:\\ftproot\work\Ryno\simwd';
      elseif strcmp(rem.hostName, '192.168.1.104')
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
