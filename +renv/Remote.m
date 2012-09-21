classdef Remote < handle

  properties
    hostIP;
    hostPort;
  end
  
  methods
    function rem = Remote(hostIP, hostPort)
      rem.hostIP = hostIP;
      rem.hostPort = hostPort;
    end
    function response = SendCommand(rem, commandText)
      %function imports
      import java.io.*;
      import java.net.Socket;
      
      %connect to the socket host
      socket = Socket(rem.hostIP, rem.hostPort);

      %get data io streams
      iStream   = socket.getInputStream;
      dInputStream = DataInputStream(iStream);
      oStream   = socket.getOutputStream;
      dOutputStream = DataOutputStream(oStream);

      fprintf(1, 'Connected to server\n');
      
      %send data
      dOutputStream.writeBytes(char(commandText));
      dOutputStream.flush;

      %get response data
      pause(0.5);
      NBytes = iStream.available;
      fprintf(1, 'Reading %d bytes\n', NBytes);
      
      response = zeros(1, NBytes, 'uint8');
      for i = 1:NBytes
          response(i) = dInputStream.readByte;
      end
      
      response = char(response);

      %release objects / cleanup
      iStream.close;
      dInputStream.close;
      dOutputStream.flush;
      oStream.close;
      dOutputStream.close;
      socket.close;
    end
    function response = SendCommands(rem, commandTextArr)
      %function imports
      import java.io.*;
      import java.net.Socket;
      
      %connect to the socket host
      socket = Socket(rem.hostIP, rem.hostPort);

      %get data io streams
      iStream   = socket.getInputStream;
      dInputStream = DataInputStream(iStream);
      oStream   = socket.getOutputStream;
      dOutputStream = DataOutputStream(oStream);

      fprintf(1, 'Connected to server\n');
      
      %send data
      for n = 1:length(commandTextArr)
        commandText = commandTextArr{n};
        dOutputStream.writeBytes(char(commandText));
        dOutputStream.flush;

        %get response data
        pause(0.5);
        NBytes = iStream.available;
        fprintf(1, 'Reading %d bytes\n', NBytes);
        response = zeros(1, NBytes, 'uint8');
        for i = 1:NBytes
            response(i) = dInputStream.readByte;
        end
        response = char(response)
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

end
