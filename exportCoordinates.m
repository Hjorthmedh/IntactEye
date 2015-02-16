function exportCoordinates()

  name = {};
  NT = [];
  DV = [];
  
  fid = fopen('allNTcoords.csv','w');

  fprintf(fid,'Dir name,phi,NT fraction\n');
  runOnAllReconstructedFiles(@writeData);
  
  fclose(fid);
  
  save('allNTcoords.mat', 'name','NT','DV')
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  function writeData(data,fileName)

    % Retistruct naming convention is that it is the directory that has
    % the unique name, all files have same name...

    fn = fieldnames(data.Dsw);
    if(numel(fn) ~= 1)
      keyboard
      fprintf('I require exactly one marking. File: %s\n', fileName)
      fprintf(fid,'%s,ONE MARKING REQUIRED,ONE MARKING REQUIRED\n',fileName)
      return
    end
    
    if(strcmpi(data.side,'Left'))
      disp('Left')
      NTcoord = 1 - data.Dsdw.(fn{1})(1);
    else
      disp('Right')
      NTcoord = data.Dsdw.(fn{1})(1);
    end
    
    DVcoord = data.Dsdw.(fn{1})(2);
    
    fprintf(fid,'%s,%f,%f\n', ...
            findDirName(fileName), ...
            NTcoord, DVcoord);
  
    name{end+1} = findDirName(fileName);
    NT(end+1) = NTcoord;
    DV(end+1) = DVcoord;
    
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  function dirStr = findDirName(fullStr)

      fullStr = strrep(fullStr,'\\','/');
      slashIdx = find(fullStr == '/');
      
      if(nnz(slashIdx) < 2)
        dirStr = [];
        return
      end
      
      dirStr = fullStr(slashIdx(end-1)+1:slashIdx(end)-1);
      
  end
  
end