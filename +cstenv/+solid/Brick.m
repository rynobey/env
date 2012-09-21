classdef Brick < cstenv.Solid
    %BRICK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        sizeX;
        sizeY;
        sizeZ;
    end
    
    methods
        function br = Brick(project, solidName, sizeX, sizeY, sizeZ)
            br@cstenv.Solid(project, solidName);
            br.sizeX = sizeX;
            br.sizeY = sizeY;
            br.sizeZ = sizeZ;
        end
        function seq = Create(br)
            obj = br.project.GetCOMObj('Brick');
            objName = 'Brick';
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset');
            seq.Add('Name', br.solidName);
            seq.Add('Component', br.componentName);
            seq.Add('Material', 'Vacuum');
            seq.Add('XRange', num2str(-br.sizeX/2), num2str(br.sizeX/2));
            seq.Add('YRange', num2str(-br.sizeY/2), num2str(br.sizeY/2));
            seq.Add('ZRange', num2str(-br.sizeZ/2), num2str(br.sizeZ/2));
            seq.Add('Create');
        end
    end
    
end

