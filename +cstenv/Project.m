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
    function proj = Project(env, projectName)
      proj.Env = env;
      proj.projectPath = fullfile(env.path, projectName, '');
      proj.projectName = projectName;
      cstPath = sprintf('%s\\%s\\%s.cst', proj.Env.remotePath, ...
        proj.projectName, proj.projectName);
      msg = renv.Message.New('FileExists', cstPath);
      if exist(proj.projectPath, 'dir') == 7 && ...
        strcmp(env.remote.Request(msg).Msg, 'True')
          proj.Open();
      elseif exist(proj.projectPath, 'dir') == 7 && ...
        strcmp(env.remote.Request(msg).Msg, 'False')
          proj.New();
      elseif exist(proj.projectPath, 'dir') ~= 7
          disp('ERROR: Project folder does not exist!');
      end
    end
    function Close(proj)
      try
        cstPath = sprintf('%s\\%s\\%s.cst', proj.Env.remotePath, ...
          proj.projectName, proj.projectName);
        proj.CSTProject.invoke('SaveAs', cstPath, 'False');
        proj.CSTProject.invoke('Quit');
        proj.delete();
      end
    end
    function Clean(proj)
      try
        proj.CSTProject.invoke('FileNew');
        cstPath = sprintf('%s\\%s\\%s.cst', proj.Env.remotePath, ...
          proj.projectName, proj.projectName);
        proj.CSTProject.invoke('SaveAs', cstPath, 'False');
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
            if length(find(double(lines) == 10)) >= maxNumLines || n == ...
                length(index)
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
        cstPath = sprintf('%s\\%s\\%s.cst', proj.Env.remotePath, ...
          proj.projectName, proj.projectName);
        proj.CSTProject.invoke('SaveAs', cstPath, 'False');
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
        cstPath = sprintf('%s\\%s\\%s.cst', proj.Env.remotePath, ...
          proj.projectName, proj.projectName);
        proj.CSTProject = proj.Env.CST.invoke('OpenFile', cstPath);
        proj.CSTProject.invoke('Save');
      catch e
        proj.CSTProject = [];
        disp(sprintf('Error opening project: %s', e.message));
        disp('Working in offline mode');
      end
    end
    function New(proj)
      try
        cstPath = sprintf('%s\\%s\\%s.cst', proj.Env.remotePath, ...
        proj.projectName, proj.projectName);
        proj.CSTProject = proj.Env.CST.invoke('NewMWS');
        proj.CSTProject.invoke('SaveAs', cstPath, 'False');
      catch e
        proj.CSTProject = [];
        disp(sprintf('Error opening project: %s', e.message));
        disp('Working in offline mode');
      end
    end
    function updateLib(proj)
      installPath = proj.CSTProject.invoke('GetInstallPath');
      sourceDirPath = fullfile(proj.Env.path, 'env', '+cstenv', '+scripts', '');
      sourceDirPath = fullfile(sourceDirPath, 'cst', 'Includes', '');
      destFolderPath = sprintf('%s\\Library', installPath);
      proj.Env.remote.Upload(sourceDirPath, destFolderPath);

      sourceDirPath = fullfile(proj.Env.path, 'env', '+cstenv', '+scripts', '');
      sourceDirPath = fullfile(sourceDirPath, 'cst', 'Result Templates', 'General 1D', '');
      destFolderPath = sprintf('%s\\Library\\Result Templates', installPath);
      proj.Env.remote.Upload(sourceDirPath, destFolderPath);
    end
    function delete(proj) % called when this object is destroyed
      try
        for n = 1:length(proj.COMObjectArr)
          proj.COMObjectArr{n}.release();
        end
        proj.CSTProject.release();
      end
      proj.Env.removeFromList(proj.projectName);
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
    end
  end
end
