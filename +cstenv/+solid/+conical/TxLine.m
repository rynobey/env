classdef TxLine < cstenv.Solid
    %TXLINE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        radius;
        theta1;
        theta2;
        impedance;
        dTheta;
        dThetaExpr;
        avgTheta;
        avgThetaExpr;
    end
    
    methods
        function tx = TxLine(project, solidName, theta1, theta2, radius)
            tx@cstenv.Solid(project, solidName);
            tx.theta1 = cstenv.Parameter(tx, 'theta1', theta1);
            tx.theta2 = cstenv.Parameter(tx, 'theta2', theta2);
            tx.radius = cstenv.Parameter(tx, 'radius', radius);
        end
        function seq = Create(tx)
            % create face
            fPath = sprintf('%s:%s', 'temp', 'face1');
            objName = 'AnalyticalFace';
            obj = tx.project.GetCOMObj(objName);
            fSeq = cstenv.CommandSequence(obj, objName);
            fSeq.Add('Reset');
            fSeq.Add('component', 'temp');
            fSeq.Add('Name', 'face1');
            fSeq.Add('Material', tx.material);
            fSeq.Add('LawX', 'u');
            fSeq.Add('LawY', '0');
            hParam = cstenv.Parameter(tx, 'hConical', sprintf('tand((%s)/2)', tx.dThetaExpr), 1);
            fSeq.Add('LawZ', sprintf('v*u*%s', hParam.name));
            fSeq.Add('ParameterRangeU', '0', tx.radius.name);
            fSeq.Add('ParameterRangeV', '-1', '1');
            fSeq.Add('Create');
            
            % transform face
            expr = sprintf('90-%s+(%s)/2', tx.theta2.name, tx.dThetaExpr);
            trSeq = cstenv.Solid.ExtRotateExpr(tx.project, fPath, '0', '0', '0', '0', expr, '0');
            seq = cstenv.CommandSequence.Join(fSeq, trSeq);
            
            % rotate face            
            objName = 'Pick';
            obj = tx.project.GetCOMObj(objName);
            pSeq = cstenv.CommandSequence(obj, objName);
            pSeq.Add('ClearAllPicks');
            pSeq.Add('PickFaceFromId', fPath, '1');
            pSeq.Add('AddEdge', '0.0', '0.0', '10', '0.0', '0.0', '-10');
            seq = cstenv.CommandSequence.Join(seq, pSeq);
            objName = 'Rotate';
            obj = tx.project.GetCOMObj(objName);
            rSeq = cstenv.CommandSequence(obj, objName);
            rSeq.Add('Reset');
            rSeq.Add('Component', tx.componentName);
            rSeq.Add('Name', tx.solidName);
            rSeq.Add('Material', tx.material);
            rSeq.Add('Mode', 'Picks');
            rSeq.Add('Angle', '360');
            rSeq.Add('Height', '0.0');
            rSeq.Add('RadiusRatio', '1.0');
            rSeq.Add('NSteps', '0');
            rSeq.Add('SplitClosedEdges', 'True');
            rSeq.Add('SegmentedProfile', 'False');
            rSeq.Add('DeleteBaseFaceSolid', 'True');
            rSeq.Add('SimplifySolid', 'True');
            rSeq.Add('UseAdvancedSegmentedRotation', 'True');
            rSeq.Add('Create');
            seq = cstenv.CommandSequence.Join(seq, rSeq);
            obj = tx.project.GetCOMObj('Pick');
            seq.cmdArr(end + 1) = cstenv.Command(obj, 'Pick', 'ClearAllPicks');
            
            % spherial ends
            sPath = sprintf('%s:%s', 'temp', 'sphere1');
            objName = 'Sphere';
            obj = tx.project.GetCOMObj(objName);
            sSeq = cstenv.CommandSequence(obj, objName);
            sSeq.Add('Reset');
            sSeq.Add('Component', 'temp');
            sSeq.Add('Name', 'sphere1');
            sSeq.Add('Material', tx.material);
            sSeq.Add('Axis', 'z');
            sSeq.Add('CenterRadius', tx.radius.name);
            sSeq.Add('TopRadius', '0');
            sSeq.Add('BottomRadius', '0');
            sSeq.Add('Center', '0', '0', '0');
            sSeq.Add('Segments', '0');
            sSeq.Add('Create');
            seq = cstenv.CommandSequence.Join(seq, sSeq);
            obj = tx.project.GetCOMObj('Solid');
            seq.cmdArr(end + 1) = cstenv.Command(obj, 'Solid', 'Intersect', tx.solidPath, sPath);
            
            initSeq = tx.InitParameters();
            seq = cstenv.CommandSequence.Join(initSeq, seq);
        end 
        function avgTheta = get.avgTheta(tx)
            avgTheta = (tx.theta1 + tx.theta2)/2;
        end
        function dTheta = get.dTheta(tx)
            dTheta = abs(tx.theta1 - tx.theta2);
        end
        function impedance = get.impedance(tx)
            impedance = CalcImpedanc(tx.theta1, tx.theta2);
        end
        function expr = get.avgThetaExpr(tx)
            expr = sprintf('(%s + %s)/2', tx.theta1.name, tx.theta2.name);
        end
        function expr = get.dThetaExpr(tx)
            expr = sprintf('abs(%s - %s)', tx.theta1.name, tx.theta2.name);
        end
    end
    
    methods (Static)
        function theta1Expr = CalcTheta1Expr(impedance, theta2)
            theta1Expr = sprintf('2*atnd(tand((%s)/2)/exp((%s)/60))', theta2, impedance);
        end
        function theta1 = CalcTheta1(impedance, theta2)
            theta1 = 2*atand(tand(theta2/2)/exp(impedance/60));
        end
        function impedanceExpr = CalcImpedanceExpr(theta1, theta2)
            impedanceExpr = sprintf('60*log(tand((%s)/2)/tand((%s)/2))', theta2, theta1);
        end
        function impedance = CalcImpedance(theta1, theta2)
            impedance = 60*log(tand(theta2/2)/tand(theta1/2));
        end
    end
    
end

