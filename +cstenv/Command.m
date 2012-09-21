classdef Command < handle
    %COMMAND Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        object;
        objectName;
        commandName;
        arguments;
    end
    
    methods
        function cmd = Command(object, objectName, commandName, varargin)
            cmd.object = object;
            cmd.objectName = objectName;
            cmd.commandName = commandName;
            cmd.arguments = varargin;
        end
        function out = Execute(cmd)
            out = cell(zeros(size(cmd)));
            try
                for n = 1:size(cmd, 2)
                    out(n) = {cmd(n).object.invoke(cmd(n).commandName, cmd(n).arguments{:})};
                end
            catch e
                disp(sprintf('In Command.Execute: %s', e.message));
            end
        end
        function text = ToVBA(cmd)
            text = '';
            for nn = 1:size(cmd, 2)
                if nn == 1
                    if strcmp(cmd(nn).objectName, '')
                        text = sprintf('%s', cmd(nn).commandName);
                    else
                        text = sprintf('%s.%s', cmd(nn).objectName, cmd(nn).commandName);
                    end
                else
                    if strcmp(cmd(nn).objectName, '')
                        text = sprintf('%s \n%s', text, cmd(nn).commandName);
                    else
                        text = sprintf('%s \n%s.%s', text, cmd(nn).objectName, cmd(nn).commandName);
                    end
                end
                if length(cmd(nn).arguments) > 0 %#ok<ISMT>
                    text = sprintf('%s "%s"', text, cmd(nn).arguments{1});
                    for n = 2:length(cmd(nn).arguments)
                        text = sprintf('%s, "%s"', text, cmd(nn).arguments{n});
                    end
                end
            end
        end
    end
end

