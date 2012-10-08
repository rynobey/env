function ReceiveCallback(obj, event, rem)
  NBytes = rem.iStream.available;
  if NBytes ~= 0    
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
          d1 = strcmp(response.Msg, 'True');
          d2 = strcmp(response.Msg, 'False');
          d3 = strcmp(response.Msg, '');
          d4 = strcmp(response.Msg, 'Enqueued');
          if ~(d1 || d2 || d3 || d4) || (response.Success == 0)
            disp(sprintf('SERVER: %s', response.Msg.toCharArray));
          end
        end
      else
        index = index - 1;
      end
      index = index + 1;
    end
  end
end
