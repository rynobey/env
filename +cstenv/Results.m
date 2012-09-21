classdef Results < handle
    %RESULTS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        code;
    end
    
    methods
        function res = Results()
            res.code = cstenv.Results.DefineVar('fileName', 'String');
            res.code = sprintf('%s%s', res.code, cstenv.Results.DefineVar('fileText', 'String'));
            res.code = sprintf('%s%s', res.code, cstenv.Results.AssignVal('fileName', 'testFile'));
            res.code = sprintf('%s%s', res.code, cstenv.Results.AssignVal('fileText', 'testText'));
            res.code = sprintf('%s%s', res.code, cstenv.Results.AppendToFile('fileName', 'fileText'));
        end
    end
    
    methods (Static)
        function code = AppendToFile(fileVarName, textVarName)
            code = sprintf('Dim file As Long\n');
            code = sprintf('%sfile = FreeFile\n', code);
            code = sprintf('%sOpen %s For Append As #file\n', code, fileVarName);
            code = sprintf('%sPrint #file, %s\n', code, textVarName);
            code = sprintf('%sClose #file\n', code);
        end
        function code = DefineVar(varName, typeName)
            code = sprintf('Dim %s As %s\n', varName, typeName);
        end
        function code = AssignVal(varName, value)
            code = sprintf('%s = "%s"\n', varName, num2str(value));
        end
        function code = AssignVar(varName, valVarName)
            code = sprintf('%s = %s\n', varName, valVarName);
        end
    end
    
end

