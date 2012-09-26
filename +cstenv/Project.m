classdef Project < handle
    %PROJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Env = [];
        CSTProject = [];
        projectPath = [];
        projectName = [];
        components = {};
        COMObjectArr = {};
    end
    
    methods
        function proj = Project(env, projectPath)
            proj.Env = env;
            proj.projectPath = projectPath;
            proj.projectName = projectPath(find(projectPath == filesep, 1, 'last') + 1: end);
            cstPath = sprintf('%s\\%s.cst', proj.Env.remotePath, proj.projectName);
            if exist(proj.projectPath, 'dir') == 7 && exist(cstPath, 'file') == 2
                proj.New();
            elseif exist(proj.projectPath, 'dir') == 7 && exist(cstPath, 'file') ~= 2
                proj.New();                
       %projectPath = sprintf('%s\\%s', env.path, projectName);
            elseif exist(proj.projectPath, 'dir') ~= 7
                disp('ERROR: Project folder does not exist!');
            end
        end
        function Close(proj)
            proj.delete();
        end
        function Clean(proj)
            try
                proj.CSTProject.invoke('FileNew');
                filePath = sprintf('%s\\%s.cst', proj.Env.remotePath, proj.projectName);
                proj.CSTProject.invoke('SaveAs', filePath, 'False');
            end
        end
        function Reset(proj)
            try
                proj.CSTProject.invoke('ResetAll');
            end
        end
        function Rebuild(proj)
            try
                proj.CSTProject.invoke('Rebuild');
            end
        end
        function AddToHistory(proj, header, commands)
            maxNumLines = 15;
            try
                index = find(double(commands) == 10);
                index(end + 1) = length(commands);
                if length(index) > maxNumLines
                    lines = '';
                    counter = 1;
                    for n = 1:length(index)
                        startLine = 1;
                        endLine = index(n);
                        if n > 1
                            startLine = index(n - 1) + 1;
                            endLine = index(n);
                        end
                        lines = sprintf('%s%s', lines, commands(startLine:endLine));
                        if length(find(double(lines) == 10)) >= maxNumLines || n == length(index)
                            headerTemp = sprintf('%s_%d', header, counter);
                            proj.CSTProject.invoke('AddToHistory', headerTemp, lines);
                            lines = '';
                            counter = counter + 1;
                        end
                    end
                else
                    proj.CSTProject.invoke('AddToHistory', header, commands);
                end
            end
        end
        function DeleteResults(proj)
            try
                proj.CSTProject.invoke('DeleteResults');
            end
        end
        function Save(proj)
            try
                filePath = sprintf('%s\\%s.cst', proj.Env.remotePath, proj.projectName);
                proj.CSTProject.invoke('SaveAs', filePath, 'False');
            end
        end
        function obj = GetCOMObj(proj, objName)
            obj = [];
            if length(proj.CSTProject) > 0
                if length(proj.FindCOMObjByName(objName)) > 0
                    obj = proj.FindCOMObjByName(objName);
                else
                    obj = proj.CSTProject.get(objName);
                    proj.COMObjectArr(end + 1) = {obj};
                end
            end
        end
    end
    methods (Hidden)
        function Open(proj)
            try
                filePath = sprintf('%s\\%s.cst', proj.Env.remotePath, proj.projectName);
                proj.CSTProject = proj.Env.CST.invoke('OpenFile', filePath);
                proj.CSTProject.invoke('Save');
            catch e
                proj.CSTProject = [];
                disp(sprintf('Error opening project: %s', e.message));
                disp('Working in offline mode');
            end
        end
        function New(proj)
            try
                filePath = sprintf('%s\\%s.cst', proj.Env.remotePath, proj.projectName);
                proj.CSTProject = proj.Env.CST.invoke('NewMWS');
                proj.CSTProject.invoke('SaveAs', filePath, 'False');
            catch e
                proj.CSTProject = [];
                disp(sprintf('Error opening project: %s', e.message));
                disp('Working in offline mode');
            end
        end
        function updateLib(proj)
            % copy library into "Includes" folder of CST
            sourceFilePath = sprintf('%s\\+cstenv\\+scripts\\envlib.lib', proj.Env.remotePath);
            installPath = proj.CSTProject.invoke('GetInstallPath');
            destFolderPath = sprintf('%s\\Library\\Includes\\', installPath);
            copyfile(sourceFilePath, destFolderPath, 'f');
        end
        function delete(proj) % called when this object is destroyed
            try
                filePath = sprintf('%s\\%s.cst', proj.Env.remotePath, proj.projectName);
                proj.CSTProject.invoke('SaveAs', filePath, 'False');
                proj.CSTProject.invoke('Quit');
                for n = 1:length(proj.COMObjectArr)
                    proj.COMObjectArr{n}.release();
                end
                proj.CSTProject.release();
            end
        end
        function obj = FindCOMObjByName(proj, objName)
            obj = [];
            for n = 1:length(proj.COMObjectArr)
                name = evalc(sprintf('proj.COMObjectArr{%d}', n));
                name = name(find(name == '.', 1, 'last') + 1: end);
                name = name(1:find(double(name == 10), 1, 'first')-1);
                if strcmp(name, objName)
                    obj = proj.COMObjectArr{n};
                    break;
                end
            end
            if length(obj) == 0
              for n = 1:length(proj.COMObjectArr)
                name = '';
                try
                  name = proj.COMObjectArr{n}.objVarName;
                end
                if strcmp(name, objName)
                  obj = proj.COMObjectArr{n};
                  break;
                end
              end
            end
        end
    end
    methods (Static)
        function env = GetEnv()
            env = evalin('base', 'cstenv.Environment.Start();');
        end
        function proj = GetObject(projectName)
            env = cstenv.Project.GetEnv();
            if env.IsOpen(projectName) == 0
                proj = env.Open(projectName);
            else
                proj = env.FindByName(projectName);
            end
            %proj.updateLib();
        end
    end
end
