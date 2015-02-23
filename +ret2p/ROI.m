%{
ret2p.ROI (imported) # List of rois to analyze

-> ret2p.Quadrant
roi_num        : int unsigned      # number of cell
---
pos_x=null                  : float      # x-coordinate of roi pos
pos_y=null                  : float      # y-coordinate of roi pos
depth=null                  : float      # depth of ROI
area2d                      : float      # 2D size
area3d=null                 : float      # 3D area
volume=null                 : float      # 3D volume
ephys=0                     : int        # are spikes present
tp=1                        : int        # are two photon traces present
ephys_idx=null              : int        # index into spike files
%}

classdef ROI < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.ROI');
        popRel = ret2p.Quadrant;
    end
    
    methods
        function self = ROI(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            [path, target, data_type] = ...
                fetch1(ret2p.Dataset(key),'path','target','data_type');
            folder = fetch1(ret2p.Quadrant(key),'folder');
            
            % roi info
            y = IBWread(getLocalPath(fullfile(path,folder,'Cells.ibw')));
            nCells = size(y.y,1);
            
            switch target
                case 'RGC_CB'
                    
                    pos = y.y(:,4:5);  % position of cells
                    scale = y.y(1,6);
                    
                    % 2d/3d cell info
                    y2 = IBWread(getLocalPath(fullfile(path,folder,'info_3D_ROIs.ibw')));
                    area2d = y2.y(:,1) * scale^2;
                    area3d = y2.y(:,4);
                    volume = y2.y(:,3);
                    
                case 'BC_T'
                    pos = [y.y(:,10) y.y(:,11)] ; 
                    depth = y.y(:,5); % in microns
                    
                    y2 = IBWread(getLocalPath(fullfile(path,folder,'Roi.ibw')));
                    rois = y2.y;
                    
                    area2d = zeros(size(y.y,1),1);
                    for i=1:size(y.y,1)
                        area2d(i) = sum(rois(:)==-i)*y.y(1,6)^2;
                    end
                    
            end
            
            
            % simultaneous recordings / spike recordings
            if strcmp(data_type,'sim')
                assert(exist(getLocalPath(fullfile(path,folder,'sim.txt')),'file'),'missing sim.txt')
                y = load(getLocalPath(fullfile(path,folder,'sim.txt')));
                ephys_ids = y(:,2);
                twop_ids = y(:,1);
            end
            
            % prepare key
            key.date = key.date; %#ok<*AGROW>
            key.quadrant_num = key.quadrant_num;
            key.qset = key.qset;
            key.mouse_id = key.mouse_id;
            
            % enter cells
            for i=1:nCells
                fprintf('Adding roi %d.\n',i)
                tuple = key;
                tuple.roi_num = i;
                tuple.pos_x = pos(i,1);
                tuple.pos_y = pos(i,2);
                tuple.area2d = area2d(i);
                
                if exist('depth','var')
                    tuple.depth = depth(i);
                end
                
                
                if exist('area3d','var')
                    tuple.area3d = area3d(i);
                    tuple.volume = volume(i);
                end
                
                switch data_type
                    case '2p'
                        tuple.tp = 1;
                        tuple.ephys = 0;
                    case 'sp'
                        tuple.tp = 0;
                        tuple.ephys = 1;
                    case 'sim'
                        idx = twop_ids==i;
                        if any(idx)
                            tuple.ephys_idx = ephys_ids(idx);
                            tuple.ephys = 1;
                        else
                            tuple.ephys = 0;
                        end
                end
                
              
                self.insert(tuple);
            end
        end
        
    end
end
