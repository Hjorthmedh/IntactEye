classdef EyeSphere < handle
  
  properties
  
    % Sphere assumption approximation but well tested, set to true
    useSphere = true;

    % New version, use mouse + right click to rotate
    useAngles = false;
    
    fig = [];
    ax = [];
    parent = [];
    
    visibleFlag = true;
    detailedFlag = true;
    
    % These place a sphere so that nasal point is parallell to X-axis
    centre = [0; 0; 0];
    radius = [100; 100; 100];

    % This is the rotational transformation needed to align with
    % the image shown
    rotAngle = 0;
    
    angle = [0 0 0]; % deprecated
    prevAngle = []; % deprecated
    defaultAngle = [0 0 0]; % deprecated
    rimAngle = pi*50/180;
    
    % Alternative way to represent view transform, to replace old
    % GUI using angles
    viewTransform = [1 0 0; 0 1 0; 0 0 1];
    originalViewTransform = [];
    previousViewTransform = [];
    
    % !!! Need to add control for rotationTransform, transform
    % should be trans = viewTransform * rotationTransform
    
    viewType = [];
    
    % Graphical handle for ellipse
    handleEllipsoid = [];
    handleX = [];
    handleY = [];
    handleZ = [];
    handleCentre = [];
    handleRim = [];
    handleInjection = [];
    handlePutativeInjection = [];
    handleInjectionRegion = [];
    
    oldActionListener = [];
    
    handleAxisDir = []; % Direction of the currently updated axis
    oldRadius = [];
    
    % These objects need to be updates together with this EyeSphere
    linkedObj = [];
    
    injection = [];
    oldInjection = [];
    
    injNT = [];
    injDV = [];
    side = '';
    
    injectionRegion = [];
    mouseRotationSpeedScaling = 1/(2*pi*10) *0.5; % Lets slow it
                                                  % down by 0.5
    
    % Matlab2014b now has correct clipping, which means we do no
    % longer see the axis if it is behind image plane. Shift the
    % wire-frame up above the image using zShift
    zShift = 2000;
    
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  properties (SetAccess = private)
  
    trackMouseStartX = [];
    trackMouseStartY = [];
    
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  methods

%    % Minimal construct, please use the other one for normal usage
%    function obj = EyeSphere()
%      
%    end
    
    function obj = EyeSphere(type,side,centre,fig,ax)
      
      if(~exist('type') | isempty(type))
        type = 'top';
      end
      
      if(~exist('side') | isempty(side))
        side = 'left';
      end
      obj.side = side;

      if(~exist('centre') | isempty(centre))
        centre = [0; 0; 0];
      end
      
      if(exist('fig'))
        obj.fig = fig;
      end
      
      % Figure axis
      if(exist('ax'))
        obj.ax = ax;
      else
        disp('No axis specified.')
      end
      
      type = lower(type);
      
      
      obj.centre = centre;
        
      switch(type)
        case 'top'
          obj.viewType = 'top';
          obj.angle = [0 0 0];
        case 'side'
          obj.viewType = 'side';
          obj.angle = [-pi/2 0 0];
        otherwise
          fprintf('Unknown type: %s', type)
      end
      
      % Sets the view transform, based on angle
      obj.setViewTransform(obj.angle);
      
      obj.originalViewTransform = obj.viewTransform;
      
      obj.defaultAngle = obj.angle;
      obj.prevAngle = [];
      
      % This is not called by the external function
      % obj.captureActionListener();
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function reset(obj)
      
      obj.angle = [0 0 0];
      obj.prevAngle = [];
      
      
      switch(obj.viewType)
        case 'top'
          obj.defaultAngle = [0 0 0];          
        case 'side'
          obj.defaultAngle = [-pi/2 0 0];          
        otherwise
          obj.defaultAngle = [0 0 0];
      end
      
      obj.angle = obj.defaultAngle;
      obj.setViewTransform(obj.angle);
      obj.originalViewTransform = obj.viewTransform;

      obj.centre = [0; 0; 0];
      obj.radius = [1;1;1] * 300;
      
      obj.injection = [];
      obj.oldInjection = [];
      obj.injectionRegion = [];
      obj.injNT = [];
      obj.injDV = [];
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function setParent(obj,parent)
      obj.parent = parent;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function captureActionListener(obj)
      
      % Now we got to be a bit clever...
      disp('Action listener called')
  
      f = get(obj.fig, 'WindowButtonDownFcn');
      if(isempty(f))
        % Great, we are first, steal the slot!
        set(obj.fig,'WindowButtonDownFcn',@obj.setupMouseButtonListener);

      else
        % Someone else was before us, find out who
        disp('Windowlistener captured, playing nicely...')
        
        bossObj = f();
        
        if(obj == bossObj)
          % Oh, we already own it, all done...
          return
        end
        
        % Attaching to bossObj
        if(~ismember(obj,bossObj.linkedObj))
          if(isempty(bossObj.linkedObj))
            bossObj.linkedObj = obj;
          else
            bossObj.linkedObj(end+1) = obj;
          end
        else
          disp('Already in the linked object list')
        end
        
        % Attaching bossObj
        if(~ismember(bossObj,obj.linkedObj))
          if(isempty(obj.linkedObj))
            obj.linkedObj = bossObj;
          else
            obj.linkedObj(end+1) = bossObj;
          end
        else
          disp('Already aware of primary object.')
        end
        
      end
      
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function deleteHandles(obj)

      try
        if(~isempty(obj.handleEllipsoid))
          delete(obj.handleEllipsoid); obj.handleEllipsoid = [];
          delete(obj.handleCentre); obj.handleCentre = [];
          delete(obj.handleX); obj.handleX = [];
          delete(obj.handleY); obj.handleY = [];
          delete(obj.handleZ); obj.handleZ = [];
          delete(obj.handleRim); obj.handleRim = [];
          
          if(~isempty(obj.handleInjection))
            delete(obj.handleInjection); 
            obj.handleInjection = [];
          end
          
          if(~isempty(obj.handlePutativeInjection))
            delete(obj.handlePutativeInjection);
            obj.handlePutativeInjection = [];
          end
          
          if(~isempty(obj.handleInjectionRegion))
            delete(obj.handleInjectionRegion)
            obj.handleInjectionRegion = [];
          end
          
        end
      catch e
        getReport(e)
        keyboard
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function [closestObj,closestType] = getClosestSphere(obj,xp,yp,maxDist)
      
      disp('getClosestSphere called')
      
      allObj = [obj, obj.linkedObj];
      
      closestObj = [];
      closestType = [];
      closestDist = inf;
      
      if(~exist('xp') | ~exist('yp') | isempty(xp) | isempty(yp))
        [xp,yp] = obj.getCurrentPoint();
      end
     
      if(~exist('maxDist') | isempty(maxDist))
        maxDist = [60 50 50 50];
      end
      
      handleType = {'centre','x','y','z'};
      
      for i = 1:numel(allObj)
        o = allObj(i);
        
        for j = 1:numel(handleType)
          
          d = o.getDistance(handleType{j},xp,yp);
          
          try
            if(d < closestDist & d < maxDist(j))
              % Ignore anything further away than maxDist
              closestObj = o;
              closestType = handleType{j};
              closestDist = d;
            end
          catch e
            getReport(e)
            keyboard
          end
        end       
      end
     end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function clearInjectionMarks(obj)
      try
        if(~isempty(obj.handleInjection))
          delete(obj.handleInjection); 
          obj.handleInjection = [];
        end
          
        if(~isempty(obj.handlePutativeInjection))
          delete(obj.handlePutativeInjection);
          obj.handlePutativeInjection = [];
        end
        
        if(~isempty(obj.handleInjectionRegion))
            delete(obj.handleInjectionRegion)
            obj.handleInjectionRegion = [];
        end
          
      catch e
        getReport(e)
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function plotSphere(obj)
      
      if(isempty(obj.fig))
        obj.fig = gcf;
        obj.ax = gca;
      else
        try
          set(obj.fig,'currentaxes',obj.ax);
        catch e
          getReport(e)
          keyboard
        end
      end
      
      obj.deleteHandles();
      
      if(~obj.visibleFlag)
        % Not visible, don't plot
        return
      end
      
      if(obj.detailedFlag)
        nSize = 100;
      else
        nSize = 20;
      end
      
      [eX,eY,eZ] = ellipsoid(0,0,0,obj.radius(1),obj.radius(2),obj.radius(3),nSize);

      if(obj.detailedFlag)
        % We want to cut off the top bit that goes beyond the rim
        zRim = cos(obj.rimAngle)*obj.radius(3);
        idx = find(eZ(:,1) > zRim);
        
        eX(idx,:) = [];
        eY(idx,:) = [];
        eZ(idx,:) = [];
        
      end
      
      % Transform the ellipse so it aligns with figure
      [eX,eY,eZ] = obj.transXYZ(eX,eY,eZ);

      hold on
      obj.handleEllipsoid = surf(eX,eY,eZ+obj.zShift);
      set(obj.handleEllipsoid,'facealpha',0.2,'edgealpha',0.2)
      hold on
      
      obj.handleCentre = obj.plotCentre();
      
      try
        switch(lower(obj.side))
          case 'left'
            yMark = 'V';
          case 'right'
            yMark = 'D';
          otherwise
            yMark = '';
        end
      catch e
        getReport(e)
        keyboard
      end
        
      obj.handleX = obj.plotAxLine(obj.trans(obj.radius(1)*[1; 0; 0]),[1 0 0],'N');
      obj.handleY = obj.plotAxLine(obj.trans(obj.radius(2)*[0; 1; 0]),[0 1 0],yMark);
      obj.handleZ = obj.plotAxLine(obj.trans(obj.radius(3)*[0; 0; 1]),[0 0 1],[]);      
      
      obj.handleRim = obj.plotRim();
      
      obj.handleInjection = obj.plotInjection();
      obj.handleInjectionRegion = obj.plotInjectionRegion();
      
      obj.updateNT();      
      
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function updateNT(obj)

      if(size(obj.injection,2) == 1)
        % Write out NT coordinates
      
        [fNT,fDV] = obj.dualWedgeCoordinates(obj.injection);
        
        obj.injNT = fNT;
        obj.injDV = fDV;
        
        for i = 1:numel(obj.linkedObj)
          obj.linkedObj(i).injNT = obj.injNT;
          obj.linkedObj(i).injDV = obj.injDV;
        end
        
        obj.parent.printInjectionLocation(fNT,fDV);
        
        str = sprintf('%s: NT = %.2f, DV = %.2f', ...
                      obj.parent.getExpName(), ...
                      fNT, fDV);
        set(obj.fig,'name',str)

        obj.parent.plotFlatRepresentation(obj.injection);
       
      else
        try
          if(~isempty(obj.parent))
            set(obj.fig,'name',obj.parent.getExpName())
          else
            % Do nothing
          end

          if(~isempty(obj.parent))
            obj.parent.plotFlatRepresentation([]);
          end
        
        catch e
          getReport(e)
          keyboard
        end
        
        obj.injNT = [];
        obj.injDV = [];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function sideObj = getView(obj,type)
      
      if(strcmpi(obj.viewType,type))
        sideObj = obj;
        return
      else
        for i = 1:numel(obj.linkedObj)
          if(strcmpi(obj.linkedObj(i).viewType,type))
            sideObj = obj.linkedObj(i);
            return
          end
        end
          
        % If we get here we are in trouble, no side view available
        fprintf('getView: Internal error, didnt find a %s view object\n',type)
        keyboard
        
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function h = plotInjection(obj, injection)
      
      if(exist('injection') ~= 1)
        injection = obj.injection;
      end
      
      switch(size(injection,2))
        case 0
          % Dont do anything, just return
          h = [];
        case 1
          % Plot point
          v = obj.trans(injection) + obj.centre;
          h(1) = plot3(v(1),v(2),v(3)+obj.zShift,'.','color',[1 1 1]*0.99,'markersize',20);
                    
        otherwise
          % Plot line
          v = obj.trans(injection) + repmat(obj.centre,1,size(injection,2));

          if(mean(v(3,:)) > 0)
            h(1) = plot3(v(1,:),v(2,:),v(3,:)+obj.zShift,'w-','linewidth',3);
          else
            % This indicates that the line is on the backside of
            % the retina
            h(1) = plot3(v(1,:),v(2,:),v(3,:)+obj.zShift,'w--','linewidth',3);
          end
          
          h(2) = plot3(v(1,:),v(2,:),v(3,:)+obj.zShift,'w.','markersize',20);
                 
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function h = plotInjectionRegion(obj)
      
      if(isempty(obj.injectionRegion))
        % No injection region specified, nothing to plot
        h = [];
        return
      end
      
      v = obj.trans(transpose(obj.injectionRegion));
      v = v + kron(obj.centre,ones(1,size(obj.injectionRegion,1)));
      h = plot3(v(1,:),v(2,:),v(3,:)+obj.zShift,'r.');
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function h = plotCentre(obj)
      
      h = plot3(obj.centre(1),obj.centre(2),obj.centre(3)+obj.zShift, ...
                'y','markersize',20);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function h = plotRim(obj)
      
      fi = linspace(0,2*pi,20);
      
      x = obj.radius(1) * sin(obj.rimAngle) * cos(fi);
      y = obj.radius(2) * sin(obj.rimAngle) * sin(fi);
      z = obj.radius(3) * cos(obj.rimAngle) * ones(size(fi));
      
      [x,y,z] = obj.transXYZ(x,y,z);
      
      h = plot3(x,y,z+obj.zShift,'y-');
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function h = plotAxLine(obj,vector,colour,axisText)
      
      if(~exist('axisText'))
        axisText = [];
      end
      
      vTrans = obj.centre + vector;
      
      if(vTrans(3) < 0)
        lineStyle = '--';
      else
        lineStyle = '-';
      end
      
      h(2) = plot3([obj.centre(1) vTrans(1)], ...
                   [obj.centre(2) vTrans(2)], ...
                   [obj.centre(3) vTrans(3)]+obj.zShift, ...
                   'linestyle', lineStyle, ...
                   'color',colour);
      
      h(1) = plot3(vTrans(1),vTrans(2),vTrans(3)+obj.zShift, ...
                  '.','color',colour);
      
      if(~isempty(axisText))
        h(3) = text(vTrans(1),vTrans(2),vTrans(3)+obj.zShift,axisText, ...
                    'fontsize',20,'color',colour);
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function R = rotX(obj,angle)
      R = [1, 0, 0; 0, cos(angle), -sin(angle); 0, sin(angle), cos(angle)];
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function R = rotY(obj,angle)
      R = [cos(angle), 0, sin(angle); 0, 1, 0; -sin(angle), 0, cos(angle)];
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function R = rotZ(obj,angle)
      R = [cos(angle), -sin(angle), 0; sin(angle), cos(angle), 0; 0, 0, 1];
    end
  
    function R = rotAng(obj,angle)
      R = obj.rotZ(angle);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function vTrans = trans(obj,v)
    
      if(isempty(v))
        vTrans = [];
        return
      end
      
      if(obj.useAngles)
        try
          vTrans = obj.rotX(obj.angle(1)) ...
                   * obj.rotY(obj.angle(2)) ...
                   * obj.rotZ(obj.angle(3)) * v;
        catch e
          getReport(e)
          keyboard
        end
      else
        try
          vTrans = obj.viewTransform * obj.rotAng(obj.rotAngle) * v;
        catch e
          getReport(e)
          keyboard
        end
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function vTrans = invTrans(obj,v)

      if(isempty(v))
        vTrans = [];
        return
      end      
      
      if(obj.useAngles)
        try
          vTrans = obj.rotZ(-obj.angle(3)) ...
                   * obj.rotY(-obj.angle(2)) ...
                   * obj.rotX(-obj.angle(1)) ...
                   * v;
        catch e
          getReport(e)
          keyboard
        end
      else
        vTrans = inv(obj.viewTransform*obj.rotAng(obj.rotAngle)) * v;
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function [vTransX,vTransY,vTransZ] = transXYZ(obj,x,y,z)
    
      snr = size(x,1);
      snc = size(x,2);
      sn = numel(x);
      
      V = [reshape(x,1,sn);reshape(y,1,sn);reshape(z,1,sn)];
      
      VT = obj.trans(V);
      
      vTransX = reshape(VT(1,:),snr,snc) + obj.centre(1);
      vTransY = reshape(VT(2,:),snr,snc) + obj.centre(2);
      vTransZ = reshape(VT(3,:),snr,snc) + obj.centre(3);      
      
    end
      
      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function obj = setupMouseButtonListener(obj,source,event)
      
      if(~exist('source') | isempty(source))
        return
      end
            
      % If the sphere is not displayed, then do not do this
      if(isempty(obj.handleX))
        return
      end

      [cx,cy] = obj.getCurrentPoint();
      fprintf('Pressed down: %f,%f\n', cx,cy)
      
      % Make sure we are within image
      a = axis();
      if(cx < a(1) | a(2) < cx | cy < a(3) | a(4) < cy)
        disp('Outside of image, ignoring click')
        return
      end
      
      disp('Okay lets parse the click')
      
      buttonType = get(gcbf,'selectionType');
      % buttonType
      
      switch(buttonType)
        case 'normal' 
          fprintf('%s: Left click\n',datestr(now()))
          % Determine which point is closest
          [closestObj,closestType] = obj.getClosestSphere();
          % closestObj,closestType
      
          if(isempty(closestObj))
            % Nothing close enough
            return
          end
          
          % Left click
          set(obj.fig,'WindowButtonMotionFcn', ...
                      {@closestObj.captureResizeSphere,closestType}, ...
                      'interruptible','off')
          % set(obj.fig,'WindowButtonDownFcn',[]);
          set(obj.fig,'WindowButtonUpFcn', ...
                      {@closestObj.stopResizeSphereFcn,closestType}, ...
                      'interruptible','off');

        case 'alt'
          % Right click
          
          fprintf('%s: Right click\n',datestr(now()))
          
          
          closestObj = obj.withinSphere(cx,cy);

          if(isempty(closestObj))
            % disp('No closest object, ignoring.')
            return
          end
          
          % Save starting view
          closestObj.previousViewTransform = closestObj.viewTransform;
          
          if(isempty(closestObj))
            return
          end
          
          % We need to know original point, and original view transform

          [cx,cy] = closestObj.getCurrentPoint();
          fprintf('Setting trackMouseStartX/Y to %d,%d\n', cx,cy)
          closestObj.trackMouseStartX = cx;
          closestObj.trackMouseStartY = cy;

          set(obj.fig,'WindowButtonMotionFcn', ...
                      {@closestObj.captureRotationMovement}, ...
                      'interruptible','off')
          % set(obj.fig,'WindowButtonDownFcn',[]);
          set(obj.fig,'WindowButtonUpFcn', ...
                      {@closestObj.stopCaptureRotation}, ...
                      'interruptible','off');       
          
        otherwise
          fprintf('%s: Unknown selectionType: %s - Doing nothing.\n', ...
                  datestr(now()), buttonType)
      end
      
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
    function [cx,cy] = getCurrentPoint(obj)
      set(obj.fig,'currentaxes',obj.parent.handleAxis);

      C = get(obj.ax, 'CurrentPoint');
      cx = C(1,1); cy = C(1,2);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    function stopResizeSphereFcn(obj,source,event,handleType)
      % fprintf('Released: %s\n', handleType)
    
      [cx,cy] = obj.getCurrentPoint();
      
      obj.setRadius(handleType,cx,cy);
      obj.resetInjection();
      obj.plotAllSpheres();
      
      % Turn off the tracking
      set(obj.fig,'WindowButtonMotionFcn',[])
      set(obj.fig,'WindowButtonUpFcn',[])
      % set(obj.fig,'WindowButtonDownFcn',@obj.startMoveFcn);
      
      obj.handleAxisDir = [];
      obj.oldRadius = [];
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function captureResizeSphere(obj,source,event,handleType)

      [cx,cy] = obj.getCurrentPoint();
      
      obj.setRadius(handleType,cx,cy);
      obj.resetInjection();      
      obj.plotAllSpheres();
    
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Stop when mouse button is released
    
    function stopCaptureRotation(obj,source,event)

      % Turn off the tracking
      set(obj.fig,'WindowButtonMotionFcn',[])
      set(obj.fig,'WindowButtonUpFcn',[])
    
      obj.resetInjection();      
      obj.plotAllSpheres();
       
    end
      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function captureRotationMovement(obj,source,event)
      
      if(isempty(obj.trackMouseStartX) ...
         | isempty(obj.trackMouseStartY))
        disp('Start point not set for rotation')
        return
      end
      
      [cx,cy] = obj.getCurrentPoint();

      deltaX = cx - obj.trackMouseStartX;
      deltaY = cy - obj.trackMouseStartY;
      
      vx = -deltaY * obj.mouseRotationSpeedScaling;
      vy = deltaX * obj.mouseRotationSpeedScaling;

      try
        obj.viewTransform = obj.rotX(vx)*obj.rotY(vy)*obj.previousViewTransform;
        assert(~isempty(obj.viewTransform))
      catch e
        getReport(e)
        keyboard
      end
        
      obj.resetInjection();
      obj.plotAllSpheres();
      
      % Reset start points
      obj.trackMouseStartX = cx;
      obj.trackMouseStartY = cy;
      obj.previousViewTransform = obj.viewTransform;
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function plotAllSpheres(obj)
      
      set(obj.fig,'currentaxes',obj.parent.handleAxis);
      
      obj.plotSphere();
      
      for i = 1:numel(obj.linkedObj)
        obj.linkedObj(i).plotSphere();
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function hideSphere(obj,source,events,handle)
      
      obj.visibleFlag = ~obj.visibleFlag;
      
      if(obj.visibleFlag)
        set(handle,'string','hide')
      else
        set(handle,'string','show')
      end
      
      obj.plotSphere();
      
    end
    
  
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function d = getDistance(obj,handleType,x,y)
    
      switch(handleType)
        case 'x'
          handle = obj.handleX(1);
          rIdx = 1;
        case 'y'
          handle = obj.handleY(1);
          rIdx = 2;
        case 'z'
          handle = obj.handleZ(1);
          rIdx = 3;
        case 'centre'
          
          d = norm(obj.centre(1:2) - [x;y]);
          return
        otherwise
          fprintf('Unknown handleType: %s\n',handleType)
          keyboard
      end
      
      try
        vOld = transpose(cell2mat(get(handle,{'Xdata','Ydata'})));
      catch e
        getReport(e)
        keyboard
      end
        
      d = norm(vOld - [x;y]);
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function setRadius(obj,handleType,x,y)
      
      switch(handleType)
        case 'x'
          handle = obj.handleX(1);
          rIdx = 1;
        case 'y'
          handle = obj.handleY(1);
          rIdx = 2;
        case 'z'
          handle = obj.handleZ(1);
          rIdx = 3;
        case 'centre'
          obj.centre = [x;y;0];
          return
        otherwise 
          fprintf('Unknown handleType: %s\n', handleType)
          keyboard
      end
      
      % First find out how far along the axis the cursor is
      
      if(isempty(obj.handleAxisDir))
        vOld = transpose(cell2mat(get(handle,{'Xdata','Ydata','Zdata'})));
        obj.handleAxisDir = vOld;
        obj.oldRadius = obj.radius;
      else
        vOld = obj.handleAxisDir;
      end
      
      % Project the cursor along the axis, to find out how we
      % should rescale.
      vNew = [x;y;0];
      
      %reScale = abs(sum((vNew - obj.centre).*(vOld - obj.centre)) ...
      %              ./ sum((vOld-obj.centre).*(vOld-obj.centre)));
      
      % Only do projection in x-y plane
      centre = obj.centre;
      centre(3) = 0;
      vOld(3) = 0;
      
      reScale = abs(sum((vNew - centre).*(vOld - centre)) ...
                    ./ sum((vOld-centre).*(vOld-centre)));

      % keyboard
      
      if(isnan(reScale))
        disp('NAN!!')
        keyboard
      end
      
      obj.radius(rIdx) = obj.oldRadius(rIdx)*reScale;
      
      for i = 1:numel(obj.linkedObj)
        obj.linkedObj(i).radius(rIdx) = obj.radius(rIdx);
      end
      
      fprintf('Radius (x = %.1f, y = %.1f, z = %.1f)\n', obj.radius)
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function resetView(obj,source,event,callFunkAfter)
      
      obj.prevAngle(end+1,:) = obj.angle;
      obj.angle = obj.defaultAngle;
      
      obj.radius = [100; 100; 100];

      for i = 1:numel(obj.linkedObj)
        obj.linkedObj(i).radius = obj.radius;
        obj.linkedObj(i).plotSphere();
      end
      
      obj.plotSphere();

      if(exist('callFunkAfter') & ~isempty(callFunkAfter))
        callFunkAfter();
      end      
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function resetInjection(obj)
      
      obj.clearInjectionMarks();
      obj.injection = [];
      obj.injNT = [];
      obj.injDV = [];
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function undoRot(obj,source,event,callFunkAfter)
      
      if(~isempty(obj.prevAngle))
        obj.angle = obj.prevAngle(end,:);
        obj.prevAngle(end,:) = [];
      else
        disp('No more undo history.')
        return
      end
      
      obj.plotSphere();
      
      if(exist('callFunkAfter') & ~isempty(callFunkAfter))
        callFunkAfter();
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function rotate(obj,source,event,handle,callFunkAfter)
      
      v = get(handle,'value');
      obj.rotAngle = v;
      
      obj.plotSphere();
      
      if(exist('callFunkAfter') & ~isempty(callFunkAfter))
        callFunkAfter();
      end
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function markInjection(obj,source,events,type,parentObj)

      % Clear old area marking
      obj.injectionRegion = [];
      for i = 1:numel(obj.linkedObj)
        obj.linkedObj.injectionRegion = [];
      end
      
      switch(type)
        
        case 'top'

          % We are ok
          
        case 'side'
          
          if(isempty(obj.injection))
            disp('You need to mark injection from top first')
            return
          end
          
          if(size(obj.injection,2) == 1)
            obj.injection = obj.oldInjection;
            obj.plotAllSpheres()
          else
            obj.oldInjection = obj.injection;
          end
                    
        otherwise
          
          fprintf('markInjection: Unknown type: %s\n', type)
          return
      end
      
      % Prepare action listeners
      
      obj.oldActionListener = get(obj.fig,'WindowButtonDownFcn');

      try
        set(obj.fig,'WindowButtonMotionFcn',{@obj.updateInjectionSite,type})
        set(obj.fig,'WindowButtonDownFcn',{@obj.acceptInjectionSite,type,parentObj});
      catch e
        getReport(e)
        keyboard
      end
        % set(obj.fig,'WindowButtonUpFcn',{})
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This is a mouse movement action listener
    
    function updateInjectionSite(obj,source,event,type)
      
      % Where is the cursor?  
      [x,y] = obj.getCurrentPoint();
      
      if(obj.getDistance('centre',x,y) > 1.1*max(obj.radius))
        % We are not near the sphere with the cursor, dont show anything

        if(0) % Dont show text message anymore
          fprintf('(%d,%d) dist %.1f- Far from sphere, not showing point.\n',...
                  x,y,obj.getDistance('centre',x,y))
        end
        
        return
      end

      putativeInjection = obj.getInjectionLocation(x,y,type);
      
      % If anything was drawn before, clear it

      obj.clearInjectionMarks();
      
      % Show the line / point where it is currently      
      obj.handlePutativeInjection = obj.plotInjection(putativeInjection);
      
      for i = 1:numel(obj.linkedObj)
        lo = obj.linkedObj(i);
        lo.clearInjectionMarks();
        lo.handlePutativeInjection = lo.plotInjection(putativeInjection);
      end      
       
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Mouse button down action listener, clears action listeners
    
    function acceptInjectionSite(obj,source,event,type,parentObj)
    
      % Clear mouse movement action listener
      set(obj.fig,'WindowButtonMotionFcn',[])
      set(obj.fig,'WindowButtonUpFcn',[])
      
      % Clear mouse down action listener, restore old action listener
      set(obj.fig,'WindowButtonDownFcn',obj.oldActionListener)
        
      [x,y] = obj.getCurrentPoint();
      obj.injection = obj.getInjectionLocation(x,y,type);

      for i = 1:numel(obj.linkedObj)
        obj.linkedObj(i).injection = obj.injection;
      end      
      
      obj.plotAllSpheres();
      
      obj.parent.plotFlatRepresentation(obj.injection);
      
      % Set the treshold of the injection
      parentObj.updateInjectionThreshold();
      
      % Indicate to user that it is ok to mark side now
      parentObj.activateMarkSide();
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Wrapper function
    
    function inj = getInjectionLocation(obj,x,y,type)
      
      switch(type)
        case 'top'
          inj = obj.getView('top').getTopInjectionLocation(x,y); 
      
        case 'side'
          inj = obj.getView('side').getSideInjectionLocation(x,y);

        otherwise
          
          fprintf('Unknown injection marking type %s\n', type)
          keyboard
      end
    
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    function coordsXYZ = imageCoordsToSphere(obj,x,y)
    
      % Transform back to native coordinate system
      xc = x - obj.centre(1);
      yc = y - obj.centre(2);

      % Find z-range --- for now, just use largest radius
      rmax = max(obj.radius);
      v = [xc, xc; yc, yc; rmax, -rmax];
          
      % Find coordinates in native system
      coordsXYZ = obj.invTrans(v);
      
    end
      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function sphereCoordsToImage(obj,x,y,z)
      
    end
    

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function transforms x,y coordinates to the top injection
    % in native cartesian coordinates for the sphere - this
    % function gives a line!
    
    function inj = getTopInjectionLocation(obj,x,y)
      
      % Transform back to native coordinate system
      xc = x - obj.centre(1);
      yc = y - obj.centre(2);

      % Find z-range --- for now, just use largest radius
      rmax = max(obj.radius);
      v = [xc, xc; yc, yc; rmax, -rmax];
          
      % Find coordinates in native system
      inj = obj.invTrans(v);
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function transforms x,y coordinates to the side injection
    % in the native cartesian coordinates for the sphere - this
    % function gives a point!
    
    function inj = getSideInjectionLocation(obj,x,y)
      
      assert(strcmpi(obj.viewType,'side'))
      
      nPoints = 2000;
      
      % All possible points on line of first injection
      injLine = [linspace(obj.injection(1,1),obj.injection(1,2),nPoints); ...
                 linspace(obj.injection(2,1),obj.injection(2,2),nPoints); ...
                 linspace(obj.injection(3,1),obj.injection(3,2),nPoints)];

      % Remove all points outside of sphere
      idx = find((injLine(1,:)/obj.radius(1)).^2 ...
                 + (injLine(2,:)/obj.radius(2)).^2 ...
                 + (injLine(3,:)/obj.radius(3)).^2 <= 1); 
      
      injLine = injLine(:,idx);
      
      % Transform to display coordinate system
      injLineT = obj.trans(injLine);
      injLineT(1,:) = injLineT(1,:) + obj.centre(1);
      injLineT(2,:) = injLineT(2,:) + obj.centre(2);
      injLineT(3,:) = injLineT(3,:) + obj.centre(3);      
      
      % Debug plot
      %p = plot3(injLineT(1,:),injLineT(2,:),injLineT(3,:),'b-')
      %injLineT
      
      % Find closest point in (x,y) coordinate plane
      lineDist = (injLineT(1,:) - x).^2 + (injLineT(2,:) - y).^2;
      [~,minIdx] = min(lineDist);

      injPointLine = injLineT(:,minIdx);

      
      % Ok, we used to be happy here, but now we want to get the
      % closest point on the sphere as seen from the XY plane when
      % looking at the line
      
      % Find the position on the ellipsoid
      
      [xs,ys,zs] = obj.pointOnEllipsoidXY(injPointLine(1), ...
                                          injPointLine(2));

      
      inj = [xs;ys;zs];
      
      % injAnalytical = obj.getSideInjectionLocationAnalytical(x,y);
      % 
      % keyboard
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Working on an analytical solution... Needs to be fixed
    
    function inj = getSideInjectionLocationAnalytical(obj,x,y)
      
      disp('This is not yet correct!')
      assert(false)
      
      assert(strcmpi(obj.viewType,'side'))
 
      % Two points on the linke
      p = obj.injection(:,1);
      q = obj.injection(:,2);
      
      % Radius of ellipsoid
      r = obj.radius;
      
      % x^2/rx^2 + y^2/ry^2 + z^2/rz^2 = 1
      % x = k *(px-qx) + qx
      % y = k *(py-qy) + qy
      % z = k *(pz-qz) + qz
      
      % ---> a * k^2 + b*k + c = 0
      
      a =   (p(1)-q(1))^2 * r(2)^2 * r(3)^2 ...
          + (p(2)-q(2))^2 * r(1)^2 * r(3)^2 ...
          + (p(3)-q(3))^2 * r(1)^2 * r(2)^2;
      
      b = 2*(  (p(1)-q(1)) * r(2)^2*r(3)^2 ...
             + (p(2)-q(2)) * r(1)^2*r(3)^2 ...
             + (p(3)-q(3)) * r(1)^2*r(2)^2);
      
      c =   q(1)^2 * r(2)^2 * r(3)^2 ...
          + q(2)^2 * r(1)^2 * r(3)^2 ...
          + q(3)^2 * r(1)^2 * r(2)^2 ...
          - r(1)^2 * r(2)^2 * r(3)^2;
               
      k1 = (-b + sqrt(b^2 + 4*a*c)) / (2*a); 
      k2 = (-b - sqrt(b^2 - 4*a*c)) / (2*a);
      
      inj1 = k1 *[p(1)-q(1);p(2)-q(2);p(3)-q(3)] + q;
      inj2 = k2 *[p(1)-q(1);p(2)-q(2);p(3)-q(3)] + q;      
      
      inj1T = obj.trans(inj1);
      inj2T = obj.trans(inj2);
      
      try
        assert((inj1T(3) > 0 | inj2T(3) > 0))      
      catch e
        inj1T
        inj2T
        getReport(e)
        keyboard
      end
        
      if(inj1T(3) > 0)
        inj = inj1;
      else
        inj = inj2;
      end
      
      keyboard
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function setRimAngle(obj,source,event,handle,callFunkAfter)
      
      rimAngle = get(handle,'value');

      obj.rimAngle = rimAngle;
      
      for i = 1:numel(obj.linkedObj)
        obj.linkedObj(i).rimAngle = rimAngle;
      end

      obj.plotAllSpheres();
      
      if(exist('callFunkAfter') & ~isempty(callFunkAfter))
        callFunkAfter();
      end      
            
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function [x,y,z] = pointOnEllipsoid(obj,injection)

      normalisedInj = injection ./ obj.radius;
      
      % First convert to spherical coordinates
      theta = atan2(sqrt(sum(normalisedInj(1:2).^2)),normalisedInj(3));
      phi = atan2(normalisedInj(2),normalisedInj(1));
      
      % Have to make sure theta is not larger than rim angle
      if(theta < obj.rimAngle)
        disp('Clicked outside rettina, clamping to rim')
        theta = obj.rimAngle;
      end

      x = obj.radius(1) .* sin(theta) .* cos(phi);
      y = obj.radius(2) .* sin(theta) .* sin(phi);
      z = obj.radius(3) .* cos(theta);
        
      % [theta,phi]
      
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function does not take the closest point, but the point that
    % when looking from the view of the XY-plane looks closest
    
    function [x,y,z] = pointOnEllipsoidXY(obj,xp,yp)
      
      % This should only be called for the side object
      assert(strcmpi(obj.viewType,'side'))
      
      nPoints = 200;
      
      xc = xp - obj.centre(1);
      yc = yp - obj.centre(2);
      zc = max(obj.radius)*linspace(0,1,nPoints);
      
      % Transform the candidate points to the natural coordinate system
      candidatePoints = obj.invTrans([kron([xc;yc],ones(size(zc))); zc]);
      
      xCand = candidatePoints(1,:)/obj.radius(1);
      yCand = candidatePoints(2,:)/obj.radius(2);
      zCand = candidatePoints(3,:)/obj.radius(3);
      
      % Which of the points are closest to the ellipsoid surface
      [minVal,minIdx] = min(abs(xCand.^2 + yCand.^2 + zCand.^2 - 1));
      
      if(minVal > max(obj.radius)/101)
        disp('pointOnEllipsoidXYZ: Something is wrong with the points')
        fprintf('minVal = %f\n', minVal)
        plot3(xp,yp,0,'b*')
        
        set(obj.fig,'windowbuttonmotionfcn',[])
        beep
        keyboard
      end
        
      x = candidatePoints(1,minIdx);
      y = candidatePoints(2,minIdx);
      z = candidatePoints(3,minIdx);

      % Another debug figure
      % figure(2)
      % d = xCand.^2 + yCand.^2 + zCand.^2 - 1;
      % plot(d,'k-'), hold on, plot(minIdx,d,'r*'); hold off
      % figure(obj.fig)
      
      % Debug plot
      % [px,py,pz] = obj.transXYZ(x,y,z);
      % plot3(px,py,pz,'r*')

      
      if(0)
        set(obj.fig,'windowbuttonmotionfcn',[])
        keyboard
      end
            
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    function [x,y,z] = pointsOnNormalisedSphere(obj,injection)
    
      % First convert to spherical coordinates
      if(numel(injection) > 3)
        theta = atan2(sqrt(sum(injection(:,1:2).^2,2)),injection(:,3));
        phi = atan2(injection(:,2),injection(:,1));
      else
        theta = atan2(sqrt(sum(injection(1:2).^2)),injection(3));
        phi = atan2(injection(2),injection(1));
      end
      
      x = sin(theta) .* cos(phi);
      y = sin(theta) .* sin(phi);
      z = cos(theta);
      
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [psi,f] = tomatoCoordinates(obj,coords);
    
      assert(numel(coords) == 3);

      % Get injection point, on ellipsoid
      [x,y,z] = obj.pointOnEllipsoid(coords);
      
      rx = obj.radius(1);
      ry = obj.radius(2);
      rz = obj.radius(3);
      
      % Just make sure we are on the ellipsoid
      try
        assert(all(abs(1 - sqrt((x/rx).^2 + (y/ry).^2 + (z/rz).^2)) < 1e-3))
      catch e
        getReport(e)
        keyboard
      end
        
      phi0 = pi - obj.rimAngle;
      
      % From DS tomato equations, updated to handle ellipsoid
      psi = atan2(y/ry,-cos(phi0) - z/rz);

      idxM = find(psi > pi/2);
      idxP = find(psi < -pi/2);
      
      psi(idxM) = psi(idxM) - pi;
      psi(idxP) = psi(idxP) + pi;

      r = sqrt(sin(phi0).^2 + cos(phi0).^2 .* cos(psi).^2);
      y0 = -ry.*sin(psi).*cos(psi).*cos(phi0);
      z0 = -rz.*sin(psi).*sin(psi).*cos(phi0);
  
      v = -(y - y0)./ry.*sin(psi) + (z - z0)./rz.*cos(psi);
      alpha = atan2(x, v);
      
      % Make sure angles in the second quadrant are negative
      % FIXME: we could avoid this by defining the angle \alpha differently
      idx = find(alpha < 0);
      alpha(idx) = alpha(idx) + 2*pi;
      
      % alpha0 = asin(sin(phi0)/r);
      alpha0 = -asin(cos(phi0)/r);      
      
      f = (alpha - alpha0)./(2*pi - 2*alpha0);

      % Check that f is within bounds, our new NT coordinate
      try
        assert(0 <= f & f <= 1)
      catch e
        getReport(e)
        keyboard
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % This function accounts for left and right eyes
    
    function [fNT,fDV] = dualWedgeCoordinates(obj,point)

      [x,y,z] = obj.pointsOnNormalisedSphere(point);

      % Tomato/wedge coordinate system was originally developed for
      % NT axis
      [~,fNT] = obj.tomatoCoordinatesSPHERE(x,y,z);

      % Rotate 90 degrees and use same function for DV axis
      [~,fDV] = obj.tomatoCoordinatesSPHERE(-y,x,z);

      switch(lower(obj.side))
        case 'left'
          % Default, nothing to change
        case 'right'
          % We need to flip the DV axis
          fDV = 1 - fDV;
        otherwise
          fprintf('Unknown side %s, use left or right\n', obj.side)
          beep
          keyboard
      end
    
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function [psi,f] = tomatoCoordinatesSPHERE(obj,x,y,z);
    
      % Just make sure we are on a unit sphere
      try
        assert(all(abs(1 - sqrt(x.^2 + y.^2 + z.^2)) < 1e-3))
      catch e
        getReport(e)
        keyboard
      end
      
        
      phi0 = pi - obj.rimAngle;
      
      % From DS tomato equations
      psi = atan2(y,-cos(phi0) - z);

      idxM = find(psi > pi/2);
      idxP = find(psi < -pi/2);
      
      psi(idxM) = psi(idxM) - pi;
      psi(idxP) = psi(idxP) + pi;

      r = sqrt(sin(phi0).^2 + cos(phi0).^2 .* cos(psi).^2);
      y0 = -sin(psi).*cos(psi).*cos(phi0);
      z0 = -sin(psi).*sin(psi).*cos(phi0);
  
      v = -(y - y0).*sin(psi) + (z - z0).*cos(psi);
      alpha = atan2(x, v);
      
      % Make sure angles in the second quadrant are negative
      % FIXME: we could avoid this by defining the angle \alpha differently
      idx = find(alpha < 0);
      alpha(idx) = alpha(idx) + 2*pi;
      
      alpha0 = asin(sin(phi0)./r);
      
      try
        f = (alpha - alpha0)./(2*pi - 2*alpha0);
      catch e
        getReport(e)
        keyboard
      end
      
        
      % Check that f is within bounds, our new NT coordinate
      try
        assert(all(0-1e-9 <= f & f <= 1+1e-9))
      catch e
        getReport(e)
        keyboard
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
    % Note that these coordinates assume that we are on a sphere!
    
    function [x,y,z] = tomatoToCartesian(obj,psi,f)

      rx = obj.radius(1);
      ry = obj.radius(2);
      rz = obj.radius(3);
      
      phi0 = pi - obj.rimAngle;
      r = sqrt(sin(phi0).^2 + cos(phi0).^2.*cos(psi).^2);
      y0 = -ry*sin(psi).*cos(psi).*cos(phi0);
      z0 = -rz*sin(psi).*sin(psi).*cos(phi0);
      
      % alpha0 = asin(sin(phi0)./r);
      alpha0 = -asin(cos(phi0)./r);
      
      alpha = alpha0 + f.*(2*pi - 2*alpha0);
      
      x = rx*sin(alpha);
      y = y0 - ry*sin(psi)*cos(alpha);
      z = z0 + rz*cos(psi)*cos(alpha);
  
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [x,y,z] = tomatoToCartesianSPHERE(obj,psi,f,R)

      phi0 = pi - obj.rimAngle;
      r = sqrt(sin(phi0).^2 + cos(phi0).^2.*cos(psi).^2);
      y0 = -sin(psi).*cos(psi).*cos(phi0);
      z0 = -sin(psi).*sin(psi).*cos(phi0);
      alpha0 = asin(sin(phi0)./r);
      alpha = alpha0 + f.*(2*pi - 2*alpha0);
      
      x = R*r*sin(alpha);
      y = R*(y0 - r*sin(psi)*cos(alpha));
      z = R*(z0 + r*cos(psi)*cos(alpha));
  
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function setSide(obj,side)

      obj.side = side;

      if(size(obj.injection,2) == 1)
        [fNT,fDV] = obj.dualWedgeCoordinates(obj.injection);
        
        obj.injNT = fNT;
        obj.injDV = fDV;
      else
        obj.injNT = [];
        obj.injDV = [];
      end

      obj.plotSphere();
    
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function inSphere = withinSphere(obj,x,y)
      
      disp('withinSphere called')
    
      allObj = [obj, obj.linkedObj];
      
      minDist = inf;
      inSphere = [];
      
      for i = 1:numel(allObj)
        d = sqrt(sum((allObj(i).centre(1:2) - [x;y]).^2));
        if(d < max(allObj(i).radius) ...
           & d < minDist)
          minDist = d;
          inSphere = allObj(i);
        end
        
      end
      
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function setViewTransform(obj,angle3)
    
      obj.viewTransform = obj.rotX(angle3(1)) ...
                        * obj.rotY(angle3(2)) ...
                        * obj.rotZ(angle3(3));
      
    end

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function [r,theta,phi] = getPolarCoordinates(obj,x,y,z)
    
      r = sqrt(x.^2 + y.^2 + z.^2);
      theta = acos(z/r);
      phi = atan2(y,x);
      
    end
      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
  end
  
end
