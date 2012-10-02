function SetupSendTimer(obj, event, rem)
    %rem.sendTimer.StartFcn = @(x,y)disp('Send Timer started!');
    rem.sendTimer.TimerFcn = {@renv.SendCallback, rem};
    rem.sendTimer.StopFcn = {@renv.SetupSchedTimer, 'Send', rem};
    start(rem.sendTimer);
end
