clear all, close all

showText = false % true;

% Make sure we have the right coordinates
exportCoordinates()

% These are all coordinates from Retistruct
data = load('allNTcoords.mat');

figNT = figure;
plot([0 1],[0 1],'r-')

figDV = figure;
plot([0 1],[0 1],'r-')


% Reber Email 10 june 2014
%
% 22.2 - 26% NT axis        80% DV axis (where Dorsal  = 0% and Ventral = 100%). so this one is a very ventral injection.
% 22.3 - 20% NT axis        48% DV axis
% 22.4 -14% NT axis         23% DV axis
% 22.6 - 13% NT                74% DV
% 22.8 - 33% NT                87% DV      
% 22.9 - 8% NT                  74% DV
% 32.1 - 88 % NT               23% DV 
% 32.2 - 99% NT                33% DV

% First column NT, second column DV

% ReberData = {{'Ret22.2', [22.6 80]}, ...
%              {'Ret22.3', [20   48]}, ...
%              {'Ret22.4', [14   23]}, ...
%              {'Ret22.6', [13   74]}, ...
%              {'Ret22.8', [33   87]}, ...
%              {'Ret22.9', [8    74]}, ...
%              {'Ret32.1', [88   23]}, ...
%              {'Ret32.2', [99   33]}, ...
%              {'D5.4',[11 67]}, ...
%              {'D5.6',[22 55]}, ...             
%              {'D6.11total',[70 38]}, ...
%              {'Ret1C',[32 52]}, ...
% ... % {'Ret2C',[74 52]}, ...
%              {'Ret3C',[47 37]}  } %, ...
%                                      %             {'WT1', [85 78]}, ...
%                                      %             {'WT2', [70 59]}, ...
%                                      %             {'WT3', [80 58]}};

% Reordered to match colours
ReberData = { {'D5.6',[22 55]}, ...             
              {'Ret22.2', [22.6 80]}, ...
             {'Ret22.3', [20   48]}, ...
             {'Ret22.6', [13   74]}, ...
             {'Ret22.9', [8    74]}, ...
             {'Ret32.2', [99   33]}, ...
              {'Ret32.1', [88   23]}, ...
              {'Ret22.4', [14   23]}, ...
              {'Ret22.8', [33   87]}, ...              
              {'D5.4',[11 67]}, ...
              {'D6.11total',[70 38]}, ...
             {'Ret1C',[32 52]}, ...
... % {'Ret2C',[74 52]}, ...
             {'Ret3C',[47 37]}  } %, ...


sphereNT = NaN*ones(numel(ReberData),1);
sphereDV = NaN*ones(numel(ReberData),1);
retistructNT = NaN*ones(numel(ReberData),1);
retistructDV = NaN*ones(numel(ReberData),1);

for i = 1:numel(ReberData)
  
  ReberName = ReberData{i}{1};
  ReberNTproj = ReberData{i}{2}(1) / 100;  
  ReberDVproj = ReberData{i}{2}(2) / 100;    
  intactRetinaNT = NaN;
  intactRetinaDV = NaN;
  
  % See if intact 3D data exist
  fNameMask = sprintf('SAVE/%s*.tif-save.mat',ReberName);
  files = dir(fNameMask);
  if(numel(files) > 1)
    for j = 1:numel(files)
      fprintf('Multiple files: %s\n', files(j).name)
    end
    beep
    return
  end
  
  % Is there a unique file with data?
  if(numel(files) == 1)
    
    fName = sprintf('SAVE/%s', files(1).name);
    
    fprintf('Reading intact retina NT from %s\n', fName)
    data3D = load(fName);
    intactRetinaNT = data3D.data.topView_injNT;
    intactRetinaDV = data3D.data.topView_injDV;

    assert(0 <= intactRetinaNT & intactRetinaNT <= 1)
    assert(0 <= intactRetinaDV & intactRetinaDV <= 1)
    
    % Save NT and DV for summary CSV file at end
    sphereNT(i) = intactRetinaNT;
    sphereDV(i) = intactRetinaDV;
    
  end
    
  for j = 1:numel(data.name)
    if(strcmpi(ReberName,data.name(j)))
      
      % Save NT and DV for summary CSV file at end
      retistructNT(i) = data.NT(j);
      retistructDV(i) = data.DV(j);
      
      figure(figNT)
      hold on
      
      if(~isnan(ReberNTproj))
        pNT(1) = plot(data.NT(j),ReberNTproj,'ko','markersize',10);
        
        if(showText)
          text(data.NT(j),ReberNTproj+0.03,ReberName, ...
               'fontsize',10,'rotation',90)
        end
        
        hold on
        fprintf('Plotting: %f, %f\n', data.NT(j), ReberNTproj)
      end
              
      if(~isnan(intactRetinaNT))
        pNT(2) = plot(data.NT(j),intactRetinaNT,'r.','markersize',20);

        if(showText & isnan(ReberNTproj))
          text(data.NT(j),intactRetinaNT+0.03,ReberName,...
               'fontsize',10,'rotation',90)
        end
        
        hold on
        fprintf('Plotting: %f, %f\n', data.NT(j), intactRetinaNT)
      else
        fprintf('Missing %s intact 3D data\n', ReberName)
      end
      
      figure(figDV)
      hold on
      
      if(~isnan(ReberDVproj))
        pDV(1) = plot(data.DV(j),ReberDVproj,'ko','markersize',10);
        if(showText)
          text(data.DV(j),ReberDVproj+0.03,ReberName, ...
               'fontsize',10,'rotation',90)
        end
        
        hold on
        fprintf('Plotting: %f, %f\n', data.DV(j), ReberDVproj)
      end
              
      if(~isnan(intactRetinaDV))
        pDV(2) = plot(data.DV(j),intactRetinaDV,'r.','markersize',20);

        if(showText & isnan(ReberNTproj))
          text(data.DV(j),intactRetinaDV+0.03,ReberName, ...
               'fontsize',10, 'rotation',90)
        end
        
        hold on
        fprintf('Plotting: %f, %f\n', data.DV(j), intactRetinaDV)
      end
            
      
    end
  end
    
end

figure(figNT)
legend(pNT,'Projection method (2D)', ...
       'IntactEye (3D)', ...
       'location','Northwest');

axis equal  
axis([0 1 0 1])
box off


% title('Comparison 3D vs flat')
xlabel('NT axis 3D (retistruct)','fontsize',24)
ylabel('NT axis flat','fontsize',24)  
set(gca,'fontsize',20)

saveas(gcf,'FIGS/Reber-compare-methods-NT-axis.pdf','pdf')


figure(figDV)
legend(pDV,'Projection method (2D)', ...
       'IntactEye (3D)', ...
       'location','Northwest');

axis equal
axis([0 1 0 1])
box off

% title('Comparison 3D vs flat')
xlabel('DV axis 3D (retistruct)','fontsize',24)
ylabel('DV axis flat','fontsize',24)
set(gca,'fontsize',20)

saveas(gcf,'FIGS/Reber-compare-methods-DV-axis.pdf','pdf')


fid = fopen('measure-summary.csv','w');

fprintf(fid,'Name,ReberNT,ReberDV,RetistructNT,RetistructDV,SphereNT,SphereDV\n');

for i = 1:numel(ReberData)
  fprintf(fid, '%s,%f,%f,%f,%f,%f,%f\n', ...
          ReberData{i}{1}, ...
          ReberData{i}{2}(1), ...
          ReberData{i}{2}(2), ...          
          100*retistructNT(i), ...
          100*retistructDV(i), ...
          100*sphereNT(i), ...
          100*sphereDV(i));
end

fclose(fid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

colours0 = [0 0 0];

colours1 = [166,206,227
            31,120,180
            178,223,138
            51,160,44
            251,154,153
            227,26,28
            253,191,111
            255,127,0
            202,178,214
            106,61,154
            ... %255,255,153
            177,89,40] /255;

colours2 = [141,211,199
            ...% 255,255,179
            ...%190,186,218
            251,128,114
            128,177,211
            253,180,98
            179,222,105
            252,205,229
            217,217,217
            188,128,189
            204,235,197
            255,237,111]/255;

colours = [colours0;colours1;colours2]*0.9;

% Lets do two more plots

ReberNT = NaN * ones(numel(ReberData),1);
ReberDV = NaN * ones(numel(ReberData),1);

figure, hold on

plot([0 100],[0 100],'--','color',[1 1 1]*0.3)

for i = 1:numel(ReberData)
  
  ReberNT(i) = ReberData{i}{2}(1);
  
  if(~isnan(ReberData{i}{2}(1)))

    plot(ReberData{i}{2}(1)*[1 1],100*[sphereNT(i) retistructNT(i)], ...
          '-','color',[1 1 1]*0.8)

    if(~isnan(retistructNT(i)))
      pR = plot(ReberData{i}{2}(1), 100 * retistructNT(i), ...
                '*','markersize',15,'color',colours(i,:));
    end
  
    if(~isnan(sphereNT(i)))
      p3 = plot(ReberData{i}{2}(1), 100*sphereNT(i), ...
                '.','markersize',30,'color',colours(i,:));
    end
    
  end

  if(i == 1)
    pR1 = pR;
    p31 = p3;
  end
  
end

legend([pR1 p31], 'Retistruct','IntactEye','location','southeast')
xlabel('Flat NT','fontsize',24)
ylabel('Spherical NT','fontsize',24)
set(gca,'fontsize',20)
box off
axis equal  
axis([0 100 0 100])
set(gca,'xtick',0:20:100)
set(gca,'ytick',0:20:100)

saveas(gcf,'FIGS/Reber-compare-methods-NT-axis-alt.pdf','pdf')


pR = []; p3 = [];

figure, hold on

plot([0 100],[0 100],'--','color',[1 1 1]*0.3)

for i = 1:numel(ReberData)

  ReberDV(i) = ReberData{i}{2}(2);
  
  if(~isnan(ReberData{i}{2}(2)))

    plot(ReberData{i}{2}(2)*[1 1],100*[sphereDV(i) retistructDV(i)], ...
          '-','color',[1 1 1]*0.8)
    
    if(~isnan(retistructDV(i)))
      pR = plot(ReberData{i}{2}(2), 100 * retistructDV(i), ...
                '*','markersize',15,'color',colours(i,:));
    end
  
    if(~isnan(sphereDV(i)))
      p3 = plot(ReberData{i}{2}(2), 100*sphereDV(i), ...
                '.','markersize',30, 'color',colours(i,:));
    end
    
    
  end

  if(i == 1)
    pR1 = pR;
    p31 = p3;
  end
  
  
end

legend([pR1 p31], 'Retistruct','IntactEye','location','southeast')
xlabel('Flat DV','fontsize',24)
ylabel('Spherical DV','fontsize',24)
set(gca,'fontsize',20)
box off
axis equal  
axis([0 100 0 100])
set(gca,'xtick',0:20:100)
set(gca,'ytick',0:20:100)

saveas(gcf,'FIGS/Reber-compare-methods-DV-axis-alt.pdf','pdf')

format compact

% Proj vs IntactEye
CNTPI = corr([ReberNT,sphereNT],'rows','complete');
fprintf('Corr Proj vs IntactEye (NT): %.2f\n', CNTPI(2))

% Proj vs Retistruct
CNTPRS = corr([ReberNT,retistructNT],'rows','complete');
fprintf('Corr Proj vs Retistruct (NT): %.2f\n', CNTPRS(2))

% IntactEye vs Retistruct
CNTIRS = corr([sphereNT,retistructNT],'rows','complete');
fprintf('Corr IntactEye vs Retistruct (NT): %.2f\n', CNTIRS(2))

% Save for DV

CDVPI = corr([ReberDV,sphereDV],'rows','complete');
fprintf('Corr Proj vs IntactEye (DV): %.2f\n', CDVPI(2))


CDVPRS = corr([ReberDV,retistructDV],'rows','complete');
fprintf('Corr Proj vs Retistruct (DV): %.2f\n', CDVPRS(2))


CDVIRS = corr([sphereDV,retistructDV],'rows','complete');
fprintf('Corr IntactEye vs Retistruct (DV): %.2f\n', CDVIRS(2))

