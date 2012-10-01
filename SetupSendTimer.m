function SetupSendTimer(obj, event, rem)
    %rem.sendTimer.StartFcn = @(x,y)disp('Send Timer started!');
    rem.sendTimer.TimerFcn = {@SendCallback, rem};
    rem.sendTimer.StopFcn = {@SetupSchedTimer, 'Send', rem};
    start(rem.sendTimer);
end