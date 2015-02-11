function runOnAllReconstructedFiles(dataFunk)

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
        
        fprintf('Processing %s\n', fileName)
        % Apply the function to the data
        try
          dataFunk(data,fileName)
        catch e
          getReport(e)
          keyboard
        end
      end
        
    catch e
      getReport(e)
      keyboard
    end
    
  end
  
  
  
  
end