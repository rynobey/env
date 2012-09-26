classdef Environment < handle
    
  properties
      CST = [];
      path = [];
      remotePath = [];
      projects = cstenv.Project.empty(1,0);
  end

  methods
    function env = Environment(varargin)
        if length(varargin) == 1
            if varargin{1}
                env.ConCST();
                disp('Started CST Environment.');
            else
                disp('Started CST Environment in offline mode.');
            end
        else
            env.ConCST();
            disp('Started CST Environment.');
        end
        env.path = cd;
    end
    function ConCST(env)
      appName = 'CSTStudio.Application';
      try
        %env.CST = actxserver(appName);
        %env.remotePath = env.path;
      %catch
        r = renv.Remote('ee430030.ee.sun.ac.za', 8000);
        env.CST = cstenv.RemoteCOMObj('CST', r);
        scriptCode = sprintf('Set %s = CreateObject("%s")', 'CST', appName);
        msg = renv.Message.New('VBScript', scriptCode);
        r.Send(msg);
        env.remotePath = 'D:\\ftproot\work\Backup\Ryno\m\renv';
      end
    end
    function proj = Open(env, projectName)
       projectPath = fullfile(env.path, projectName, '');
       proj = cstenv.Project(env, projectPath);
       env.projects(end + 1) = proj;
    end
    function Close(env, projectName)
        if env.IsOpen(projectName)
            env.FindByName(projectName).Close();
        end
    end
    function Clean(env, projectName)
        if env.IsOpen(projectName)
            env.FindByName(projectName).Clean();
        end
    end
    function Reset(env, projectName)
        if env.IsOpen(projectName)
            env.FindByName(projectName).Reset();
        end
    end
    function Rebuild(env, projectName)
        if env.IsOpen(projectName)
            env.FindByName(projectName).Rebuild();
        end
    end
    function DeleteResults(env, projectName)
        if env.IsOpen(projectName)
            env.FindByName(projectName).DeleteResults();
        end
    end
    function Save(env, projectName)
        if env.IsOpen(projectName)
            env.FindByName(projectName).Save();
        end
    end
    function proj = FindByName(env, projectName)
        for n = 1:length(env.projects)
            proj = env.projects(n);
            if strcmp(proj.projectName, projectName)
                break;
            end
        end
    end
    function val = IsOpen(env, projectName)
        val = 0;
        try
            for n = 1:length(env.projects)
                proj = env.projects(n);
                if strcmp(proj.projectName, projectName)
                    val = 1;
                    break;
                end
            end
        end
    end
  end
  methods (Hidden)
    function delete(env)
      for n = 1:length(env.projects)
        env.projects(1).delete();
      end
      env.CST.release();
    end
  end
  methods (Static)
    function env = Start(varargin)
      if evalin('base', 'exist(''env'', ''var'')') ~= 1
          if length(varargin) == 1
              evalin('base', sprintf('env = cstenv.Environment(%d);', varargin{1}));
          else
              evalin('base', 'env = cstenv.Environment();');
          end
      end
      env = evalin('base', 'env;');
    end
    function New(projectName)
      if exist(projectName, 'dir') ~= 7 && exist(projectName, 'file') ~= 2
        env = cstenv.Environment.Start();
        projectPath = fullfile(env.path, projectName, '')
        %projectPath = sprintf('%s\\%s', env.path, projectName);
        mkdir(projectPath);
        
        % generate empty project class file
        openCommand = sprintf('%s.GetEnv().Open(''%s'');', projectName, projectName);
        closeCommand = sprintf('%s.GetEnv().Close(''%s'');', projectName, projectName);
        cleanCommand = sprintf('%s.GetEnv().Clean(''%s'');', projectName, projectName);
        initCommand = sprintf('obj = %s.GetObject(''%s'');', projectName, projectName);
        runCommands = sprintf('%s.Build;\n\t\t\t%s.Setup;\n\t\t\t%s.Solve;\n\t\t\t%s.Results;', ...
            projectName, projectName, projectName, projectName);
        buildComments = 'Commands for building the CAD model';
        setupComments = 'Commands for setting up the simulation (e.g. generating mesh etc.)';
        solveComments = 'Commands for starting the solver';
        resultsComments = 'Commands for retrieving and/or post-processing the results';
        
        text = sprintf('classdef %s < cstenv.Project\n\n', projectName);
        text = sprintf('%s\tproperties\n\tend\n\n', text);
        text = sprintf('%s\tmethods (Static)\n', text);
        text = sprintf('%s\t\t%%%% Project specific methods\n', text);
        text = sprintf('%s\t\tfunction Build() %% %s\n\t\t\t%s\n\t\tend\n', text, buildComments, initCommand);
        text = sprintf('%s\t\tfunction Setup() %% %s\n\t\t\t%s\n\t\tend\n', text, setupComments, initCommand);
        text = sprintf('%s\t\tfunction Solve() %% %s\n\t\t\t%s\n\t\tend\n', text, solveComments, initCommand);
        text = sprintf('%s\t\tfunction Results() %% %s\n\t\t\t%s\n\t\tend\n', text, resultsComments, initCommand);
        text = sprintf('%s\t\t%%%% General methods\n', text);
        text = sprintf('%s\t\tfunction Open()\n\t\t\t%s\n\t\tend\n', text, openCommand);
        text = sprintf('%s\t\tfunction Close()\n\t\t\t%s\n\t\tend\n', text, closeCommand);
        text = sprintf('%s\t\tfunction Clean()\n\t\t\t%s\n\t\tend\n', text, cleanCommand);
        text = sprintf('%s\t\tfunction Run()\n\t\t\t%s\n\t\tend\n', text, runCommands);
        text = sprintf('%s\tend\n\n', text);
        text = sprintf('%send', text);
        
        fileID = fopen(sprintf('%s.m', projectName), 'w+');
        fprintf(fileID, '%s', text);
        fclose(fileID);
      end
    end
  end
end
