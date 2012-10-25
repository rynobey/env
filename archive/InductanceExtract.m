classdef InductanceExtract < cstenv.Project

	properties
	end

	methods (Static)
		%% Project specific methods
		function Build() % Commands for building the CAD model
			obj = InductanceExtract.GetObject('InductanceExtract');
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
		end
		function Setup() % Commands for setting up the simulation (e.g. generating mesh etc.)
			obj = InductanceExtract.GetObject('InductanceExtract');
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
			obj = InductanceExtract.GetObject('InductanceExtract');
		end
		function Results() % Commands for retrieving and/or post-processing the results
			obj = InductanceExtract.GetObject('InductanceExtract');
		end
		%% General methods
		function obj = Open()
			obj = InductanceExtract.GetEnv().Open('InductanceExtract');
		end
		function Close()
			InductanceExtract.GetEnv().Close('InductanceExtract');
		end
		function Clean()
			InductanceExtract.GetEnv().Clean('InductanceExtract');
		end
		function Run()
			InductanceExtract.Build;
			InductanceExtract.Setup;
			InductanceExtract.Solve;
			InductanceExtract.Results;
		end
	end

end
