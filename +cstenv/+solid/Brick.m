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
            br.sizeX = cstenv.Parameter(br, 'sizeX', sizeX);
            br.sizeY = cstenv.Parameter(br, 'sizeY', sizeY);
            br.sizeZ = cstenv.Parameter(br, 'sizeZ', sizeZ);
        end
        function seq = Create(br)
            obj = br.project.GetCOMObj('Brick');
            objName = 'Brick';
            seq = cstenv.CommandSequence(obj, objName);
            seq.Add('Reset');
            seq.Add('Name', br.solidName);
            seq.Add('Component', br.componentName);
            seq.Add('Material', 'Vacuum');
            seq.Add('XRange', sprintf('-%s/2', br.sizeX.name), sprintf('%s/2', br.sizeX.name));
            seq.Add('YRange', sprintf('-%s/2', br.sizeY.name), sprintf('%s/2', br.sizeY.name));
            seq.Add('ZRange', sprintf('-%s/2', br.sizeZ.name), sprintf('%s/2', br.sizeZ.name));
            seq.Add('Create');
            
            initSeq = br.InitParameters();
            seq = cstenv.CommandSequence.Join(initSeq, seq);
        end
    end
    
end

