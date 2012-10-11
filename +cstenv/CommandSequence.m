classdef CommandSequence < handle
  %COMMANDSEQUENCE Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    cmdArr = cstenv.Command.empty(1,0)
    object;
    objectName;
  end
  
  methods
    function seq = CommandSequence(object, objectName)
      seq.object = object;
      seq.objectName = objectName;
    end
    function Add(seq, commandName, varargin)
      cmd = cstenv.Command(seq.object, seq.objectName, commandName, varargin{:});
      seq.cmdArr(end + 1) = cmd;
    end
    function out = Execute(seq)
      out = seq.cmdArr.Execute();
    end
    function text = ToVBA(seq)
      text = seq.cmdArr.ToVBA();
    end
  end
  
  methods (Static)
    function seq = Join(sequence1, sequence2)
      seq = cstenv.CommandSequence([], []);
      l1 = length(sequence1.cmdArr);
      l2 = length(sequence2.cmdArr);
      seq.cmdArr = cstenv.Command.empty(l1 + l2, 0);
      seq.cmdArr(1:l1) = sequence1.cmdArr(:);
      seq.cmdArr(l1 + 1:l1 + l2) = sequence2.cmdArr(:);
    end
  end
end
