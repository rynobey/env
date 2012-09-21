classdef Solid < handle
    %SOLID Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        offsetX = 0;
        offsetY = 0;
        offsetZ = 0;
        angleX = 0;
        angleY = 0;
        angleZ = 0;
        material = 'Vacuum';
        componentName = 'default';
        solidName;
        project;
        ports = cstenv.Port.empty(1,0);        
        parameters = cstenv.Parameter.empty(1,0);
    end
    properties (Dependent)
        solidPath;
    end
    
    methods
        function sol = Solid(project, solidName, varargin)
            sol.project = project;
            sol.solidName = solidName;
            if length(varargin) >= 1
                sol.componentName = varargin{1};
            end
            project.components(end + 1) = {sol};
        end
        function seq = InitParameters(sol)
            seq = cstenv.CommandSequence(sol.project, '');
            if length(sol.parameters) > 0 %#ok<ISMT>
                for n = 1:length(sol.parameters) %#ok<CPROP>
                    initSeq = sol.parameters(n).SetSeq();
                    seq = cstenv.CommandSequence.Join(seq, initSeq);
                end
            end
        end
        function seq = MoveExpr(sol, exprX, exprY, exprZ)
            objName = 'Transform';
            obj = sol.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);            
            seq.Add('Reset');
            if length(sol.ports) > 0 %#ok<ISMT>
                for n = 1:length(sol.ports)
                    tSeq = sol.ports(n).MoveExpr(exprX, exprY, exprZ);
                end
                seq = cstenv.CommandSequence.Join(seq, tSeq);
            end
            mSeq = cstenv.CommandSequence(obj, objName);            
            mSeq.Add('Reset');
            mSeq.Add('Name', sol.solidPath);
            mSeq.Add('Vector', exprX, exprY, exprZ);
            mSeq.Add('UsePickedPoints', 'False');
            mSeq.Add('InvertPickedPoints', 'False');
            mSeq.Add('MultipleObjects', 'False');
            mSeq.Add('GroupObjects', 'False');
            mSeq.Add('Repetitions', '1');
            mSeq.Add('MultipleSelection', 'False');
            mSeq.Add('Transform', 'Shape', 'Translate');
            seq = cstenv.CommandSequence.Join(seq, mSeq);
        end
        function seq = Move(sol, offsetX, offsetY, offsetZ, doUpdate)
            objName = 'Transform';
            obj = sol.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);            
            seq.Add('Reset');
            if length(sol.ports) > 0 %#ok<ISMT>
                for n = 1:length(sol.ports)
                    tSeq = sol.ports(n).MoveExpr(offsetX, offsetY, offsetZ, doUpdate);
                end
                seq = cstenv.CommandSequence.Join(seq, tSeq);
            end
            mSeq = cstenv.CommandSequence(obj, objName);            
            mSeq.Add('Reset');
            mSeq.Add('Name', sol.solidPath);
            mSeq.Add('Vector', num2str(offsetX), num2str(offsetY), num2str(offsetZ));
            mSeq.Add('UsePickedPoints', 'False');
            mSeq.Add('InvertPickedPoints', 'False');
            mSeq.Add('MultipleObjects', 'False');
            mSeq.Add('GroupObjects', 'False');
            mSeq.Add('Repetitions', '1');
            mSeq.Add('MultipleSelection', 'False');
            mSeq.Add('Transform', 'Shape', 'Translate');
            seq = cstenv.CommandSequence.Join(seq, mSeq);
            if doUpdate
                sol.offsetX = sol.offsetX + offsetX;
                sol.offsetY = sol.offsetY + offsetY;
                sol.offsetZ = sol.offsetZ + offsetZ;
            end
        end
        function seq = RotateExpr(sol, pExprX, pExprY, pExprZ, aExprX, aExprY, aExprZ)
            objName = 'Transform';
            obj = sol.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset');
            if length(sol.ports) > 0 %#ok<ISMT>
                for n = 1:length(sol.ports)
                    tSeq = sol.ports(n).RotateExpr(pExprX, pExprY, pExprZ, aExprX, aExprY, aExprZ);
                end
                seq = cstenv.CommandSequence.Join(seq, tSeq);
            end
            rSeq = cstenv.CommandSequence(obj, objName);    
            rSeq.Add('Name', sol.solidPath);
            rSeq.Add('Origin', 'Free');
            rSeq.Add('Center', pExprX, pExprY, pExprZ);
            rSeq.Add('Angle', aExprX, aExprY, aExprZ);
            rSeq.Add('MultipleObjects', 'False');
            rSeq.Add('GroupObjects', 'False');
            rSeq.Add('Repetitions', '1');
            rSeq.Add('MultipleSelection', 'False');
            rSeq.Add('Transform', 'Shape', 'Rotate');
            seq = cstenv.CommandSequence.Join(seq, rSeq);
        end
        function seq = Rotate(sol, pivotX, pivotY, pivotZ, angleX, angleY, angleZ, doUpdate)
            objName = 'Transform';
            obj = sol.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset');
            if length(sol.ports) > 0 %#ok<ISMT>
                for n = 1:length(sol.ports)
                    tSeq = sol.ports(n).Rotate(pivotX, pivotY, pivotZ, angleX, angleY, angleZ, doUpdate);
                end
                seq = cstenv.CommandSequence.Join(seq, tSeq);
            end
            rSeq = cstenv.CommandSequence(obj, objName);    
            rSeq.Add('Name', sol.solidPath);
            rSeq.Add('Origin', 'Free');
            rSeq.Add('Center', num2str(pivotX), num2str(pivotY), num2str(pivotZ));
            rSeq.Add('Angle', num2str(angleX), num2str(angleY), num2str(angleZ));
            rSeq.Add('MultipleObjects', 'False');
            rSeq.Add('GroupObjects', 'False');
            rSeq.Add('Repetitions', '1');
            rSeq.Add('MultipleSelection', 'False');
            rSeq.Add('Transform', 'Shape', 'Rotate');
            seq = cstenv.CommandSequence.Join(seq, rSeq);
            if doUpdate
                distX = pivotX - sol.offsetX;
                distY = pivotY - sol.offsetY;
                distZ = pivotZ - sol.offsetZ;
                if distX ~= 0 || distY ~= 0 || distZ ~= 0
                    if angleX ~= 0 && angleY == 0 && angleZ == 0
                        % TODO: implement
                    elseif angleY ~= 0 && angleZ == 0 && angleX == 0
                        pivotLengthZ = (pivotZ - sol.offsetZ);
                        pivotLengthX = (pivotX - sol.offsetX);
                        pivotR = sqrt(pivotLengthZ^2 + pivotLengthX^2);
                        angleFromPivot = atand(pivotLengthX/pivotLengthZ);
                        endAngle = angleFromPivot + angleY;
                        sol.offsetZ = pivotZ + pivotR*cosd(endAngle);
                        sol.offsetX = pivotX + pivotR*sind(endAngle);
                    elseif angleZ ~= 0 && angleX == 0 && angleY == 0
                        pivotLengthX = (pivotX - sol.offsetX);
                        pivotLengthY = (pivotY - sol.offsetY);
                        pivotR = sqrt(pivotLengthX^2 + pivotLengthY^2);
                        angleFromPivot = atand(pivotLengthY/pivotLengthX);
                        endAngle = angleFromPivot + angleZ;
                        sol.offsetX = pivotX + pivotR*cosd(endAngle);
                        sol.offsetY = pivotY + pivotR*sind(endAngle);
                    else
                        % TODO: error
                    end
                end
                sol.angleX = sol.angleX + angleX;
                sol.angleY = sol.angleY + angleY;
                sol.angleZ = sol.angleZ + angleZ;
            end
            
        end
        function seq = RotateAndCopyExpr(sol, pExprX, pExprY, pExprZ, aExprX, aExprY, aExprZ, repetitions)
            objName = 'Transform';
            obj = sol.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', sol.solidPath);
            seq.Add('Origin', 'Free');
            seq.Add('Center', pExprX, pExprY, pExprZ);
            seq.Add('Angle', aExprX, aExprY, aExprZ);
            seq.Add('MultipleObjects', 'True');
            seq.Add('GroupObjects', 'True');
            seq.Add('Repetitions', repetitions);
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Shape', 'Rotate');
            if length(sol.ports) > 0 %#ok<ISMT>
                for n = 1:length(sol.ports)
                    tSeq = sol.ports(n).RotateAndCopyExpr(pExprX, pExprY, pExprZ, aExprX, aExprY, aExprZ, repetitions);
                end
                seq = cstenv.CommandSequence.Join(seq, tSeq);
            end
        end
        function seq = RotateAndCopy(sol, pivotX, pivotY, pivotZ, angleX, angleY, angleZ, repetitions)
            objName = 'Transform';
            obj = sol.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', sol.solidPath);
            seq.Add('Origin', 'Free');
            seq.Add('Center', num2str(pivotX), num2str(pivotY), num2str(pivotZ));
            seq.Add('Angle', num2str(angleX), num2str(angleY), num2str(angleZ));
            seq.Add('MultipleObjects', 'True');
            seq.Add('GroupObjects', 'True');
            seq.Add('Repetitions', num2str(repetitions));
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Shape', 'Rotate');
            if length(sol.ports) > 0 %#ok<ISMT>
                for n = 1:length(sol.ports)
                    tSeq = sol.ports(n).RotateAndCopy(pivotX, pivotY, pivotZ, angleX, angleY, angleZ, repetitions);
                end
                seq = cstenv.CommandSequence.Join(seq, tSeq);
            end
        end
        function val = get.solidPath(sol)
            val = sprintf('%s:%s', sol.componentName, sol.solidName);
        end
    end
    methods (Static)
        function seq = ExtMoveExpr(project, solidPath, exprX, exprY, exprZ)
            objName = 'Transform';
            obj = project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', solidPath);
            seq.Add('Vector', exprX, exprY, exprZ);
            seq.Add('UsePickedPoints', 'False');
            seq.Add('InvertPickedPoints', 'False');
            seq.Add('MultipleObjects', 'False');
            seq.Add('GroupObjects', 'False');
            seq.Add('Repetitions', '1');
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Shape', 'Translate');
        end
        function seq = ExtMove(project, solidPath, offsetX, offsetY, offsetZ)
            objName = 'Transform';
            obj = project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', solidPath);
            seq.Add('Vector', num2str(offsetX), num2str(offsetY), num2str(offsetZ));
            seq.Add('UsePickedPoints', 'False');
            seq.Add('InvertPickedPoints', 'False');
            seq.Add('MultipleObjects', 'False');
            seq.Add('GroupObjects', 'False');
            seq.Add('Repetitions', '1');
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Shape', 'Translate');
        end
        function seq = ExtRotateExpr(project, solidPath, pExprX, pExprY, pExprZ, aExprX, aExprY, aExprZ)
            objName = 'Transform';
            obj = project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset');
            rSeq = cstenv.CommandSequence(obj, objName);    
            seq.Add('Name', solidPath);
            rSeq.Add('Origin', 'Free');
            seq.Add('Center', pExprX, pExprY, pExprZ);
            seq.Add('Angle', aExprX, aExprY, aExprZ);
            rSeq.Add('MultipleObjects', 'False');
            rSeq.Add('GroupObjects', 'False');
            rSeq.Add('Repetitions', '1');
            rSeq.Add('MultipleSelection', 'False');
            rSeq.Add('Transform', 'Shape', 'Rotate');
            seq = cstenv.CommandSequence.Join(seq, rSeq); 
        end
        function seq = ExtRotate(project, solidPath, pivotX, pivotY, pivotZ, angleX, angleY, angleZ)
            objName = 'Transform';
            obj = project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', solidPath);
            seq.Add('Origin', 'Free');
            seq.Add('Center', num2str(pivotX), num2str(pivotY), num2str(pivotZ));
            seq.Add('Angle', num2str(angleX), num2str(angleY), num2str(angleZ));
            seq.Add('MultipleObjects', 'False');
            seq.Add('GroupObjects', 'False');
            seq.Add('Repetitions', '1');
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Shape', 'Rotate');
        end
        function seq = ExtRotateAndCopyExpr(project, solidPath, pExprX, pExprY, pExprZ, aExprX, aExprY, aExprZ, repetitions)
            objName = 'Transform';
            obj = project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', solidPath);
            seq.Add('Origin', 'Free');
            seq.Add('Center', pExprX, pExprY, pExprZ);
            seq.Add('Angle', aExprX, aExprY, aExprZ);
            seq.Add('MultipleObjects', 'True');
            seq.Add('GroupObjects', 'True');
            seq.Add('Repetitions', repetitions);
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Shape', 'Rotate');
        end
        function seq = ExtRotateAndCopy(project, solidPath, pivotX, pivotY, pivotZ, angleX, angleY, angleZ, repetitions)
            objName = 'Transform';
            obj = project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', solidPath);
            seq.Add('Origin', 'Free');
            seq.Add('Center', num2str(pivotX), num2str(pivotY), num2str(pivotZ));
            seq.Add('Angle', num2str(angleX), num2str(angleY), num2str(angleZ));
            seq.Add('MultipleObjects', 'True');
            seq.Add('GroupObjects', 'True');
            seq.Add('Repetitions', num2str(repetitions));
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Shape', 'Rotate');
        end
    end
    
end

