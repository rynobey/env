classdef CenterConicalCoax < cstenv.Solid
    %CENTERCONICALCOAX Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        conicalTxLine;
        coaxialTxLine;
        radius;
    end
    
    methods
        function trans = CenterConicalCoax(project, solidName, conical, coaxial, radius)
            trans@cstenv.Solid(project, solidName);
            trans.conicalTxLine = conical;
            trans.coaxialTxLine = coaxial;
            trans.radius = cstenv.Parameter(trans, 'radius', radius);
        end
        function seq = Create(trans)
            R1 = trans.coaxialTxLine.innerRadius.name;
            R2 = trans.coaxialTxLine.outerRadius.name;
            r1 = trans.radius.name;
            t1 = trans.conicalTxLine.theta1.name;
            t2 = trans.conicalTxLine.theta2.name;
            arg1 = sprintf('(%s - (%s + %s)*sind(90 - %s))', r1, R2, r1, t2);
            arg2 = sprintf('cosd(90 - %s)', t2);
            a = cstenv.Parameter(trans, 'a', sprintf('(%s)/(%s)', arg1, arg2), 1);
            arg1 = sprintf('%s*cosd(90 - %s)', a.name, t1);
            arg2 = sprintf('%s*sind(90 - %s)', R1, t1);
            arg1 = sprintf('-(%s + %s)', arg1, arg2);
            arg2 = sprintf('(sind(90 - %s) - 1)', t1);
            r2 = sprintf('(%s)/(%s)', arg1, arg2);
            
            % create profile
            objName = 'Torus';
            obj = trans.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            t1Path = trans.solidPath;
            seq.Add('Reset');
            seq.Add('Component', trans.componentName);
            seq.Add('Name', trans.solidName);
            seq.Add('Material', trans.conicalTxLine.material);
            seq.Add('OuterRadius', sprintf('%s + 2*%s', R1, r2));
            seq.Add('InnerRadius', R1);
            seq.Add('Axis', 'z');
            seq.Add('XCenter', '0');
            seq.Add('YCenter', '0');
            seq.Add('ZCenter', a.name);
            seq.Add('Segments', '0');
            seq.Add('Create');
            
            t2Path = sprintf('%s:%s', 'temp', 'torus2');
            seq.Add('Reset');
            seq.Add('Component', 'temp');
            seq.Add('Name', 'torus2');
            seq.Add('Material', trans.conicalTxLine.material);
            seq.Add('OuterRadius', sprintf('%s + 2*%s', R2, r1));
            seq.Add('InnerRadius', R2);
            seq.Add('Axis', 'z');
            seq.Add('XCenter', '0');
            seq.Add('YCenter', '0');
            seq.Add('ZCenter', a.name);
            seq.Add('Segments', '0');
            seq.Add('Create');
            
            obj = trans.project.GetCOMObj('Solid');
            seq.cmdArr(end + 1) = cstenv.Command(obj, 'Solid', 'Subtract', t1Path, t2Path);
            
            % create transition
            objName = 'Cone';
            obj = trans.project.GetCOMObj(objName);
            cSeq = cstenv.CommandSequence(obj, objName);
            c1Path = sprintf('%s:%s', 'temp', 'cone1');
            cSeq.Add('Reset');
            cSeq.Add('Component', 'temp');
            cSeq.Add('Name', 'cone1');
            cSeq.Add('Material', trans.conicalTxLine.material);
            cSeq.Add('BottomRadius', sprintf('%s + %s - %s*sind(90 - %s)', R2, r1, r1, t2));
            cSeq.Add('TopRadius', sprintf('%s + %s', R2, r1));
            cSeq.Add('Axis', 'z');
            cSeq.Add('Zrange', sprintf('%s - %s*cosd(90 - %s)', a.name, r1, t2), a.name);
            cSeq.Add('XCenter', '0');
            cSeq.Add('YCenter', '0');
            cSeq.Add('ZCenter', '0');
            cSeq.Add('Segments', '0');
            cSeq.Add('Create');
            
            c2Path = sprintf('%s:%s', 'temp', 'cone2');
            cSeq.Add('Reset');
            cSeq.Add('Component', 'temp');
            cSeq.Add('Name', 'cone2');
            cSeq.Add('Material', trans.conicalTxLine.material);
            cSeq.Add('BottomRadius', sprintf('%s + %s - %s*sind(90 - %s)', R1, r2, r2, t1));
            cSeq.Add('TopRadius', sprintf('%s + %s - %s*sind(90 - %s)', R2, r1, r1, t2));
            cSeq.Add('Axis', 'z');
            arg1 = sprintf('%s - %s*cosd(90-%s)', a.name, r2, t1);
            arg2 = sprintf('%s - %s*cosd(90-%s)', a.name, r1, t2);
            cSeq.Add('Zrange', arg1, arg2);
            cSeq.Add('XCenter', '0');
            cSeq.Add('YCenter', '0');
            cSeq.Add('ZCenter', '0');
            cSeq.Add('Segments', '0');
            cSeq.Add('Create');
            
            obj = trans.project.GetCOMObj('Solid');
            cSeq.cmdArr(end + 1) = cstenv.Command(obj, 'Solid', 'Add', c2Path, c1Path);
            cSeq.cmdArr(end + 1) = cstenv.Command(obj, 'Solid', 'Intersect', t1Path, c2Path);
            seq = cstenv.CommandSequence.Join(seq, cSeq);
            
            % adjust conical tx line
            objName = 'Cone';
            obj = trans.project.GetCOMObj(objName);
            cSeq = cstenv.CommandSequence(obj, objName);
            c3Path = sprintf('%s:%s', 'temp', 'cone3');
            cSeq.Add('Reset');
            cSeq.Add('Component', 'temp');
            cSeq.Add('Name', 'cone3');
            cSeq.Add('Material', trans.conicalTxLine.material);
            cSeq.Add('BottomRadius', sprintf('%s + %s - %s*sind(90 - %s)', R2, r1, r1, t2));
            cSeq.Add('TopRadius', sprintf('%s + %s', R2, r1));
            cSeq.Add('Axis', 'z');
            cSeq.Add('Zrange', sprintf('%s - %s*cosd(90-%s)', a.name, r1, t2), sprintf('abs(%s)', a.name));
            cSeq.Add('XCenter', '0');
            cSeq.Add('YCenter', '0');
            cSeq.Add('ZCenter', '0');
            cSeq.Add('Segments', '0');
            cSeq.Add('Create');
            
            c4Path = sprintf('%s:%s', 'temp', 'cone4');
            cSeq.Add('Reset');
            cSeq.Add('Component', 'temp');
            cSeq.Add('Name', 'cone4');
            cSeq.Add('Material', trans.conicalTxLine.material);
            cSeq.Add('BottomRadius', sprintf('%s + %s - %s*sind(90 - %s)', R1, r2, r2, t1));
            cSeq.Add('TopRadius', sprintf('%s + %s - %s*sind(90 - %s)', R2, r1, r1, t2));
            cSeq.Add('Axis', 'z');
            arg1 = sprintf('%s - %s*cosd(90-%s)', a.name, r2, t1);
            arg2 = sprintf('%s - %s*cosd(90-%s)', a.name, r1, t2);
            cSeq.Add('Zrange', arg1, arg2);
            cSeq.Add('XCenter', '0');
            cSeq.Add('YCenter', '0');
            cSeq.Add('ZCenter', '0');
            cSeq.Add('Segments', '0');
            cSeq.Add('Create');
            
            obj = trans.project.GetCOMObj('Solid');
            cSeq.cmdArr(end + 1) = cstenv.Command(obj, 'Solid', 'Add', c3Path, c4Path);
            cSeq.cmdArr(end + 1) = cstenv.Command(obj, 'Solid', 'Subtract', trans.conicalTxLine.solidPath, c3Path);
            seq = cstenv.CommandSequence.Join(seq, cSeq);
            
            aSeq = trans.coaxialTxLine.MoveExpr('0', '0', sprintf('%s + %s/2', a.name, trans.coaxialTxLine.length.name));
            seq = cstenv.CommandSequence.Join(seq, aSeq);

            initSeq = trans.InitParameters();
            seq = cstenv.CommandSequence.Join(initSeq, seq);
        end
    end
    
end

