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
      commandText = sprintf('%s', commandText);
      dOutputStream.writeBytes(char(commandText));
      dOutputStream.flush;

      %get response data
      NBytes = iStream.available;
        while NBytes == 0
            pause(0.1);
            NBytes = iStream.available;
        end
      fprintf(1, 'Reading %d bytes\n', NBytes);
      
      response = zeros(1, NBytes, 'uint8');
      for i = 1:NBytes
          response(i) = dInputStream.readByte;
      end
      response = char(response(41:end));
      SBIStream = java.io.StringBufferInputStream(response);
      XMLFactory = javax.xml.parsers.DocumentBuilderFactory.newInstance();
      XMLDocument = XMLFactory.newDocumentBuilder.parse(SBIStream);
      XMLDocument.normalizeDocument();
      
      Success = rem.GetNodeText(XMLDocument, 'Success')
      Command = rem.GetNodeText(XMLDocument, 'Command')
      Params = rem.GetNodeText(XMLDocument, 'Params')
      Msg = rem.GetNodeText(XMLDocument, 'Msg')
      
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
        commandText = sprintf('%s', commandText);
        dOutputStream.writeBytes(char(commandText));
        dOutputStream.flush;

        %get response data
        NBytes = iStream.available;
        while NBytes == 0
            pause(0.1);
            NBytes = iStream.available;
        end
            
        fprintf(1, 'Reading %d bytes\n', NBytes);
        response = zeros(1, NBytes, 'uint8');
        for i = 1:NBytes
            response(i) = dInputStream.readByte;
        end
        response = char(response(41:end));
        SBIStream = java.io.StringBufferInputStream(response);
        XMLFactory = javax.xml.parsers.DocumentBuilderFactory.newInstance();
        XMLDocument = XMLFactory.newDocumentBuilder.parse(SBIStream);
        XMLDocument.normalizeDocument();
      
        Success = rem.GetNodeText(XMLDocument, 'Success')
        Command = rem.GetNodeText(XMLDocument, 'Command')
        Params = rem.GetNodeText(XMLDocument, 'Params')
        Msg = rem.GetNodeText(XMLDocument, 'Msg')
        
      end

      %release objects / cleanup
      iStream.close;
      dInputStream.close;
      dOutputStream.flush;
      oStream.close;
      dOutputStream.close;
      socket.close;
    end
    function nodeText = GetNodeText(rem, doc, nodeName)
        nodeList = doc.getElementsByTagName(nodeName);
        if nodeList.getLength() > 0
            nodeText = nodeList.item(0).getTextContent;
        else
            nodeText = '';
        end
    end
  end

end
