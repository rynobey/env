function SetupReceiveTimer(obj, event, rem)
    %rem.rcvTimer.StartFcn = @(x,y)disp('Receive Timer started!');
    rem.rcvTimer.TimerFcn = {@ReceiveCallback, rem};
    rem.rcvTimer.StopFcn = {@SetupSchedTimer, 'Receive', rem};
    start(rem.rcvTimer);
end