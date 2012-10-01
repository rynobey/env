function SendCallback(obj, event, rem)
    % Send messages
    %disp('SendCallback called');
    
    if length(rem.msgArr) > 0
        % aggregate the data            
        commandText = '<Tx>';
        rem.dOutputStream.writeBytes(char(commandText));
        rem.dOutputStream.flush;
        for n = 1:length(rem.msgArr)
            msg = rem.msgArr{n};
            commandText = msg.GetRawXML;
            rem.dOutputStream.writeBytes(char(commandText));
            rem.dOutputStream.flush;
            %disp(commandText);
            pause(0.2);
        end            
        commandText = '</Tx>';
        rem.dOutputStream.writeBytes(char(commandText));
        rem.dOutputStream.flush;
        %send data
        rem.msgArr = renv.Message.empty(1,0);
    end    
end