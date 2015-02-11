classdef ImageExtract < handle

  properties
    
    retinalSphere = [];
    
    injectionCenterXY = [];
    threshold = 5; % Let this be set by slider

    injectionAreaXY = [];
    injectionAreaXYZ = [];
    
    plotHandle = [];
    
    lastSphere = [];
    
    plotInjection = false;
    
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function obj = ImageExtract(retinalSphere)
      
      obj.retinalSphere = retinalSphere;
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % This function gives the user a reasonable range of thresholds
    % to choose from based on the image statistics. Wont allow the
    % user to select more than 10% of the pixels.
    
    function maxThreshold = getMaxThreshold(obj,xA,yA)
      
      col_img = obj.LABimage();
      
      maxThreshold = 0;
      
      for i = 1:numel(xA)
        [colDist,minColDist] = obj.calcColourDist(xA(i),yA(i),col_img);

        % All the distances in colour space
        s = sort(colDist(:),'ascend');
      
        topIdx = floor(numel(s)*0.1);

        maxThreshold = max(maxThreshold,s(topIdx));
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function markInjection(obj,sphere)
            
      % Use injection point already marked in sphere
      v = sphere.trans(sphere.injection) + sphere.centre;
      
      obj.findInjectionExtent(round(v(1)),round(v(2)),obj.threshold);
      obj.getInjectionOnSphere();
      % obj.plotInjection3D(sphere);
      
      obj.retinalSphere.showSpheres();
      
      obj.lastSphere = sphere;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function col_img = LABimage(obj)

      % Use the L*a*b colour space
      cform = makecform('srgb2lab');
      lab_img = applycform(obj.retinalSphere.image,cform);
      col_img = double(lab_img(:,:,2:3));
      
    end
    
    function [colDist,minColDist] = calcColourDist(obj,xA,yA,col_img)

      colDist = inf*ones(size(col_img));
      minColDist = inf;

      % Calculate colour distance and minimum distance in colour space for
      for i = 1:numel(xA)
        
        colDist = sqrt((col_img(:,:,1) - col_img(yA(i),xA(i),1)).^2 ...
                 + (col_img(:,:,2) - col_img(yA(i),xA(i),2)).^2);
        
        minColDist = min(colDist,minColDist);
        
        % d = sqrt((X - xA(i)).^2 + (Y - yA(i)).^2);
        % minDist = min(minDist,d);
        
      end
      
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function looks at the points indicated by xA,yA and looks
    % for pixels with similar colour in a connected neighbourhood 
    
    function injPoints = findInjectionExtent(obj,xA,yA,threshold)

      obj.injectionCenterXY = [xA,yA];
      
      if(exist('threshold') ~= 1)
        threshold = 5;
      end
      
      col_img = obj.LABimage();
      
      nr = size(col_img,1);
      nc = size(col_img,2);
      
      % minDist = inf*ones(nr,nc);
      % [X,Y] = meshgrid(1:nc,1:nr);
      [colDist,minColDist] = obj.calcColourDist(xA,yA,col_img);
      
      % Threshold image
      thr_img = minColDist < threshold;
      cc = bwconncomp(thr_img,8);

      injCtrIdx = sub2ind([nr nc],yA,xA);
      
      injPoints = [];
      injPointsIdx = [];
      
      for i = 1:numel(cc.PixelIdxList)
        if(ismember(injCtrIdx,cc.PixelIdxList{i}))
          injPointsIdx = [injPointsIdx; cc.PixelIdxList{i}];
        end
      end
      
      [yi,xi] = ind2sub([nr nc],injPointsIdx);
      injPoints = [xi,yi];
      
      obj.injectionAreaXY = injPoints;
      
      % !!!! FIXME!!! 
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function clearPlot(obj)
      if(~isempty(obj.plotHandle))
        try
          delete(obj.plotHandle);
        catch
          % Ignore errors
        end
        
        obj.plotHandle = [];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function plotInjectionArea(obj)
  
      obj.clearPlot();
      obj.plotHandle = plot(obj.injectionAreaXY(:,2),obj.injectionAreaXY(:,1),'r.');
    
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function plotInjection3D(obj,sphere)
    
      obj.clearPlot();
      
      v = sphere.trans(transpose(obj.injectionAreaXYZ));
      v = v + kron(sphere.centre,ones(1,size(obj.injectionAreaXYZ,1)));
      obj.plotHandle = plot3(v(1,:),v(2,:),v(3,:),'r.');
      
      % Display
      % v(:,1:5)
      % disp('Somehow XY are MESSED UP I THINK...')
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function [xInj,yInj,zInj] = getInjectionOnSphere(obj)

      try       
      xc = obj.injectionCenterXY(1);
      yc = obj.injectionCenterXY(2);
      
      % All 2D points in image corresponding to injection

      xp = obj.injectionAreaXY(:,1);
      yp = obj.injectionAreaXY(:,2);
      catch e
        getReport(e)
        keyboard
      end

      
      % Find which sphere the points belong to
      sphere = obj.retinalSphere.topView.getClosestSphere(xc,yc,inf);

      % Transform the coordinates into the spheres coordinates
      
      % 1. Express all possible points, on the line out of the plane
      nPoints = 100;
      
      try
        xs = xp - sphere.centre(1);
        ys = yp - sphere.centre(2);
      catch e
        getReport(e)
        keyboard
      end
        
      % keyboard
      
      % There are two possible solutions, take the one closest to
      % the injection center
      v = sphere.trans(sphere.injection) + sphere.centre;
      
      if(v(3,1) > 0)
        zss = max(sphere.radius)*linspace(0,1,nPoints);
      else
        zss = -max(sphere.radius)*linspace(0,1,nPoints);
      end
      
      xInj = []; yInj = []; zInj = [];
      
      if(numel(xs) > 1e4)
        fprintf(['%d candidate pixels, exceptionally large. This ' ...
                 'will take time'], numel(xs))
      end
      
      % Find out which of the points are closest to the ellipsoid surface
      for i = 1:numel(xs)
        if(mod(i,1e3) == 0)
          fprintf('%d/%d pixels processed\n', i, numel(xs))
        end
        
        candidatePoints = sphere.invTrans([kron([xs(i);ys(i)],ones(size(zss))); zss]);
          
        
        % Find out which of those two points are closest to the 
        xCand = candidatePoints(1,:)/sphere.radius(1);
        yCand = candidatePoints(2,:)/sphere.radius(2);
        zCand = candidatePoints(3,:)/sphere.radius(3);
      
        % Which of the points are closest to the ellipsoid surface
        [minVal,minIdx] = min(abs(xCand.^2 + yCand.^2 + zCand.^2 - 1));

        xInj(i) = candidatePoints(1,minIdx);
        yInj(i) = candidatePoints(2,minIdx);
        zInj(i) = candidatePoints(3,minIdx);        
      end
      
      try
        obj.injectionAreaXYZ = transpose([xInj;yInj;zInj]);  
      catch e
        getReport(e)
        keyboard
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function attempts to estimate the area of the injection site
    
    function areaFraction = estimateInjectionSize(obj)
    
      if(isempty(obj.lastSphere))
        areaFraction = NaN;
        return
      end
      
      % First lets approximate the area of the eye-ball
      r = obj.lastSphere.radius;
      
      [eX,eY,eZ] = ellipsoid(0,0,0,r(1),r(2),r(3),100);

      % We need to cut away the top, to get the eye-dome
      zRim = cos(obj.lastSphere.rimAngle)*r(3);
      idx = find(eZ(:,1) > zRim);
      eX(idx,:) = []; eY(idx,:) = []; eZ(idx,:) = [];
      
      % http://math.stackexchange.com/questions/128991/how-to-calculate-area-of-3d-triangle
      % Area is cross(B-A,C-A)/2, but we have to sets of triangles, so...
      eXA = eX(1:end-1,1:end-1);
      eYA = eY(1:end-1,1:end-1);
      eZA = eZ(1:end-1,1:end-1);
      
      A = [eXA(:),eYA(:),eZA(:)];

      eXB = eX(2:end,1:end-1);
      eYB = eY(2:end,1:end-1);
      eZB = eZ(2:end,1:end-1);
      
      B = [eXB(:),eYB(:),eZB(:)];
      
      eXC = eX(1:end-1,2:end);
      eYC = eY(1:end-1,2:end);
      eZC = eZ(1:end-1,2:end);
      
      C = [eXC(:),eYC(:),eZC(:)];
      
      eXD = eX(2:end,2:end);
      eYD = eY(2:end,2:end);
      eZD = eZ(2:end,2:end);
      
      D = [eXD(:),eYD(:),eZD(:)];
      
      eyeArea = sum(sqrt(sum(cross(B-A,C-A).^2,2)) + sqrt(sum(cross(B-D,C-D).^2,2)))/2;
      
      % Lets verify calculation using alpha shape
      % !!! It lets me calculate the entire sphere, which matches,
      % but when top is taken off it failes.
      % eyeAS = alphaShape(eX(:),eY(:),eZ(:),mean(obj.lastSphere.radius)/2);
      % eyeAreaVer = eyeAS.surfaceArea();
      
      % Next we calculate injection area
      
      as = alphaShape(obj.injectionAreaXYZ,5);
      
      injectionArea = as.surfaceArea();
      areaFraction = injectionArea / eyeArea;
      
      % Plot the injection
      if(obj.plotInjection)
      
        set(obj.retinalSphere.fig,'currentaxes',obj.retinalSphere.handlePolarAxis)
        cla
        s = surf(eX,eY,eZ);
        set(s,'facealpha',0.4,'edgealpha',0)
        hold on
        as.plot()
        title(sprintf('Injection size: %.2f %%', areaFraction*100))
        
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
  end
    
end