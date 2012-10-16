classdef IsolationStudy < cstenv.Project

	properties
	end

	methods (Static)
		%% Project specific methods
		function Build() % Commands for building the CAD model
      obj = IsolationStudy.GetObject('IsolationStudy');
      import cstenv.*;
      systemImpedance = Parameter(obj, 'SystemImpedance', 5, 'Project Parameter');
      numPorts = Parameter(obj, 'numPorts', 10, 'Project Parameter');
      conicalAngle = Parameter(obj, 'conicalAngle', 90, 'Project Parameter');
      ratio = Parameter(obj, 'ratio', 1.25, 'Project Parameter');
      lambdaC = Parameter(obj, 'lambda_c', 30, 'Project Parameter');

      seq = CommandSequence.Join(systemImpedance.SetSeq(), numPorts.SetSeq());
      seq = CommandSequence.Join(seq, conicalAngle.SetSeq());
      seq = CommandSequence.Join(seq, ratio.SetSeq());
      seq = CommandSequence.Join(seq, lambdaC.SetSeq());
      obj.AddToHistory('define project parameters', seq.ToVBA());
      coax1InnerRadiusExpr =  ...
        solid.coaxial.TxLine.CalcInnerExpr(systemImpedance.name, ...
        'coax1_outerRadius');
      coax1 = solid.coaxial.TxLine(obj, 'coax1', coax1InnerRadiusExpr, 3.5, 2);
      obj.AddToHistory('coax1', coax1.Create.ToVBA());
      obj.AddToHistory('pickFace1', coax1.PickPortFace('+').ToVBA());
      port1 = Port(obj, coax1);
      obj.AddToHistory('port1', port1.Create.ToVBA());
      con1Theta1Expr = ...
        solid.conical.TxLine.CalcTheta1Expr(systemImpedance.name, ...
        'conical1_theta2');
      con1 = solid.conical.TxLine(obj, 'conical1', con1Theta1Expr, ...
        conicalAngle.name, 35);
      obj.AddToHistory('conical1', con1.Create.ToVBA());
      tr1 = solid.transition.CenterConicalCoax(obj, 'trans1', con1, coax1, 2);
      obj.AddToHistory('trans1', tr1.Create.ToVBA());
      coax2 = solid.coaxial.TxLine(obj, 'coax2', ...
        solid.coaxial.TxLine.CalcInner(50, 2.3), 2.3, 2);
      obj.AddToHistory('coax2', coax2.Create.ToVBA());
      obj.AddToHistory('pickFace2', coax2.PickPortFace('+').ToVBA());
      port2 = Port(obj, coax2, 2);
      obj.AddToHistory('port2', port2.Create.ToVBA());

      tr2PlacementRadiusExpr = sprintf('%s/4*((%s*%s)/(pi*sind(%s)) - 1)', ...
        lambdaC.name, ratio.name, numPorts.name, con1.avgTheta.name);
      tr2 = solid.transition.PeriphConicalCoax(obj, 'trans2', con1, coax2, ...
        tr2PlacementRadiusExpr, numPorts.name, '+');
      obj.AddToHistory('trans2', tr2.Create.ToVBA());

      radiusExpr = sprintf('%s + %s/4', tr2.placementRadius.name, lambdaC.name);
      con1.radius = cstenv.Parameter(con1, 'radius', radiusExpr);
      obj.AddToHistory('update conical tx line radius', con1.radius.UpdSeq.ToVBA());
      %combine components
      seq = CommandSequence(obj.GetCOMObj('Solid'), 'Solid');
      seq.Add('Add', con1.solidPath, tr1.solidPath);
      seq.Add('Add', con1.solidPath, coax1.solidPath);
      seq.Add('Add', con1.solidPath, coax2.solidPath);
      obj.AddToHistory('combine', seq.ToVBA());         
      obj.Rebuild();

      %add slots
      exprX = sprintf('(%s - 10)', con1.radius.name);
      slot1 = solid.Brick(obj, 'slot1', exprX, 0.8, 10);
      seq = slot1.MoveExpr(sprintf('(%s)/2+10/2', con1.radius.name), ...
        '0', '0');
      seq = CommandSequence.Join(slot1.Create, seq);
      aSeq = slot1.RotateExpr('0', '0', '0', '0', '0', ...
        sprintf('180/(%s)', numPorts.name));
      seq = CommandSequence.Join(seq, aSeq);
      aSeq = slot1.RotateAndCopyExpr('0', '0', '0', '0', '0', ...
        sprintf('360/(%s)', numPorts.name), sprintf('(%s - 1)', numPorts.name));
      seq = CommandSequence.Join(seq, aSeq);
      obj.AddToHistory('slot1', seq.ToVBA());

		end
		function Setup() % Commands for setting up the simulation (e.g. generating mesh etc.)
			obj = IsolationStudy.GetObject('IsolationStudy');
      seq = cstenv.CommandSequence(obj.GetCOMObj('Units'), 'Units');
      seq.Add('Geometry', 'mm');
      seq.Add('Time', 'ns');
      seq.Add('Frequency', 'Ghz');
      obj.AddToHistory('units', seq.ToVBA());
      
      seq = cstenv.CommandSequence(obj.GetCOMObj('Background'), 'Background');
      seq.Add('Type', 'pec');
      obj.AddToHistory('background', seq.ToVBA());
      
      seq = cstenv.CommandSequence(obj.GetCOMObj('Boundary'), 'Boundary');
      seq.Add('Xmin', 'electric');
      seq.Add('ApplyInAllDirections', 'True');
      obj.AddToHistory('background', seq.ToVBA());
      
      seq = cstenv.CommandSequence(obj.GetCOMObj('Solver'), 'Solver');
      seq.Add('FrequencyRange', '3', '22');
      seq.Add('TimeBetweenUpdates', '120');
      obj.AddToHistory('solver', seq.ToVBA());
      
      seq = cstenv.CommandSequence(obj.GetCOMObj('Mesh'), 'Mesh');
      seq.Add('MeshType', 'Tetrahedral');
      seq.Add('SmallFeatureSize', '5e-4');
      seq.Add('SurfaceMeshGeometryAccuracy', '1e-6');
      seq.Add('StepsPerWavelengthTet', '6');            
      %seq.Add('Update');
      %seq.Add('CalculateMatrices');            
      tSeq = cstenv.CommandSequence(obj.GetCOMObj('MeshSettings'), 'MeshSettings');
      tSeq.Add('SetMeshType', 'Tet');
      tSeq.Add('Set', 'CurvatureOrder', '3');
      seq = cstenv.CommandSequence.Join(seq, tSeq);
      obj.AddToHistory('mesh', seq.ToVBA());
      
      seq = cstenv.CommandSequence(obj.GetCOMObj('FDSolver'), 'FDSolver');
      seq.Add('Reset');
      seq.Add('Stimulation', '2', '1');
      seq.Add('AccuracyTet', '1e-6');
      seq.Add('AddSampleInterval', '5', '21', '3', 'Automatic', 'True');
      seq.Add('AddSampleInterval', '', '', '', 'Automatic', 'False');
      seq.Add('SweepMinimumSamples', '15');
      seq.Add('SParameterSweep', 'True');
      seq.Add('MeshAdaptionTet', 'True');
      obj.AddToHistory('solver', seq.ToVBA());
		end
		function Solve() % Commands for starting the solver
			obj = IsolationStudy.GetObject('IsolationStudy');
      seq = cstenv.CommandSequence(obj.GetCOMObj('FDSolver'), 'FDSolver');
      seq.Add('Start');
      seq.Execute();
		end
		function Results(set_ratio, set_numPorts, doReload) % Commands for retrieving and/or post-processing the results
			obj = IsolationStudy.GetObject('IsolationStudy');
      curPath = cd;
      path = fullfile(curPath, obj.projectName, 'session4Res', '')
      cd(path);
      Parameters();
      if doReload == 1
        evalin('base', 'clearvars fOu S F');
        assignin('base', 'fOu', cstenv.Results.GetFirstOrUniqIndexes(path));
        for n = 1:9
            S(n,2,:, :) = csvread(sprintf('cS%d(1)2(1).csv', n));
        end
        assignin('base', 'S', S);
        assignin('base', 'F', csvread('Frequency.csv'));
      end
      clearvars fOu S F;
      fOu = evalin('base', 'fOu;');
      S = evalin('base', 'S;');
      F = evalin('base', 'F;');
      cd(curPath);
      
      sel_aaa_ratio = set_ratio;
      sel_aaa_numPorts = set_numPorts;

      selector = aaa_ratio <= sel_aaa_ratio & aaa_numPorts == sel_aaa_numPorts;
      selector = selector & fOu';

      [X, AI]= sort(aaa_conicalAngle, 'descend');
      sorted_S = S(:,:,AI,:);
      sorted_selector = selector(AI);
      sorted_conicalAngle = aaa_conicalAngle(AI);
      [worst, port] = max(sorted_S(3:9,2,sorted_selector,:),[],1);
      worst = squeeze(worst);
      port = squeeze(port);
      worstDB = 20*log10(abs(worst));
      figure(3);
      imagesc(F(1,:), sorted_conicalAngle(sorted_selector),worstDB);
      title(sprintf('Worst Isolation Between Port Pairs for %s = %.2f', 'ratio', sel_aaa_ratio));
      xlabel('Frequency [GHz]');
      ylabel('Conical Angle [degrees]');
      h = colorbar();
      ylabel(h, 'Isolation [dB]');
    end
		%% General methods
		function obj = Open()
			obj = IsolationStudy.GetObject('IsolationStudy');
		end
		function Close()
			IsolationStudy.GetEnv().Close('IsolationStudy');
    end
    function Clean()
        IsolationStudy.GetEnv().Clean('IsolationStudy');
    end
    function Run()
        IsolationStudy.Build;
        IsolationStudy.Setup;
        IsolationStudy.Solve;
        IsolationStudy.Results;
    end
    function Rebuild()
        obj = IsolationStudy.GetEnv().Open('IsolationStudy');
        obj.Rebuild;
    end
	end

end
