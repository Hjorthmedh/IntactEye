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

      if(isempty(obj.imageB))
        if(~isempty(obj.imageA))
          disp('Only one image loaded, nothing to combine')
          obj.combinedImage = obj.imageA.img;
        end
        
        return
      end

      
      obj.combinedImage = obj.combineImages(obj.imageA.img,obj.imageB.img);
      
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
      
      if(isempty(fileName) | fileName == 0)
        imageStruct = [];
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
      
      try
        img = [imgA,imgB];
      catch 
        fprintf(['Failed to merge the images, are they different ' ...
                 'size? Trying along other dimension.'])
        img = [imgA; imgB];
      end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    function img = imageCrop(obj,origImg)
      
       % !!! Add me later
      
    end
    
  end
  
end
