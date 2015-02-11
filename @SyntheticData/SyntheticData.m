% This code generates a synthetic retina picture that the user can
% then test himself against
%
% It displays an image of a retina, and then 
%

classdef SyntheticData < handle
  
  properties
    
    dataFig = [];
    dataAxis = [];
    
    image = [];
    
    % Radius of mouse eye is 800 mum at P0, 1400 mum at P8, 1600
    % mum at adult
    % Rim amgle of mouse eyes are 53 degrees at P0, 55 degrees at
    % P8 and 68 degrees at adult
    meanRadius = 300; % For article text we scale it up by 1400/300
                      % to correspond to P8 mouse eye
    radiusSpread = 0.05;
    meanRimAngle = pi*53/180; % pi*35/180;
    rimAngleSpread = 0.05; % 0.2        
    
    % Randomize these
    radius = [100; 100; 100];
    rimAngle = [];
    
    topView = [];
    sideView = [];
    
    injectionHandle = [];
    
    topViewDefaultCentre = [400; 1100; 0];
    sideViewDefaultCentre = [400; 200; 0];
    
    injectionCentre = [];
    injectionSpread = pi/30;
    
    injectionCentreXYZ = [];
    injNT = [];
    injDV = [];
    
    injectionN = 100;
    injectionPointsXYZ = [];
    
    ID = [];
    score = [];
    NTdeviation = [];
    DVdeviation = [];
    
    createTime = [];
    finishTime = [];
    
    oldScores = []; % struct('ID',[],'score',[]);
    
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function obj = SyntheticData(axisHandle)
      
      if(~exist('axisHandle') | isempty(axisHandle))
      
        % Later on hide this figure, so user does not see it as we work
        % on it
        obj.dataFig = figure('units','normalized')
        obj.dataAxis = axes();
        axis equal
      else
        obj.dataFig = [];
        obj.dataAxis =  axisHandle;
        axis equal
      end
        
      % Randomize two eye positions
      obj.topView = EyeSphere('top', 'left', obj.topViewDefaultCentre, obj.dataAxis);
      obj.sideView = EyeSphere('side', 'left', obj.sideViewDefaultCentre, obj.dataAxis);
        

      obj.randomizeEye();
      obj.plot();

      obj.loadOldScores();
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function randomizeEye(obj)

      obj.randomizeEyeShape();
      obj.makeInjection();
      
      obj.randomizeEyeLocation();

      obj.createTime = now();
      obj.ID = obj.createTime;

      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function plot(obj)

      obj.topView.plotSphere();
      obj.sideView.plotSphere();

      obj.plotInjection();
      
      obj.setAxis();
      
      obj.tweakView();
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function tweakView(obj)

      lighting gouraud
      
      set(obj.topView.handleEllipsoid,'linestyle','none')
      set(obj.sideView.handleEllipsoid,'linestyle','none')      

      set(obj.topView.handleEllipsoid,'facealpha',0.5,'edgealpha',0.5)
      set(obj.sideView.handleEllipsoid,'facealpha',0.5,'edgealpha',0.5)      
      
      delete(obj.topView.handleY);
      delete(obj.topView.handleZ);
      delete(obj.sideView.handleY);
      delete(obj.sideView.handleZ);
      
      obj.topView.handleY = [];
      obj.topView.handleZ = [];      
      obj.sideView.handleY = [];      
      obj.sideView.handleZ = [];            
      
      delete(obj.topView.handleRim)
      delete(obj.sideView.handleRim)
      
      obj.topView.handleRim = [];
      obj.sideView.handleRim = [];
      
      colormap('winter')
      
      axis off
      
      lightangle(-45,30)
      
      delete(obj.topView.handleX(2))
      delete(obj.sideView.handleX(2))      
      
      obj.topView.handleX = obj.topView.handleX([1 3]);
      obj.sideView.handleX = obj.sideView.handleX([1 3]);      
      
      set(obj.topView.handleX(end),'String','M')
      set(obj.sideView.handleX(end),'String','M')      
      
      set(obj.topView.handleX,'color','black')
      set(obj.sideView.handleX,'color','black')
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function setAxis(obj)
      
      maxAxis = max(obj.topView.centre + max(obj.topView.radius), ...
                    obj.sideView.centre + max(obj.sideView.radius));

      minAxis = min(obj.topView.centre - max(obj.topView.radius), ...
                    obj.sideView.centre - max(obj.sideView.radius));
      
      xMin = minAxis(1) - (0.2 + 0.2*rand(1)) * abs(minAxis(1));
      xMax = maxAxis(1) + (0.2 + 0.2*rand(1)) * abs(maxAxis(1));
      yMin = minAxis(2) - (0.2 + 0.2*rand(1)) * abs(minAxis(2));
      yMax = maxAxis(2) + (0.2 + 0.2*rand(1)) * abs(maxAxis(2));
      
      axis([xMin xMax yMin yMax])

    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function randomizeEyeLocation(obj)
    
     topPos = obj.topViewDefaultCentre .* (1 + 0.1*randn(3,1));
     sidePos = obj.sideViewDefaultCentre .* (1 - 0.1*randn(3,1));     
      
     obj.topView.centre = topPos;
     obj.sideView.centre = sidePos;
     
     % Also jitter rotation a bit
     defaultTop = [0 0 0];
     defaultSide = [-pi/2 0 0];
     
     obj.topView.angle = defaultTop + randn(1,3).*[pi/20 pi/20 2*pi];
     
     % Make sure that we put injection on the front side of the
     % side view
     
     okSideRot = false;
     
     while(~okSideRot)
       disp('Randomizing side view rotation')
       
       obj.sideView.angle = defaultSide + randn(1,3).*[pi/20 pi/20 2*pi];
       obj.sideView.setViewTransform(obj.sideView.angle);
       
       x = obj.radius(1)*sin(obj.injectionCentre(1))*cos(obj.injectionCentre(2));
       y = obj.radius(2)*sin(obj.injectionCentre(1))*sin(obj.injectionCentre(2));
       z = obj.radius(3)*cos(obj.injectionCentre(1));

       [xS,yS,zS] = obj.sideView.transXYZ(x,y,z);
     
       if(zS >= 0)
         okSideRot = true;
       end
       
     end
     
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function randomizeEyeShape(obj)

      % Randomize eye size and rim angle
        
      obj.radius = obj.meanRadius * (1+obj.radiusSpread*randn(3,1));
      obj.rimAngle = obj.meanRimAngle * (1+obj.rimAngleSpread*(2-1*rand(1)));
      
      obj.topView.radius = obj.radius;
      obj.sideView.radius = obj.radius;
      
      obj.topView.rimAngle = obj.rimAngle;
      obj.sideView.rimAngle = obj.rimAngle;
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function setDefaultEyeLocation(obj)
      
      obj.topView.centre = obj.topViewDefaultCentre;
      obj.sideView.centre = obj.sideViewDefaultCentre;
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function makeInjection(obj)
      
      % Randomize injection centre
      theta = rand(1) * (pi - obj.rimAngle) + obj.rimAngle;
      phi = 2*pi*rand(1);
        
      obj.injectionCentre = [theta, phi];
      
      obj.injectionCentreXYZ = ...
          [obj.radius(1) .* sin(theta) .* cos(phi); ...
           obj.radius(2) .* sin(theta) .* sin(phi); ...
           obj.radius(3) * cos(theta)];
    
      
      thetaInj = theta + obj.injectionSpread*randn(1,obj.injectionN);
      phiInj = phi + obj.injectionSpread*randn(1,obj.injectionN);
      
      obj.injectionPointsXYZ = ...
          [obj.radius(1) .* sin(thetaInj) .* cos(phiInj); ...
           obj.radius(2) .* sin(thetaInj) .* sin(phiInj); ...
           obj.radius(3) * cos(thetaInj)];
        
      % Remove all points above rim
      
      zRim = cos(obj.rimAngle)*obj.radius(3);
      idx = find(obj.injectionPointsXYZ(3,:) > zRim);
        
      obj.injectionPointsXYZ(:,idx) = [];
      
      % Save the real NT and alpha 
      [fNT,fDV] = obj.topView.dualWedgeCoordinates(obj.injectionCentreXYZ);
      
      obj.injNT = fNT;
      obj.injDV = fDV;
      
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function plotInjection(obj)
      
      if(~isempty(obj.injectionHandle))
        delete(obj.injectionHandle);
        obj.injectionHandle = [];
      end
      
      [xTop,yTop,zTop] = obj.topView.transXYZ(obj.injectionPointsXYZ(1,:), ...
                                              obj.injectionPointsXYZ(2,:), ...
                                              obj.injectionPointsXYZ(3,:));

      [xSide,ySide,zSide] = obj.sideView.transXYZ(obj.injectionPointsXYZ(1,:), ...
                                                  obj.injectionPointsXYZ(2,:), ...
                                                  obj.injectionPointsXYZ(3,:));
      
      pT = plot3(xTop,yTop,zTop,'.','color',[0.9 0.2 0.2]);
      pS = plot3(xSide,ySide,zSide,'.','color',[0.9 0.2 0.2]);      
      
      
      obj.injectionHandle = [pT pS];
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function plotRealInjectionCentre(obj,markObjTop,markObjSide)
      
      [xTop,yTop,zTop] = obj.topView.transXYZ(obj.injectionCentreXYZ(1,:), ...
                                              obj.injectionCentreXYZ(2,:), ...
                                              obj.injectionCentreXYZ(3,:));

      [xSide,ySide,zSide] = obj.sideView.transXYZ(obj.injectionCentreXYZ(1,:), ...
                                                  obj.injectionCentreXYZ(2,:), ...
                                                  obj.injectionCentreXYZ(3,:));
      
      pT = plot3(xTop,yTop,zTop,'y.','markersize',30);
      pS = plot3(xSide,ySide,zSide,'y.','markersize',30);

      obj.injectionHandle(end+1) = pT;
      obj.injectionHandle(end+1) = pS;      
      
      
      % Draw a line between real injection and user injection marking
      vTop = markObjTop.trans(markObjTop.injection) + markObjTop.centre;
      vSide = markObjSide.trans(markObjSide.injection) + markObjSide.centre;
      
      pLT = plot3([xTop vTop(1)],[yTop vTop(2)],[zTop vTop(3)],'y-');
      pLS = plot3([xSide vSide(1)],[ySide vSide(2)],[zSide vSide(3)],'y-');      
      
      obj.injectionHandle(end+1) = pLT;
      obj.injectionHandle(end+1) = pLS;      

    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Mark obj is an EyeSphere which has been marked
    
    function verifyUser(obj,markObjTop,markObjSide)      
     
      if(size(markObjTop.injection,2) ~= 1)
        disp('You need to make an injection both in top and side view')
        return
      end

      % Mark the correct position to show user how much they missed  
      obj.plotRealInjectionCentre(markObjTop,markObjSide);

      userRadius = markObjTop.radius;
      userNT = markObjTop.injNT;
      userDV = markObjTop.injDV;
      
      realRadius = obj.topView.radius;
      realNT = obj.injNT;
      realDV = obj.injDV;
      
      radiusDeviation = mean((userRadius - realRadius)./realRadius * 100);
      
      userRim = markObjTop.rimAngle;
      realRim = obj.rimAngle;
      rimDeviation = (userRim - realRim) / realRim * 100;
      
      fprintf('Radius: rx = %.1f (real %.1f), ry = %.1f (real %.1f), rz = %.1f (real %.1f)\n',...
              userRadius(1),realRadius(1), ...
              userRadius(2),realRadius(2), ...
              userRadius(3),realRadius(3));
      fprintf('Radius deviation: %.2f %%\n', ...
              radiusDeviation)
      
      fprintf('Rim: %.1f (real %.1f)\n', userRim*180/pi, realRim*180/pi)
      
      fprintf('NT: %.2f (real %.2f)   DV: %.2f (real %.2f)\n', ...
              userNT, realNT, userDV, realDV)
      
      obj.NTdeviation = userNT - realNT;
      obj.DVdeviation = userDV - realDV;
      
      fprintf('NT deviation: %.2f, DV deviation %.2f\n', ...
              obj.NTdeviation,obj.DVdeviation)
       
      
      obj.score = max(40 - abs(obj.NTdeviation),0) ...
                + max(40 - abs(obj.DVdeviation),0) ...
                + max(15 - abs(radiusDeviation),0) ...
                + max(5 - abs(rimDeviation),0);
      
      fprintf('Your score is : %f\n', obj.score)
      
      obj.addScore(markObjTop);
      obj.saveOldScores();
      obj.plotScore();
      
      obj.finishTime = now();
      
    end
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function loadOldScores(obj)
      
      scoreName = 'SAVE/trainingScores.mat';
      
      if(exist(scoreName))
        data = load(scoreName);
        obj.oldScores = data.oldScores;
      else
        fprintf('Unable to load scores, file %s does not exist\n', scoreName)
      end
      
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function saveOldScores(obj)
      
      if(~exist('SAVE'))
        disp('Creating SAVE directory')
        mkdir('SAVE')
      end
      
      scoreName = 'SAVE/trainingScores.mat';
      fprintf('Saving scores to %s\n', scoreName)
      
      oldScores = obj.oldScores;
      save(scoreName,'oldScores');
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function addScore(obj,markObjTop)
      
      if(isempty(obj.oldScores))
        obj.oldScores.ID = obj.ID;
        obj.oldScores.score = obj.score;
        
        obj.oldScores.NTdeviation = obj.NTdeviation;
        obj.oldScores.DVdeviation = obj.DVdeviation;
        
        obj.oldScores.realNT = obj.injNT;
        obj.oldScores.realDV = obj.injDV;
        
        obj.oldScores.guessedNT = markObjTop.injNT;
        obj.oldScores.guessedDV = markObjTop.injDV;
        
        obj.oldScores.realRim = obj.rimAngle;
        obj.oldScores.guessedRim = markObjTop.rimAngle;
        
        obj.oldScores.realRadius =  obj.topView.radius;
        obj.oldScores.guessedRadius = markObjTop.radius;
        
        obj.oldScores.duration = obj.finishTime - obj.createTime;
        
      else
        allID = cat(1,obj.oldScores.ID);
        
        idx = find(obj.ID == allID);
        
        if(~isempty(idx))
          disp('Overwriting old score')
          assert(obj.oldScores(idx).ID == obj.ID);
          
          obj.oldScores(idx).score = obj.score;
          
          obj.oldScores(idx).NTdeviation = obj.NTdeviation;
          obj.oldScores(idx).DVdeviation = obj.DVdeviation;
          
          obj.oldScores(idx).realNT = obj.injNT;
          obj.oldScores(idx).realDV = obj.injDV;
          
          obj.oldScores(idx).guessedNT = markObjTop.injNT;
          obj.oldScores(idx).guessedDV = markObjTop.injDV;
          
          obj.oldScores(idx).realRim = obj.rimAngle;
          obj.oldScores(idx).guessedRim = markObjTop.rimAngle;
          
          obj.oldScores(idx).realRadius = obj.topView.radius;
          obj.oldScores(idx).guessedRadius = markObjTop.radius;
          
          obj.oldScores(idx).duration = obj.finishTime - obj.createTime;
          
        else
          nextIdx = numel(obj.oldScores)+1;
          
          obj.oldScores(nextIdx).ID = obj.ID;
          obj.oldScores(nextIdx).score = obj.score;          

          obj.oldScores(nextIdx).NTdeviation = obj.NTdeviation;
          obj.oldScores(nextIdx).DVdeviation = obj.DVdeviation;          
        
          obj.oldScores(nextIdx).realNT = obj.injNT;
          obj.oldScores(nextIdx).realDV = obj.injDV;
          
          obj.oldScores(nextIdx).guessedNT = markObjTop.injNT;
          obj.oldScores(nextIdx).guessedDV = markObjTop.injDV;
          
          obj.oldScores(nextIdx).realRim = obj.rimAngle;
          obj.oldScores(nextIdx).guessedRim = markObjTop.rimAngle;
          
          obj.oldScores(nextIdx).realRadius = obj.topView.radius;
          obj.oldScores(nextIdx).guessedRadius = markObjTop.radius;
          
          obj.oldScores(nextIdx).duration = obj.finishTime - obj.createTime;          
          
        end
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function plotScore(obj)
    
      ID = cat(1,obj.oldScores.ID);
      scores = cat(1,obj.oldScores.score);
      
      fig = gcf;
      figure(2)
      plot(1:numel(scores),scores,'k.')
      ylabel('Score')
      xlabel('Attempt number')
      
      figure(fig)
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
  end
  
  
  
end

