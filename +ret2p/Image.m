%{
ret2p.Image (imported) # Structural image and ROIs

-> ret2p.Quadrant
---
image=null      : longblob          # structural image
roi             : longblob          # roi image
pixel_length    : float             # size of pixel
pixel_area      : float             # area of pixel
        
%}

classdef Image < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.Image');
        popRel = ret2p.Quadrant;
    end
    
    methods
        function self = Image(varargin)
            self.restrict(varargin{:})
        end 
            
     
        function plotStruct(self,ids)
            
            roi = fetch1(self,'roi');
            im = fetch1(self,'image');
            im = im-min(im(:));
            im = im/prctile(im(:),95);
                        
            roi2 = false(size(roi));
            for i=1:length(ids)
                roi2(roi==ids(i))=true;
            end
            
            im = im(4:end,:);
            roi2 = roi2(4:end,:);
            
            imshow(im);
            fg = cat(3,ones(size(im)),zeros(size(im)),zeros(size(im)));
            hold on
            h = imshow(fg);
                        
            alpha = roi2 * .3;
            set(h,'AlphaData',alpha)
            
        end
        
    end
    
    
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            path = fetch1(ret2p.Dataset(key),'path');
            folder = fetch1(ret2p.Quadrant(key),'folder');
            
            tuple = key;
            
            file = getLocalPath(fullfile(path,folder,'image.ibw'));
            if exist(file,'file')
                y = IBWread(file);
                tuple.image = y.y;
            end
            
            file = getLocalPath(fullfile(path,folder,'Roi.ibw'));
            if exist(file,'file')
                y = IBWread(file);
                tuple.roi = y.y;
                tuple.roi(tuple.roi==1)=0;
                tuple.roi = abs(tuple.roi);
            end
            
            file = getLocalPath(fullfile(path,folder,'Cells.ibw'));
            y = IBWread(file);
            tuple.pixel_length = y.y(1,6);
            tuple.pixel_area = tuple.pixel_length^2;
            
            
            self.insert(tuple);
        end
    end
    
end
