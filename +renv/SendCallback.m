function SendCallback(obj, event, rem)
  if length(rem.msgArr) > 0
    commandText = '<Tx>';
    rem.dOutputStream.writeBytes(char(commandText));
    rem.dOutputStream.flush;
    for n = 1:length(rem.msgArr)
      msg = rem.msgArr{n};
      commandText = msg.GetRawXML;
      %disp(commandText)
      rem.dOutputStream.writeBytes(char(commandText));
      rem.dOutputStream.flush;
      pause(0.25);
    end
    commandText = '</Tx>';
    rem.dOutputStream.writeBytes(char(commandText));
    rem.dOutputStream.flush;
    rem.msgArr = renv.Message.empty(1,0);
  end    
end
