% Purpose of this loader script is to allow the user to either
% combine two images, or crop an existing image ... or both

classdef ImageLoader < handle

  properties
    
    imageA = struct('filename', [], ...
                    'filepath', [], ...
                    'img', []);

    imageB = struct('filename', [], ...
                    'filepath', [], ...
                    'img', []);
   
    combinedImage = [];
    
    image = [];
    
  end
  
  methods
    
    function obj = ImageLoader()
      
      obj.imageA = obj.loadImage();
      obj.imageB = obj.loadImage(obj.imageA.filepath);

      obj.combinedImage = obj.combineImages(obj.imageA,obj.imageB);
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function imageStruct = loadImage(obj,filePath,fileName)

      disp('loadImage called')
      
      if(~exist('filePath'))
        if(exist('/Users/hjorth/DATA/ReberRetina/'))
          filePath = '/Users/hjorth/DATA/ReberRetina/';
        else
          filePath = [];
        end
      end
      
      if(~exist('fileName') | isempty(fileName))
        [fileName,filePath] = uigetfile(sprintf('%s/*.tif*', filePath));
      end
      
      if(isempty(fileName))
        img = [];
        return
      end
      
      fName = sprintf('%s/%s', filePath, fileName);
      img = imread(fName);
      
      img = img(end:-1:1,:,:);
      
      imageStruct.filename = fileName;
      imageStruct.filepath = filePath;
      imageStruct.img = img;
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function img = combineImages(obj,imgA,imgB)
      
      [rA,cA] = size(imgA);
      [rB,cB] = size(imgB);
      
      if(rA > rB)
        imgB(rA,1,:) = [0,0,0];
      end
      
      if(rB > rA)
        imgA(rB,1,:) = [0,0,0];
      end
      
      img = [imgA,imgB];
      
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function img = imageCrop(obj,origImg)
      
       % !!! Add me later
      
    end
    
  end
  
end
