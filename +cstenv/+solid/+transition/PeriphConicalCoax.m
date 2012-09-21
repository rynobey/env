classdef PeriphConicalCoax < cstenv.Solid
    %PERIPHCONICALCOAX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        placementRadius;
        numPorts;
        conicalTxLine;
        coaxialTxLine;
        direction;
    end
    
    methods
        function trans = PeriphConicalCoax(project, solidName, conical, coaxial, placementRadius, numPorts, direction)
            trans@cstenv.Solid(project, solidName);
            trans.conicalTxLine = conical;
            trans.coaxialTxLine = coaxial;
            trans.placementRadius = cstenv.Parameter(trans, 'placementRadius', placementRadius);
            trans.numPorts = cstenv.Parameter(trans, 'numPorts', numPorts);
            trans.direction = direction;
        end
        function seq = Create(trans)
            % adjust the conical tx line: add coax pins
            objName = 'Cylinder';
            obj = trans.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            iR = trans.coaxialTxLine.innerRadius.name;
            pR = trans.placementRadius.name;
            pinPath = sprintf('%s:%s', 'temp', 'pin1');
            seq.Add('Reset');
            seq.Add('Component', 'temp');
            seq.Add('Name', 'pin1');
            seq.Add('Material', trans.conicalTxLine.material);
            seq.Add('OuterRadius', iR);
            seq.Add('InnerRadius', '0');
            seq.Add('Axis', 'z');
            hDZ = sprintf('-2*(%s + %s)*Pi/180*(%s)/2', pR, iR, trans.conicalTxLine.dThetaExpr);
            seq.Add('Zrange', hDZ, sprintf('-(%s)', hDZ));
            seq.Add('XCenter', pR);
            seq.Add('YCenter', '0');
            seq.Add('Segments', '0');
            seq.Add('Create');
            
            rSeq = cstenv.Solid.ExtRotateExpr(trans.project, pinPath, '0', '0', '0', '0', sprintf('90-%s', trans.conicalTxLine.avgThetaExpr), '0');
            seq = cstenv.CommandSequence.Join(seq, rSeq);
            
            rSeq = cstenv.Solid.ExtRotateAndCopyExpr(trans.project, pinPath, '0', '0', '0', '0', '0', sprintf('360/%s', trans.numPorts.name), sprintf('%s - 1', trans.numPorts.name));
            seq = cstenv.CommandSequence.Join(seq, rSeq);
            
            obj = trans.project.GetCOMObj('Solid');
            seq.cmdArr(end + 1) = cstenv.Command(obj, 'Solid', 'Subtract', trans.conicalTxLine.solidPath, pinPath);
            
            lTemp = sprintf('(0.1 + (%s)*Pi/180*(%s)/2)', pR, trans.conicalTxLine.dThetaExpr);
            coaxTemp = cstenv.solid.coaxial.TxLine(trans.project, 'coaxTemp', iR, trans.coaxialTxLine.outerRadius.name, lTemp);
            coaxTemp.componentName = 'temp';
            seq = cstenv.CommandSequence.Join(seq, coaxTemp.Create());
            mSeq = coaxTemp.MoveExpr(pR, '0', sprintf('%s/2', lTemp));
            seq = cstenv.CommandSequence.Join(seq, mSeq);
            rSeq = coaxTemp.RotateExpr('0', '0', '0', '0', sprintf('90-%s', trans.conicalTxLine.avgThetaExpr), '0');
            seq = cstenv.CommandSequence.Join(seq, rSeq);
            rSeq = coaxTemp.RotateAndCopyExpr('0', '0', '0', '0', '0', sprintf('360/(%s)', trans.numPorts.name), sprintf('%s - 1', trans.numPorts.name));
            seq = cstenv.CommandSequence.Join(seq, rSeq);
            obj = trans.project.GetCOMObj('Solid');
            seq.cmdArr(end + 1) = cstenv.Command(obj, 'Solid', 'Add', trans.conicalTxLine.solidPath, coaxTemp.solidPath);
            
            % move coaxial tx line into position
            mSeq = trans.coaxialTxLine.MoveExpr(pR, '0', sprintf('%s + 0.99*(%s)/2', lTemp, trans.coaxialTxLine.length.name));
            seq = cstenv.CommandSequence.Join(seq, mSeq);
            rSeq = trans.coaxialTxLine.RotateExpr('0', '0', '0', '0', sprintf('90-(%s)', trans.conicalTxLine.avgThetaExpr), '0');
            seq = cstenv.CommandSequence.Join(seq, rSeq);
            rSeq = trans.coaxialTxLine.RotateAndCopyExpr('0', '0', '0', '0', '0', sprintf('360/(%s)', trans.numPorts.name), sprintf('%s - 1', trans.numPorts.name));
            seq = cstenv.CommandSequence.Join(seq, rSeq);

            initSeq = trans.InitParameters();
            seq = cstenv.CommandSequence.Join(initSeq, seq);
        end
    end
    
end

