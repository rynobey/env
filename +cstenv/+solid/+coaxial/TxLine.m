classdef TxLine < cstenv.Solid
  %TXLINE Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    innerRadius;
    outerRadius;
    length;
    impedance;
  end
  
  methods
    function tx = TxLine(project, solidName, innerRadius, outerRadius, length)
      tx@cstenv.Solid(project, solidName);
      tx.innerRadius = cstenv.Parameter(tx, 'innerRadius', innerRadius);
      tx.outerRadius = cstenv.Parameter(tx, 'outerRadius', outerRadius);
      tx.length = cstenv.Parameter(tx, 'length', length);
    end
    function seq = Create(tx)
      objName = 'Cylinder';
      obj = tx.project.GetCOMObj(objName);
      seq = cstenv.CommandSequence(obj, objName);
      
      seq.Add('Reset');
      seq.Add('Name', tx.solidName);
      seq.Add('Component', tx.componentName);
      seq.Add('Material', tx.material);
      seq.Add('OuterRadius', tx.outerRadius.name);
      seq.Add('InnerRadius', tx.innerRadius.name);
      seq.Add('Axis', 'z');
      seq.Add('ZRange', sprintf('-%s/2', tx.length.name), sprintf('%s/2', ...
        tx.length.name));
      seq.Add('XCenter', num2str(0));
      seq.Add('YCenter', num2str(0));
      seq.Add('ZCenter', num2str(0));
      seq.Add('Create');
      
      initSeq = tx.InitParameters();
      seq = cstenv.CommandSequence.Join(initSeq, seq);
    end
    function seq = PickPortFace(tx, direction)
      %NOTE: it is assumed that no rotation or translation operations
      %have been performed before calling this method
      obj = tx.project.GetCOMObj('Pick');
      objName = 'Pick';
      seq = cstenv.CommandSequence(obj, objName);
      seq.Add('ClearAllPicks');
      dR = sprintf('(%s + %s)/2', tx.innerRadius.name, tx.outerRadius.name);
      if strcmp(direction,'+')
        seq.Add('PickFaceFromPoint', tx.solidPath, dR, num2str(0), ...
          sprintf('%s/2', tx.length.name));
      elseif strcmp(direction,'-')
        seq.Add('PickFaceFromPoint', tx.solidPath, dR, num2str(0), ...
          sprintf('-%s/2', tx.length.name));
      end
    end
    function impedance = get.impedance(tx)
      impedance = ...
        cstenv.solid.coaxial.TxLine.CalcImpedance(tx.innerRadius.value, ...
        tx.outerRadius.value);
    end
  end
  methods (Static)
    function radiusExpr = CalOuterExpr(impedance, innerRadius)
      radiusExpr = sprintf('(%s)*exp((%s)/60)', impedance, innerRadius);
    end
    function radius = CalcOuter(impedance, innerRadius)
      radius = innerRadius*exp(impedance/60);
    end
    function radiusExpr = CalcInnerExpr(impedance, outerRadius)
      radiusExpr = sprintf('(%s)/exp((%s)/60)', outerRadius, impedance);
    end
    function radius = CalcInner(impedance, outerRadius)
      radius = outerRadius/exp(impedance/60);
    end
    function impedanceExpr = CalImpedanceExpr(innerRadius, outerRadius)
      impedanceExpr = sprintf('60*log((%s)/(%s))', innerRadius, outerRadius);
    end
    function impedance = CalcImpedance(innerRadius, outerRadius)
      impedance = 60*log(outerRadius/innerRadius);
    end
  end
end
