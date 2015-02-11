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

ReberData = {{'Ret22.2', [22.6 80]}, ...
             {'Ret22.3', [20   48]}, ...
             {'Ret22.4', [14   23]}, ...
             {'Ret22.6', [13   74]}, ...
             {'Ret22.8', [33   87]}, ...
             {'Ret22.9', [8    74]}, ...
             {'Ret32.1', [88   23]}, ...
             {'Ret32.2', [99   33]}, ...
             {'D5.4',[11 67]}, ...
             {'D5.6',[22 55]}, ...             
             {'D6.11total',[70 38]}, ...
             {'WT1', [85 78]}, ...
             {'WT2', [70 59]}, ...
             {'WT3', [80 58]}};


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
       'Intact Eye (3D)', ...
       'location','Northwest');
  
axis([0 1 0 1])
box off
  
% title('Comparison 3D vs flat')
xlabel('NT axis 3D (retistruct)','fontsize',24)
ylabel('NT axis flat','fontsize',24)  
set(gca,'fontsize',20)

saveas(gcf,'FIGS/Reber-compare-methods-NT-axis.pdf','pdf')


figure(figDV)
legend(pDV,'Projection method (2D)', ...
       'Intact Eye (3D)', ...
       'location','Northwest');
  
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


