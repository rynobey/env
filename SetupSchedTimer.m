function SetupSchedTimer(obj, event, callerName, rem)
    %rem.schedTimer.StartFcn = @(x,y)disp('Sched Timer started!');
    if strcmp(callerName, 'Send')
        rem.schedTimer.TimerFcn = {@SetupReceiveTimer, rem};
    elseif strcmp(callerName, 'Receive')
        rem.schedTimer.TimerFcn = {@SetupSendTimer, rem};
    end
    %rem.schedTimer.StopFcn = @(x,y)disp('Sched Timer stopped!');
    start(rem.schedTimer);
end