classdef IntactEye < handle
  
  properties
    
    fileName = [];
    filePath = [];
    image = [];
    imageExtract = []; % Used to get area of injection
  
    topView = [];
    sideView = [];
        
    fig = [];
    
    handleLoadMenu = []
    
    handleAxis = [];
    handleImage = [];
    
    handlePolarAxis = [];
    
    handleRotTop = [];
    handleRotSide = [];
    
    handleRotTopText = [];
    handleRotSideText = [];
    
    handleResetView1 = [];
    handleResetView2 = [];
    
    handleUndoRot1 = [];
    handleUndoRot2 = [];
    
    handleHide1 = [];
    handleHide2 = [];
   
    handleRimAngle = [];
    handleRimAngletext = [];
    
    handleMarkTop = [];
    handleMarkSide = [];
    handleRimMarktext = [];
    
    handleSide = [];
    
    handleTopCentre = [];
    handleSideCentre = [];
    
    handleSave = [];
    handleLoad = [];
    handleLoadImage = [];
    handleLoadImage2 = [];    
    
    handlePrintFig = [];

    handleSyntheticText = [];
    handleTrain = [];
    handleVerify = [];

    handleLocation = [];
    
    handleEstimateAreaText = [];
    handleEstimateAreaTop = [];
    handleEstimateAreaSide = [];
    handleEstimateAreaThreshold = [];
    
    syntheticData = [];
    
    version = 0.106;
    oldestAcceptedVersion = 0.102; % Dont load older files, due to
                                   % file format changes.
    
    variablesToSave = { 'version', ...
                        'fileName','filePath',...
                        'topView.viewTransform', ...
                        'topView.rotAngle', ...
                        'topView.centre', 'topView.radius', 'topView.angle', ...
                        'topView.rimAngle', 'topView.injection', ...
                        'topView.injectionRegion', ...
                        'topView.injNT', 'topView.injDV', ...
                        'topView.side', ...
                        'sideView.viewTransform', ...
                        'sideView.rotAngle', ...
                        'sideView.centre', 'sideView.radius', 'sideView.angle', ...
                        'sideView.rimAngle', 'sideView.injection', ...
                        'sideView.injectionRegion', ...
                        'sideView.injNT', 'sideView.injDV', ...
                        'sideView.side', ...
                        'injectionAreaFraction' ...
                      };
    
    injectionAreaFraction = NaN;
    
  end
  
  methods
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function obj = IntactEye()

      obj.imageExtract = ImageExtract(obj);
      obj.setupGUI();

      if(0)
        obj.loadImage();
        obj.showImage();
        obj.showSpheres();
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function setupGUI(obj)
      
      obj.fig = figure('units','normalized');
      set(obj.fig,'position',[0.01 0.1 0.8 0.9])
      
      obj.handleAxis = axes('position', [0 0 0.72 1]);
      hold on
      obj.handleAxis.Clipping = 'off'

      obj.handlePolarAxis = axes('position', [0.75 0.1 0.20 0.25]);
      axis equal
      
      obj.handleLoadMenu = uimenu('label','Load')
      uimenu(obj.handleLoadMenu,'label','Combine images','callback',@obj.combineImages)
      
      obj.topView = EyeSphere('top','left',[400; 600; 0],obj.fig,obj.handleAxis);
      obj.sideView = EyeSphere('side','left',[400; 200; 0],obj.fig,obj.handleAxis);      
      
      obj.topView.setParent(obj);
      obj.sideView.setParent(obj);      
      
      obj.topView.captureActionListener();
      obj.sideView.captureActionListener();
      
      % Rotation sliders
      objT = obj.topView;
      objS = obj.sideView;
      
      obj.handleRotTop = uicontrol('style','slider','min',-pi,'max',pi, ...
                                  'value', objT.rotAngle, ...
                                   'interruptible','off', ...                                  
                                   'sliderstep', [0.005 0.05], ...
                                   'units','normalized','position', [0.73 0.86 0.24 0.04]);
      set(obj.handleRotTop,'callback',{@objT.rotate,obj.handleRotTop,@obj.updateSliders});
      
      obj.handleRotTopText = uicontrol('style','text','string','Rotation (top view)', ...
                                      'backgroundcolor',get(gcf,'color'), ...
                                      'units','normalized', ...
                                      'fontsize', 10, 'horizontalalignment','left', ...
                                      'position', [0.73 0.905 0.24 0.015]);
      
      
      obj.handleRotSide = uicontrol('style','slider','min',-pi,'max',pi, ...
                                    'value', objS.rotAngle, ...    
                                    'interruptible','off', ...                                  
                                    'sliderstep', [0.005 0.05], ...                                  
                                    'units','normalized','position', [0.73 0.75 0.24 0.04]);
      set(obj.handleRotSide,'callback',{@objS.rotate,obj.handleRotSide,@obj.updateSliders});

      obj.handleRotSideText = uicontrol('style','text','string','Rotation (side view)', ...
                                        'backgroundcolor',get(gcf,'color'), ...
                                        'units','normalized', ...
                                        'fontsize', 10, 'horizontalalignment','left', ...
                                        'position', [0.73 0.795 0.24 0.015]);        

      
      obj.handleResetView1 = uicontrol('style','pushbutton','string','Reset', ...
                                       'interruptible','off', ...                                       
                                       'units','normalized','position', ...
                                       [0.80 0.83 0.06 0.04], ...
                                       'callback', {@objT.resetView, @obj.updateSliders});

      obj.handleResetView2 = uicontrol('style','pushbutton','string','Reset', ...
                                       'interruptible','off', ...                                       
                                       'units','normalized','position', ...
                                       [0.80 0.72 0.06 0.04], ...
                                       'callback', {@objS.resetView, @obj.updateSliders});
      
    
      obj.handleHide1 = uicontrol('style','pushbutton','string','Hide', ...
                                  'interruptible','off', ...                                  
                                  'units','normalized','position', ...                                  
                                  [0.73 0.83 0.055 0.04]);
      set(obj.handleHide1,'callback', {@objT.hideSphere,obj.handleHide1});

      obj.handleHide2 = uicontrol('style','pushbutton','string','Hide', ...
                                  'interruptible','off', ...                                  
                                  'units','normalized','position', ...                                  
                                  [0.73 0.72 0.055 0.04]);
      set(obj.handleHide2,'callback', {@objS.hideSphere,obj.handleHide2});
      
      
      obj.handleRimAngle = uicontrol('style','slider','min',0,'max',pi/2, ...
                                     'value', pi/3, ...
                                     'interruptible','off', ...                                     
                                     'units','normalized', ...
                                     'position', [0.73 0.62 0.24 0.04]);

      set(obj.handleRimAngle,'Callback', {@objT.setRimAngle,obj.handleRimAngle, @obj.updateSliders})
      
      
      obj.handleRimAngletext = uicontrol('style','text','string','Rim angle (marked in yellow)', ...
                                      'backgroundcolor',get(gcf,'color'), ...
                                      'units','normalized', ...
                                      'fontsize', 10, 'horizontalalignment','left', ...
                                      'position', [0.73 0.665 0.24 0.015]);       
      
      
      obj.handleMarkTop = uicontrol('style','pushbutton','string','Mark top', ...
                                    'interruptible','off', ...                                    
                                    'units','normalized','position', ...                                  
                                    [0.73 0.54 0.07 0.04], ...
                                    'callback', {@objT.markInjection,'top',obj});

      obj.handleMarkSide = uicontrol('style','pushbutton','string','Mark side', ...
                                     'interruptible','off', ...                                     
                                     'units','normalized', ...
                                     'foregroundcolor', 0.4*[1 1 1], ...
                                     'position', [0.81 0.54 0.07 0.04], ...
                                     'callback', {@objS.markInjection,'side',obj});

      
      obj.handleEstimateAreaText = uicontrol('style','text', ...
                                             'string','Estimate injection area', ...
                                             'backgroundcolor',get(gcf,'color'), ...
                                             'units','normalized', ...
                                             'fontsize', 10, 'horizontalalignment','left', ...
                                             'position', [0.89 0.585 0.24 0.015]);          
            
      obj.handleEstimateAreaTop = uicontrol('style','pushbutton', ...
                                            'string','Top', ...
                                            'interruptible','off', ...                                     
                                            'units','normalized', ...
                                            'foregroundcolor', 0*[1 1 1], ...
                                            'position', [0.89 0.54 0.05 0.04], ...
                                            'callback', {@obj.estimateArea,objT});
      
      obj.handleEstimateAreaSide = uicontrol('style','pushbutton', ...
                                            'string','Side', ...
                                            'interruptible','off', ...                                     
                                            'units','normalized', ...
                                            'foregroundcolor', 0*[1 1 1], ...
                                            'position', [0.94 0.54 0.05 0.04], ...
                                            'callback', {@obj.estimateArea,objS});
      
      
      obj.handleEstimateAreaThreshold = uicontrol('style','slider', ...
                                                 'min',1,'max',255, 'value',obj.imageExtract.threshold, ...
                                                  'sliderstep', [1/255 10/255], ...
                                                 'interruptible','off', ...  
                                                 'units','normalized', ...
                                                 'foregroundcolor', 0*[1 1 1], ...
                                                 'position', [0.89 0.49 0.10 0.04], ...
                                                 'callback', {@obj.setAreaThreshold})

      if(exist('alphaShape') ~= 2)
        % Older version of matlab, does not have alphaShape
        disp(['Version 2014b or later is needed. Older versions does ' ...
              'not have alphaShape.'])
        
        set(obj.handleEstimateAreaTop,'callback',[], ...
                          'foregroundcolor',0.5*[1 1 1])
        set(obj.handleEstimateAreaSide,'callback',[], ...
                          'foregroundcolor',0.5*[1 1 1])        
        set(obj.handleEstimateAreaThreshold,'callback',[])        
        
      end
            
      obj.handleRimMarktext = uicontrol('style','text','string', ...
                                        'Mark injection side (first top, then side)', ...
                                        'backgroundcolor',get(gcf,'color'), ...
                                        'units','normalized', ...
                                        'fontsize', 10, 'horizontalalignment','left', ...
                                        'position', [0.73 0.585 0.16 0.015]);          
      
      obj.handleLocation = uicontrol('style','text','string', ...
                                     'Injection location: -', ...
                                     'backgroundcolor',get(gcf,'color'), ...
                                     'units','normalized', ...
                                     'fontsize', 14, 'horizontalalignment','left', ...
                                     'position', [0.73 0.46 0.24 0.035]);          
         
      
      
      obj.handleSave = uicontrol('style','pushbutton','string','Save', ...
                                 'interruptible','off', ...        
                                 'foregroundcolor', 0.4*[1 1 1], ...
                                 'units','normalized','position', ...                                  
                                 [0.73 0.4 0.07 0.04], ...
                                 'callback', @obj.saveGUI);

      obj.handleLoad = uicontrol('style','pushbutton','string','Reload', ...
                                 'interruptible','off', ...                                 
                                 'units','normalized','position', ...                                  
                                 [0.86 0.95 0.06 0.04], ...
                                 'callback', @obj.loadGUI);
      

      obj.handleLoadImage2 = uicontrol('style','pushbutton','string','Load images', ...
                                      'interruptible','off', ...                                      
                                     'units','normalized','position', ...                                  
                                     [0.73 0.95 0.06 0.04], ...
                                     'callback', @ ...
                                      obj.combineImages);
      
      obj.handleLoadImage = uicontrol('style','pushbutton','string','Load image', ...
                                      'interruptible','off', ...                                      
                                     'units','normalized','position', ...                                  
                                     [0.795 0.95 0.06 0.04], ...
                                     'callback', @ ...
                                      obj.loadImageGUI);
      
      obj.handleSide = uicontrol('style','pushbutton','string','Left eye', ...
                                 'interruptible','off', ...                                     
                                 'units','normalized', ...
                                 'position', [0.925 0.95 0.06 0.04], ...
                                 'callback', @obj.changeEyeSide);


      obj.handleTrain = uicontrol('style','pushbutton','string','Train', ...
                                  'interruptible','off', ...                                      
                                  'units','normalized','position', ...                                  
                                  [0.92 0.435 0.07 0.045], ...
                                  'callback', @obj.trainUser);

      obj.handleVerify = uicontrol('style','pushbutton','string','Verify', ...
                                  'interruptible','off', ...                                      
                                  'units','normalized','position', ...                                  
                                  [0.92 0.385 0.07 0.045], ...
                                  'callback', @obj.verifyUser);

      obj.handleSyntheticText = uicontrol('style','text','string','Synthetic data', ...
                                      'backgroundcolor',get(gcf,'color'), ...
                                      'units','normalized', ...
                                      'fontsize', 10, 'horizontalalignment','left', ...
                                      'position', [0.92 0.48 0.24 0.015]);       
      
      obj.handlePrintFig = uicontrol('style','pushbutton','string','Export figure', ...
                                     'interruptible','off', ...                                     
                                     'units','normalized','position', ...                                  
                                     [0.81 0.4 0.07 0.04], ...
                                     'callback', @obj.exportFIG);
      
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function loadImage(obj,lazyFlag)
    
      if(exist('lazyFlag') & lazyFlag)
        if(isempty(obj.fileName))
          obj.fileName = 'ret22.2.tif';
          obj.filePath = '/Users/hjorth/DATA/ReberRetina/Ret22.2';
        end
      else
        myPath = '/Users/hjorth/DATA/ReberRetina';
        if(exist(myPath))
          obj.filePath = myPath;
        end
          
        [obj.fileName,obj.filePath] = uigetfile(sprintf('%s/*.tif*', obj.filePath));
      end
      
      if(~obj.fileName)
        disp('No file selected')
        return
      end
        
      fprintf('Reading %s/%s\n', obj.filePath, obj.fileName)
      
      obj.image = imread(sprintf('%s/%s',obj.filePath,obj.fileName));
      
      % We want to use the right handed coordinate system
      obj.image = obj.image(end:-1:1,:,:);
      
      set(obj.fig,'name',(sprintf('IntactEye - %s', obj.fileName)))
      
      % Make sure any synthetic data is cleared
      obj.syntheticData = [];
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function showImage(obj)
      
      if(~isempty(obj.image))
        set(obj.fig,'currentaxes',obj.handleAxis);
        
        if(~isempty(obj.topView))
          obj.topView.deleteHandles();
        end
        
        if(~isempty(obj.sideView))        
          obj.sideView.deleteHandles();
        end
        
        if(~isempty(obj.handleImage))
          try
            delete(obj.handleImage);
          end
          obj.handleImage = [];
        end
        
        cla
        obj.handleImage = imshow(obj.image);
        set(gca,'ydir','normal')
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function showSpheres(obj)
      
      set(obj.fig,'currentaxes',obj.handleAxis);
      
      try
        obj.topView.plotSphere();
        obj.sideView.plotSphere();
        obj.topView.captureActionListener();
        obj.sideView.captureActionListener();
        obj.plotFlatRepresentation(obj.topView.injection,obj.topView.injectionRegion);
      catch e
        getReport(e)
        keyboard
      end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function save(obj)
      
      if(exist('SAVE') ~= 7)
        mkdir('SAVE')
      end
      
      if(iscell(obj.fileName))
        fName = sprintf('SAVE/%s-%s-save.mat', obj.fileName{1},obj.fileName{2});
      else
        fName = sprintf('SAVE/%s-save.mat', obj.fileName);
      end
      
      % Create data structure with all the info
      data = struct([]);
      for i = 1:numel(obj.variablesToSave)
        str = sprintf('data(1).%s = obj.%s;', ...
                      strrep(obj.variablesToSave{i},'.','_'), ...
                      obj.variablesToSave{i});
        try
          eval(str);
        catch e
          getReport(e)
          keyboard
        end
      end
      
      fprintf('Saving state to %s\n', fName)
      save(fName,'data','-v7.3');
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function load(obj,fName)
            
      obj.topView.viewType = 'top';
      obj.sideView.viewType = 'side';
      
      obj.topView.reset();
      obj.sideView.reset();
      
      % Reload data structure
      data = load(fName);
      data = data.data;
      
      for i = 1:numel(obj.variablesToSave)
        
        if(strcmpi(obj.variablesToSave{i},'version'))
          if(data.version < obj.oldestAcceptedVersion)
            fprintf(['Trying to load version %s, please proceed ' ...
                     'with caution (currentVersion %s).\n'], ...
                    num2str(data.version), num2str(obj.version))
          end
          % Don't load version information
          continue
        end
        
        try
          str = sprintf('obj.%s = data.%s;', ...
                        obj.variablesToSave{i}, ...
                        strrep(obj.variablesToSave{i},'.','_'));
          eval(str);
        catch e
          getReport(e)
        end
      end
      
      fprintf('Data version %f\n', data.version)
      
      if(data.version < 0.1040)
        fprintf('Found version %f, upgrading to version %f.\n', ...
                data.version, obj.version)
        % We need to convert to new format
        obj.topView.setViewTransform(obj.topView.angle);
        obj.sideView.setViewTransform(obj.sideView.angle);
        
        obj.topView.originalViewTransform = obj.topView.viewTransform;
        obj.sideView.originalViewTransform = obj.sideView.viewTransform;        
      end
           
      % Consistency check on data
      try
        assert(all(obj.topView.radius == obj.sideView.radius))
        assert(obj.topView.rimAngle == obj.sideView.rimAngle)
        assert(all(obj.topView.injection(:) == obj.sideView.injection(:)))
      catch e
        getReport(e)
        keyboard
      end
        
      % Reload image
      
      obj.loadImage(1); % Uses filename already in object
      obj.showImage();
      
      % Update spheres
      
      obj.showSpheres();
      
      % Update the sliders
      
      obj.updateInjectionThreshold();
      obj.updateSliders();
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function updateSliders(obj)
      
      % Sliders
      set(obj.handleRotTop,'value',obj.topView.rotAngle);
     
      set(obj.handleRotSide,'value',obj.sideView.rotAngle);
      
      set(obj.handleRimAngle,'value',obj.topView.rimAngle)
      
      % Text    
      set(obj.handleRotTopText,'string', ...
                        sprintf('Rotation (top view): %.1f', obj.topView.rotAngle*180/pi));
      
      set(obj.handleRotSideText,'string', ...
                        sprintf('Rotation (side view): %.1f', obj.sideView.rotAngle*180/pi));
      
      set(obj.handleRimAngletext,'string', ...
                        sprintf('Rim angle (marked in yellow): %.1f', obj.topView.rimAngle*180/pi));

      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function loadGUI(obj,source,event)
      
      [fName,fPath] = uigetfile('SAVE/*.mat');
      
      matFile = sprintf('%s/%s',fPath,fName);
      fprintf('Loading %s\n', matFile)
      if(fName)
        obj.load(matFile);
      end
      
      set(obj.handleSave,'foregroundcolor',[0 0 0 ])
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function saveGUI(obj,source,event)
      
      if(isempty(obj.image))
        disp('No image loaded, aborting save')
        return
      end
      
      obj.save();
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function loadImageGUI(obj,source,event)
      obj.loadImage();
      % obj.setupGUI();

      obj.showImage();
      obj.showSpheres(); 
      obj.updateSliders()
      
      set(obj.handleSave,'foregroundcolor',[0 0 0 ])

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function name = getExpName(obj)
      
      if(~isempty(obj.syntheticData))
        name = 'Synthetic data';
        return
      end
      
      if(isempty(obj.filePath))
        name = char('');
        return
      end
      
      if(iscell(obj.filePath))
        filePath = obj.filePath{1};
      else
        filePath = obj.filePath;
      end
      
      if(filePath(end) == '/')
        fPath = filePath(1:end-1);
      else
        fPath = filePath;
      end
      
      idx = find(fPath == '/',1,'last');
      if(isempty(idx))
        name = fPath;
      else
        if(idx == numel(fPath))
          name = 'noname';
        else
          name = fPath(idx+1:end);
        end
      end
      
      name = char(name);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function exportFIG(obj,source,event)
      
      plotFig = figure('visible','off');
      
      % Add image first, make sure we got the coordinate system the
      % standard way
      imshow(obj.image);
      set(gca,'ydir','normal')

      % Next plot the spheres
      obj.topView.plotSphere();
      obj.sideView.plotSphere();
      
      % Add text with coordinates
      coordStr = sprintf('%s: NT = %.2f, DV = %.2f', ...
                         obj.getExpName(), ...
                         obj.topView.injNT, obj.topView.injDV);
      
      % Finally save the figure
      
      pos = get(plotFig,'position');
      set(plotFig,'position',[0 0 pos(3:4)*2])
      
      title([])
      
      fName = sprintf('FIGS/%s-3D-coord-%.2f-NT-%.2f-DV.png', ...
                      obj.getExpName, obj.topView.injNT, obj.topView.injDV);
      fprintf('Saving figure to: %s\n', fName)
      saveas(plotFig,fName,'png')
      
      figure(obj.fig);
      obj.topView.plotSphere();
      obj.sideView.plotSphere();      
      
      close(plotFig)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      % We also want to plot the flat injection view
      plotInjFig = figure('visible','off'); % Turn off when we know
                                           % it works
      
      % -1 means we plot in the current figure
      obj.plotFlatRepresentation(obj.topView.injection, obj.topView.injectionRegion,-1);
      
      
      fName = sprintf('FIGS/%s-FLAT-3D-coord-%.2f-NT-%.2f-DV.pdf', ...
                      obj.getExpName, obj.topView.injNT, obj.topView.injDV);
      fprintf('Saving figure to: %s\n', fName)
      saveas(plotInjFig,fName,'pdf')
      
      close(plotInjFig)
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function activateMarkSide(obj)
      set(obj.handleMarkSide,'foregroundcolor',[0 0 0]);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function updateInjectionThreshold(obj)
      
      % Injection locations for top and side sphere
      if(numel(obj.topView.injection) == 3)
        try
          vTop = obj.topView.trans(obj.topView.injection) + obj.topView.centre;
          vSide = obj.sideView.trans(obj.sideView.injection) + obj.sideView.centre;
        catch e
          getReport(e)
          keyboard
        end
      else
        % Cant update the treshold if injection point is not marked
        return
      end
        
      % Maximal threshold, to get no more than 10%
      maxThreshold = obj.imageExtract.getMaxThreshold(round([vTop(1) ...
                          vSide(1)]),round([vTop(2) vSide(2)]));
      
      % Update sliders
      curVal = get(obj.handleEstimateAreaThreshold,'value');

      % If value is above max value, then the slider might not render...
      if(curVal > maxThreshold)
        set(obj.handleEstimateAreaThreshold,'value',maxThreshold);
      end
      
      set(obj.handleEstimateAreaThreshold,'sliderstep', [1/maxThreshold, 10/maxThreshold])
      
      set(obj.handleEstimateAreaThreshold,'max',maxThreshold);

      obj.setAreaThreshold([],[]);
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function trainUser(obj, source, event)
      
      if(isempty(obj.syntheticData))
        obj.syntheticData = SyntheticData(obj.handleAxis,obj.fig);
      else
        obj.syntheticData.randomizeEye();
        obj.syntheticData.plot();
      end

      if(~isempty(obj.handleImage))
        try
          delete(obj.handleImage);
        end
        obj.handleImage = [];
      end
       
      
      obj.image = [];
      obj.fileName = [];
      obj.filePath = [];
      
      obj.topView.resetView();
      obj.sideView.resetView();
      
      obj.topView.resetInjection();
      obj.sideView.resetInjection();
      
      obj.showSpheres(); 
      obj.updateSliders()
      
      set(obj.fig,'name','Synthetic data')
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function printInjectionLocation(obj,NT,DV)
      if(~isnan(obj.injectionAreaFraction))
       
        
        str = sprintf('Injection location: %.2fNT %.2fDV\nInj size %.2f %% - %s', ...
                NT,DV, obj.injectionAreaFraction*100, ...
                      obj.getExpName());
      else
        str = sprintf('Injection location: %.2fNT %.2fDV\n%s', ...
                      NT,DV,obj.getExpName());
      end
      
      
      set(obj.handleLocation,'String', str)
      
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function verifyUser(obj, source, event)
      
      if(isempty(obj.syntheticData))
        disp('You can only verify your skills on synthetic data')
        return
      end
      
      if(size(obj.topView.injection,2) ~= 1)
        disp('You need to make an injection both in top and side view')
        return
      end
      
      % Ok our user got skills, lets see how good they really are
      
      obj.syntheticData.verifyUser(obj.topView,obj.sideView);
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function changeEyeSide(obj,source,event)
      
      oldSide = get(obj.handleSide,'string');

      switch(oldSide)
        case 'Left eye'
          newSide = 'Right';
          
        case 'Right eye'
          newSide = 'Left';
          
        otherwise
          fprintf('Unknown eye: %s\n', oldSide)
          beep
          keyboard
      end
      
      set(obj.handleSide,'string',sprintf('%s eye', newSide));
      
      obj.topView.setSide(lower(newSide));
      obj.sideView.setSide(lower(newSide));
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function estimateArea(obj, source, event, eyeSphere)
    
      if(isempty(obj.imageExtract))
        obj.imageExtract = ImageExtract(obj);
      end

      obj.imageExtract.markInjection(eyeSphere);

      obj.topView.injectionRegion = obj.imageExtract.injectionAreaXYZ;
      obj.sideView.injectionRegion = obj.imageExtract.injectionAreaXYZ;      
      
      obj.injectionAreaFraction = obj.imageExtract.estimateInjectionSize();
      
      fprintf('Injection size: %.2f %%\n', obj.injectionAreaFraction*100)
      
      obj.showSpheres();
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function setAreaThreshold(obj,source,event)
      v = get(obj.handleEstimateAreaThreshold,'Value');
      obj.imageExtract.threshold = v;
      
      fprintf('Area threshold set to %.0f\n', v)
      
      % Should we rerun the detection?
      if(~isempty(obj.imageExtract.lastSphere))
        obj.imageExtract.markInjection(obj.imageExtract.lastSphere);
      end
      
      obj.showSpheres();
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function combineImages(obj,source,event)
      
      imLoad = ImageLoader();
      
      obj.fileName = {imLoad.imageA.filename, imLoad.imageB.filename};
      obj.filePath = {imLoad.imageA.filepath, imLoad.imageB.filepath};
      obj.image = imLoad.combinedImage;
      
      % Show the user the new data
      obj.showImage();
      obj.showSpheres();
      obj.updateInjectionThreshold();
      obj.updateSliders();
      
    end
   
  end
  
end
