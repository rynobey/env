classdef Port < handle
    %PORT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        offsetX = 0;
        offsetY = 0;
        offsetZ = 0;
        angleX = 0;
        angleY = 0;
        angleZ = 0;
        orientation = 'positive';
        portNumber = 1;
        project;
        solid;
    end
    properties (Dependent)
        portName;
    end
    
    methods
        function port = Port(project, solid, varargin)
            port.project = project;
            port.solid = solid;
            if length(varargin) > 0 %#ok<ISMT>
                port.portNumber = varargin{1};
            end
            solid.ports(end + 1) = port;
        end
        function seq = Create(port)
            obj = port.project.GetCOMObj('Port');
            objName = 'Port';
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset');
            seq.Add('PortNumber', num2str(port.portNumber));
            seq.Add('Label', '');
            seq.Add('NumberOfModes', '1');
            seq.Add('AdjustPolarization', 'False');
            seq.Add('PolarizationAngle', '0.0');
            seq.Add('ReferencePlaneDistance', '0.0');
            seq.Add('TextSize', '50');
            seq.Add('Coordinates', 'Picks');
            seq.Add('Orientation', port.orientation);
            seq.Add('PortOnBound', 'True');
            seq.Add('ClipPickedPortToBound', 'False');
            seq.Add('SingleEnded', 'False');
            seq.Add('Create');
        end
        function seq = MoveExpr(port, exprX, exprY, exprZ)
            objName = 'Transform';
            obj = port.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', port.portName);
            seq.Add('Vector', exprX, exprY, exprZ);
            seq.Add('UsePickedPoints', 'False');
            seq.Add('InvertPickedPoints', 'False');
            seq.Add('MultipleObjects', 'False');
            seq.Add('GroupObjects', 'False');
            seq.Add('Repetitions', '1');
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Port', 'Translate');
        end
        function seq = Move(port, offsetX, offsetY, offsetZ, doUpdate)
            objName = 'Transform';
            obj = port.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', port.portName);
            seq.Add('Vector', num2str(offsetX), num2str(offsetY), num2str(offsetZ));
            seq.Add('UsePickedPoints', 'False');
            seq.Add('InvertPickedPoints', 'False');
            seq.Add('MultipleObjects', 'False');
            seq.Add('GroupObjects', 'False');
            seq.Add('Repetitions', '1');
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Port', 'Translate');
            if doUpdate
                port.offsetX = port.offsetX + offsetX;
                port.offsetY = port.offsetY + offsetY;
                port.offsetZ = port.offsetZ + offsetZ;
            end
        end
        function seq = RotateExpr(port, pExprX, pExprY, pExprZ, aExprX, aExprY, aExprZ)
            objName = 'Transform';
            obj = port.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', port.portName);
            seq.Add('Origin', 'Free');
            seq.Add('Center', pExprX, pExprY, pExprZ);
            seq.Add('Angle', aExprX, aExprY, aExprZ);
            seq.Add('MultipleObjects', 'False');
            seq.Add('GroupObjects', 'False');
            seq.Add('Repetitions', '1');
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Port', 'Rotate');
        end
        function seq = Rotate(port, pivotX, pivotY, pivotZ, angleX, angleY, angleZ, doUpdate)
            objName = 'Transform';
            obj = port.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', port.portName);
            seq.Add('Origin', 'Free');
            seq.Add('Center', num2str(pivotX), num2str(pivotY), num2str(pivotZ));
            seq.Add('Angle', num2str(angleX), num2str(angleY), num2str(angleZ));
            seq.Add('MultipleObjects', 'False');
            seq.Add('GroupObjects', 'False');
            seq.Add('Repetitions', '1');
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Port', 'Rotate');
            if doUpdate
                distX = pivotX - port.offsetX;
                distY = pivotY - port.offsetY;
                distZ = pivotZ - port.offsetZ;
                if distX ~= 0 || distY ~= 0 || distZ ~= 0
                    if angleX ~= 0 && angleY == 0 && angleZ == 0
                        % TODO: implement
                    elseif angleY ~= 0 && angleZ == 0 && angleX == 0
                        pivotLengthZ = (pivotZ - port.offsetZ);
                        pivotLengthX = (pivotX - port.offsetX);
                        pivotR = sqrt(pivotLengthZ^2 + pivotLengthX^2);
                        angleFromPivot = atand(pivotLengthX/pivotLengthZ);
                        endAngle = angleFromPivot + angleY;
                        port.offsetZ = pivotZ + pivotR*cosd(endAngle);
                        port.offsetX = pivotX + pivotR*sind(endAngle);
                    elseif angleZ ~= 0 && angleX == 0 && angleY == 0
                        pivotLengthX = (pivotX - port.offsetX);
                        pivotLengthY = (pivotY - port.offsetY);
                        pivotR = sqrt(pivotLengthX^2 + pivotLengthY^2);
                        angleFromPivot = atand(pivotLengthY/pivotLengthX);
                        endAngle = angleFromPivot + angleZ;
                        port.offsetX = pivotX + pivotR*cosd(endAngle);
                        port.offsetY = pivotY + pivotR*sind(endAngle);
                    else
                        % TODO: error
                    end
                end
                port.angleX = port.angleX + angleX;
                port.angleY = port.angleY + angleY;
                port.angleZ = port.angleZ + angleZ;
            end
        end
        function seq = RotateAndCopyExpr(port, pExprX, pExprY, pExprZ, aExprX, aExprY, aExprZ, repetitions)
            objName = 'Transform';
            obj = port.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', port.portName);
            seq.Add('Origin', 'Free');
            seq.Add('Center', pExprX, pExprY, pExprZ);
            seq.Add('Angle', aExprX, aExprY, aExprZ);
            seq.Add('MultipleObjects', 'True');
            seq.Add('GroupObjects', 'False');
            seq.Add('Repetitions', repetitions);
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Port', 'Rotate');
        end
        function seq = RotateAndCopy(port, pivotX, pivotY, pivotZ, angleX, angleY, angleZ, repetitions)
            objName = 'Transform';
            obj = port.project.GetCOMObj(objName);
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset')
            seq.Add('Name', port.portName);
            seq.Add('Origin', 'Free');
            seq.Add('Center', num2str(pivotX), num2str(pivotY), num2str(pivotZ));
            seq.Add('Angle', num2str(angleX), num2str(angleY), num2str(angleZ));
            seq.Add('MultipleObjects', 'True');
            seq.Add('GroupObjects', 'False');
            seq.Add('Repetitions', num2str(repetitions));
            seq.Add('MultipleSelection', 'False');
            seq.Add('Transform', 'Port', 'Rotate');
        end
        function name = get.portName(port)
            name = sprintf('port%d', port.portNumber);
        end
    end
    
end

