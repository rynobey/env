classdef Results < handle
  %RESULTS Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    code;
  end
  
  methods
    function res = Results()
      res.code = cstenv.Results.DefineVar('fileName', 'String');
      res.code = sprintf('%s%s', res.code, ...
        cstenv.Results.DefineVar('fileText', 'String'));
      res.code = sprintf('%s%s', res.code, ...
        cstenv.Results.AssignVal('fileName', 'testFile'));
      res.code = sprintf('%s%s', res.code, ...
        cstenv.Results.AssignVal('fileText', 'testText'));
      res.code = sprintf('%s%s', res.code, ...
        cstenv.Results.AppendToFile('fileName', 'fileText'));
    end
  end

  methods (Static)
    function EvalInTemp(cmds)
      assignin('base', 'cmds_temp_ws', cmds);
      clearvars;
      for n = 1:evalin('base', 'length(cmds_temp_ws);')
        assignin('base', 'n_temp_ws', n);
        clearvars n;
        eval(evalin('base', sprintf('cmds_temp_ws{%d};', evalin('base', ...
          'n_temp_ws'))));
        n = evalin('base', 'n_temp_ws'); %#ok<FXSET>
      end
      evalin('base', 'clearvars cmds_temp_ws n_temp_ws');
    end
    function JoinCSVResults(sourceResultDir, destResultDir)
      curPath = cd;
      %get list of result files for both dirs
      cd(sourceResultDir);
      sourceFileList = ls;
      cd(destResultDir);
      destFileList = ls;
      %compare result file lists
      numNotFound = 0;
      for i = 1:length(sourceFileList(:,1))
        found = 0;
        for j = 1:length(destFileList(:,1))
          if strcmp(sourceFileList(i,:), destFileList(j,:))
            found = 1;
          end
        end
        if found == 0
          numNotFound = numNotFound + 1;
        end
      end
      if numNotFound == 0
        %load Parameters from sourceResultDir
        cd(sourceResultDir);
        cmds = {'Parameters;', 'S1 = who();', 'assignin(''caller'', ''S1'', S1)'};
        cstenv.Results.EvalInTemp(cmds);
        %load Parameters from destResultDir
        cd(destResultDir);
        cmds = {'Parameters;', 'S2 = who();', 'assignin(''caller'', ''S2'', S2)'};
        cstenv.Results.EvalInTemp(cmds);
        %compare parameter name lists
        numExtraParams = 0;
        for i = 1:length(S1) %#ok<USENS>
          found = 0;
          for j = 1:length(S2) %#ok<USENS>
            if strcmp(S2{j}, S1{i})
              found = 1;
              break;
            end
          end
          if found == 0
            numExtraParams = numExtraParams + 1;
          end
        end
        if numExtraParams == 0
          for i = 1:length(sourceFileList(:,1))
            for j = 1:length(destFileList(:,1))
              if strcmp(sourceFileList(i,:), destFileList(j,:))
                % check that current item is a file
                if exist(sourceFileList(i,:), 'file') == 2
                  filePath = fullfile(sourceResultDir, sourceFileList(i,:));
                  sourceContents = fileread(filePath);
                  filePath = fullfile(destResultDir, destFileList(j,:));
                  fid = fopen(filePath, 'a+');
                  fprintf(fid, '%s', sourceContents);
                  fclose(fid);
                end
                break;
              end
            end
          end                    
        else
          disp('Unable to complete operation!');
        end
      else
        disp('Unable to complete operation!');
      end
      cd(curPath);
    end
    function firstOrUniq = GetFirstOrUniqIndexes(resultDir)
      curPath = cd;
      cd(resultDir);
      Parameters();
      cmds = {'Parameters;', 'S1 = who();', ...
        'assignin(''caller'', ''paramList'', S1)'};
      cstenv.Results.EvalInTemp(cmds);
      numSets = eval(sprintf('length(%s)',paramList{1})); %#ok<USENS>
      firstOrUniq = zeros(numSets, 1);
      for i = 1:numSets
        dupValExists = 1;                
        for j = 1:numSets
          if j ~= i
            dupValExists = 1;
            for k = 1:length(paramList)
              curParam = eval(sprintf('%s',paramList{k}));
              if curParam(i) ~= curParam(j)
                dupValExists = 0;
                break;
              end
            end
            if dupValExists == 1
              if j > i
                firstOrUniq(i) = 1;
              end
              break;
            end
          end
        end
        if dupValExists == 0
          firstOrUniq(i) = 1;
        end
      end
      cd(curPath)
    end
    function RemoveDuplicates(resultDir)
    end
  end    
end
