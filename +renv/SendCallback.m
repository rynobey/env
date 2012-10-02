function SendCallback(obj, event, rem)
    % Send messages
    %disp('SendCallback called');
    
    if length(rem.msgArr) > 0
        commandText = '<Tx>';
        rem.dOutputStream.writeBytes(char(commandText));
        rem.dOutputStream.flush;
        for n = 1:length(rem.msgArr)
            msg = rem.msgArr{n};
            commandText = msg.GetRawXML;
            rem.dOutputStream.writeBytes(char(commandText));
            rem.dOutputStream.flush;
            pause(0.1);
        end            
        commandText = '</Tx>';
        rem.dOutputStream.writeBytes(char(commandText));
        rem.dOutputStream.flush;
        rem.msgArr = renv.Message.empty(1,0);
    end    
end
