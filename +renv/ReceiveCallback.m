function ReceiveCallback(obj, event, rem)
  NBytes = rem.iStream.available;
  if NBytes ~= 0    
    RawResponse = zeros(1, NBytes, 'uint8');
    for i = 1:NBytes
      byte = rem.dInputStream.readByte;
      if byte ~= 0
        RawResponse(i) =  byte;
        c1 = length(strfind(char(RawResponse(41:end)), '<Message'));
        c2 = length(strfind(char(RawResponse(41:end)), '</Message>'));
        c3 = length(strfind(char(RawResponse(41:end)), '<Message/>'));
        c4 = length(strfind(char(RawResponse(41:end)), '<Message />'));
        if (c1 > 0 && c2 > 0) || c3 > 0 || c4 > 0
          response = renv.Message(char(RawResponse(41:end)));
          d1 = strcmp(response.Msg, 'True');
          d2 = strcmp(response.Msg, 'False');
          d3 = strcmp(response.Msg, '');
          if ~(d1 || d2 || d3) || (response.Success == 0)
            disp(response.Msg);
          end
        end
      end
    end    
  end
end
