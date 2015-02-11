dataRootDir = '/Users/hjorth/DATA/ReberRetina';

dataDirs = dir(dataRootDir);
dataDirs = dataDirs(cat(1,dataDirs.isdir));

for i = 1:numel(dataDirs)

  if(strcmp(dataDirs(i).name,'..') ...
     || strcmp(dataDirs(i).name,'.'))
    continue
  end
  
  clear data
  try
    fileName = sprintf('%s/%s/r.mat',dataRootDir,dataDirs(i).name);
    if(exist(fileName,'file'))
      data = load(fileName);
      
      % Plot the retina
      figure
      
      % Plot tears
      fn = fieldnames(data.Tss);

      for j = 1:numel(fn)
        phi = data.Tss.(fn{j})(:,1);
        lambda = data.Tss.(fn{j})(:,2);
        polar(lambda,(phi .* 180/pi) + 90)
        hold on
      end
      
      % Plot data points
      fn = fieldnames(data.Dss)
      for j = 1:numel(fn)
        phi = data.Dss.(fn{j})(:,1);
        lambda = data.Dss.(fn{j})(:,2);
        polar(lambda,(phi .* 180/pi) + 90,'.r')
        hold on
      end
      
      % Plot landmarks
      fn = fieldnames(data.Sss)
      for j = 1:numel(fn)
        phi = data.Sss.(fn{j})(:,1);
        lambda = data.Sss.(fn{j})(:,2);
        polar(lambda,(phi .* 180/pi) + 90,'.r')
        hold on
      end      

      % Lets try to calculate an angle which could correspond to
      % the N-T axis.
      if(1)
        
        
      end
      
    end
  catch e
    getReport(e)
    keyboard
  end
    
end