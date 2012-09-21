
classdef Parameter < handle
   
    properties
        name;
        value;
        description;
        project;
    end
    
    methods
        function param = Parameter(obj, name, varargin)
            isHelper = 0;
            if nargin >= 4 && strcmp(class(varargin{end}), 'double')
                isHelper = varargin{end};
            end
            if strcmp(class(obj), 'cstenv.Project')
                param.project = obj;
                param.name = sprintf('aaa_%s', name);
            else
                param.project = obj.project;
                obj.parameters(end + 1) = param;
                if isHelper
                    param.name = sprintf('zzz_%s', name);
                else
                    param.name = sprintf('%s_%s', obj.solidName, name);
                end
            end
            if nargin == 3 || (nargin == 4 && strcmp(class(varargin{end}), 'double'))
                param.value = varargin{1};
                param.description = '';
            elseif nargin == 4 && ~strcmp(class(varargin{end}), 'double')
                param.value = varargin{1};
                param.description = varargin{2};
            elseif nargin == 5
                param.value = varargin{1};
                param.description = varargin{2};
            end
        end
        function param = Get(param)
            for n = 1:length(param)
                try
                    if strcmp(class(param(n).value), 'double')
                        param(n).value = param(n).project.CSTProject.invoke('RestoreDoubleParameter', param(n).name);
                    elseif ischar(class(param.value))
                        param(n).value = param(n).project.CSTProject.invoke('RestoreParameterExpression', param(n).name);
                    end
                    param(n).description = param(n).project.CSTProject.invoke('GetParameterDescription', param(n).name);
                catch e
                    disp(e.message)
                end
            end
        end
        function param = Set(param)
            for n = 1:length(param)
                try
                    if strcmp(class(param(n).value), 'double')
                        param(n).project.CSTProject.invoke('StoreDoubleParameter', param(n).name, num2str(param(n).value));
                    elseif ischar(class(param(n).value))
                        param(n).project.CSTProject.invoke('StoreParameter', param(n).name, param(n).value);
                    end
                    param(n).project.CSTProject.invoke('SetParameterDescription', param(n).name, param(n).description);
                catch e
                    disp(e.message)
                end
            end
        end
        function seq = SetSeq(param)
            for n = 1:length(param)
                if n == 1
                    if length(param(n).project) == 0
                        seq = cstenv.CommandSequence([], '');
                    else
                        seq = cstenv.CommandSequence(param(n).project.CSTProject, '');
                    end
                end
                if strcmp(class(param(n).value), 'double')
                    seq.Add('MakeSureParameterExists ', param(n).name, num2str(param(n).value));
                elseif ischar(class(param(n).value))
                   seq.Add('MakeSureParameterExists', param(n).name, param(n).value);
                end
                seq.Add('SetParameterDescription', param(n).name, param(n).description);
            end
        end
    end
    
end