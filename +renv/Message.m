classdef Message < handle
  
  properties
    Success;
    Command;
    Params;
    Msg;
  end
  properties (Hidden)
    XMLDoc;
  end
  methods
    function msg = Message(RawXML)
      if strcmp(RawXML, '') == 1
        msg.XMLDoc = com.mathworks.xml.XMLUtils.createDocument('Message');
        SuccessNode = msg.XMLDoc.createElement('Success');
        CommandNode = msg.XMLDoc.createElement('Command');
        ParamsNode = msg.XMLDoc.createElement('Params');
        MsgNode = msg.XMLDoc.createElement('Msg');
        msg.XMLDoc.getDocumentElement.appendChild(SuccessNode);
        msg.XMLDoc.getDocumentElement.appendChild(CommandNode);
        msg.XMLDoc.getDocumentElement.appendChild(ParamsNode);
        msg.XMLDoc.getDocumentElement.appendChild(MsgNode);
      else
        SBIStream = java.io.StringBufferInputStream(RawXML);
        XMLFactory = javax.xml.parsers.DocumentBuilderFactory.newInstance();
        XMLDocument = XMLFactory.newDocumentBuilder.parse(SBIStream);
        XMLDocument.normalizeDocument();
        msg.XMLDoc = XMLDocument;
        msg.updateProperties;
      end
    end
    function SetNodeText(msg, nodeName, nodeText)
      nodeList = msg.XMLDoc.getElementsByTagName(nodeName);
      if nodeList.getLength() > 0
        textNode = msg.XMLDoc.createTextNode(nodeText);
        nodeList.item(0).appendChild(textNode);
      end
      msg.updateProperties;
    end
    function RawXML = GetRawXML(msg)
      XML = xmlwrite(msg.XMLDoc);
      RawXML = XML(40:end);
    end
  end
  methods (Hidden)
    function nodeText = GetNodeText(msg, nodeName)
        nodeList = msg.XMLDoc.getElementsByTagName(nodeName);
        if nodeList.getLength() > 0
            nodeText = nodeList.item(0).getTextContent;
        else
            nodeText = '';
        end
    end
    function updateProperties(msg)
      msg.Success = msg.GetNodeText('Success');
      msg.Command = msg.GetNodeText('Command');
      msg.Params = msg.GetNodeText('Params');
      msg.Msg = msg.GetNodeText('Msg');
    end
  end
  methods (Static)
    function msg = New(cmd, varargin)
      msg = renv.Message('');
      msg.SetNodeText('Command', cmd);
      if length(varargin) > 0
        params = varargin{1};
        for n = 2:length(varargin)
          params = sprintf('%s;%s', params, varargin{n});
        end
        msg.SetNodeText('Params', params);
      end
    end
  end

end
