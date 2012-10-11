function ReceiveCallback(obj, event, rem)
  try
    NBytes = rem.iStream.available;
    if NBytes ~= 0    
      RawResponse = zeros(1, NBytes, 'uint8');
      index = 1;
      for i = 1:NBytes
        byte = rem.dInputStream.readByte;
        if byte ~= 0
          RawResponse(index) =  byte;        
          offset = getStartIndex(RawResponse);
          if offset > -1
            offset = offset + 40;
            c1 = length(strfind(char(RawResponse(offset:end)), '<Message'));
            c2 = length(strfind(char(RawResponse(offset:end)), '</Message>'));
            c3 = length(strfind(char(RawResponse(offset:end)), '<Message/>'));
            c4 = length(strfind(char(RawResponse(offset:end)), '<Message />'));
            if (c1 > 0 && c2 > 0) || c3 > 0 || c4 > 0
              response = renv.Message(char(RawResponse(offset:end)));
              RawResponse = [];
              index = 0;
              d1 = strcmp(response.Msg, 'True');
              d2 = strcmp(response.Msg, 'False');
              d3 = strcmp(response.Msg, '');
              d4 = strcmp(response.Msg, 'Enqueued');
              if ~(d1 || d2 || d3 || d4) || (response.Success == 0)
                disp(sprintf('SERVER: %s', response.Msg.toCharArray));
              end
            end
          end
        else
          index = index - 1;
        end
        index = index + 1;
      end
    end
  end
end

function index = getStartIndex(RawResponse)
    index = -1;
    char1 = find(RawResponse == '<', 1, 'first');
    char2 = find(RawResponse == '?', 1, 'first');
    char3 = find(RawResponse == 'x', 1, 'first');
    char4 = find(RawResponse == 'm', 1, 'first');
    char5 = find(RawResponse == 'l', 1, 'first');
    c1 = length(char1) == 0 || length(char2) == 0;
    c2 = length(char3) == 0 || length(char4) == 0;
    if ~(c1 || c2 || length(char5) == 0)
        h1 = (char1 + 1 == char2) && (char2 + 1 == char3);
        h2 = (char3 + 1 == char4) && (char4 + 1 == char5);
        if h1 && h2
            index = char1;
        end
    end    
end
