classdef Remote < handle

  properties
    hostIP;
    hostPort;
  end
  
  methods
    function rem = Remote(hostIP, hostPort)
      rem.hostIP = hostIP;
      rem.hostPort = hostPort;
      profile on;
    end
    function response = Send(rem, msgArr)
      %function imports
      import java.io.*;
      import java.net.Socket;
      for n = 1:length(msgArr)
        msg = msgArr(n);
        %connect to the socket host
        socket = Socket(rem.hostIP, rem.hostPort);
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
        if ~(strcmp(response(n).Msg, '') == 1)
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
  end

end
