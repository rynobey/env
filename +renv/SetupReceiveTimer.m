function SetupReceiveTimer(obj, event, rem)
  rem.rcvTimer.TimerFcn = {@renv.ReceiveCallback, rem};
  rem.rcvTimer.StopFcn = {@renv.SetupSchedTimer, 'Receive', rem};
  start(rem.rcvTimer);
end
