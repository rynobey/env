classdef RemoteCOMObj < handle
  
  properties
    objVarName;
    remote;
  end
  methods
    function o = RemoteCOMObj(objVarName, remote)
      o.objVarName = objVarName;
      o.remote = remote;
    end
    function newO = invoke(o, cmd, varargin)
      %new objects need to be created in some special cases
      if strcmp(cmd, 'OpenFile')
        fileName = varargin{1};
        projName = fileName;
        if find(projName == '/', 1) 
          projName = projName(find(projName == '/', 1, 'last') + 1: end);
        end
        if find(projName == '\', 1)
          projName = projName(find(projName == '\', 1, 'last') + 1: end);
        end
        if find(projName == '.', 1)
          projName = projName(1:find(projName == '.', 1, 'last') - 1);
        end
        scriptCode = sprintf('Set %s = %s.%s "%s"', projName, o.objVarName, cmd, fileName);
        msg = renv.Message.New('VBScript', scriptCode);
        o.remote.Send(msg);
        newO = cstenv.RemoteCOMObj(fileName, o.remote);
      elseif strcmp(cmd, 'NewMWS')
        scriptCode = sprintf('Set tempNewProj = %s.%s', o.objVarName, cmd);
        msg = renv.Message.New('VBScript', scriptCode);
        o.remote.Send(msg);
        newO = cstenv.RemoteCOMObj('tempNewProj', o.remote);
      elseif strcmp(cmd, 'SaveAs')
        fileName = varargin{1};
        projName = fileName;
        if find(projName == '/', 1) 
          projName = projName(find(projName == '/', 1, 'last') + 1: end);
        end
        if find(projName == '\', 1)
          projName = projName(find(projName == '\', 1, 'last') + 1: end);
        end
        if find(projName == '.', 1)
          projName = projName(1:find(projName == '.', 1, 'last') - 1);
        end
        scriptCode = sprintf('%s.%s "%s", "%s"', o.objVarName, cmd, fileName, varargin{2});
        scriptCode = sprintf('%s:Set %s = %s', scriptCode, projName, 'tempNewProj');
        msg = renv.Message.New('VBScript', scriptCode);
        o.remote.Send(msg);
        newO = '';
        o.objVarName = projName;
      else
        scriptCode = sprintf('%s.%s', o.objVarName, cmd);
        counter = 1;
        for n = 1:length(varargin)
          if counter == 1
            scriptCode = sprintf('%s "%s"', scriptCode, varargin{n});
          else
            scriptCode = sprintf('%s, "%s"', scriptCode, varargin{n});
          end
          counter = counter + 1;
        end
        scriptCode
        msg = renv.Message.New('VBScript', scriptCode);
        o.remote.Send(msg);
        newO = '';
      end
    end
    function newO = get(o, objName)
      scriptCode = sprintf('Set %s = %s.%s', objName, o.objVarName, objName);
      msg = renv.Message.New('VBScript', scriptCode);
      o.remote.Send(msg);
      newO = cstenv.RemoteCOMObj(objName, o.remote);
    end
  end

end
