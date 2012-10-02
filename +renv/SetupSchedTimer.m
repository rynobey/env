function SetupSchedTimer(obj, event, callerName, rem)
  if strcmp(callerName, 'Send')
    rem.schedTimer.TimerFcn = {@renv.SetupReceiveTimer, rem};
  elseif strcmp(callerName, 'Receive')
    rem.schedTimer.TimerFcn = {@renv.SetupSendTimer, rem};
  end
  start(rem.schedTimer);
end
