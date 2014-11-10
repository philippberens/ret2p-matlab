%{
ret2p.QuadrantInfo (imported) # info about quadrant

-> ret2p.Quadrant
---
offset_x = 0   : float                  # offset of the scan in microns
offset_y = 0   : float                  # offset of the scan in microns
orientation=null            : longblob          # upper, lower, right, left border
nt_pos=null                 : double        # nasal-temporal position
dv_pos=null                 : double        # dorso-ventral position
        
%}

classdef QuadrantInfo < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.QuadrantInfo');
        popRel = ret2p.Quadrant;
    end
    
    methods
        function self = QuadrantInfo(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            path = fetch1(ret2p.Dataset(key),'path');
            folder = fetch1(ret2p.Quadrant(key),'folder');
            
            % bipolar cell terminals
            if strcmp(fetch1(ret2p.Dataset(key),'target'),'BC_T')
                file = getLocalPath(fullfile(path,'FieldPosition.ibw'));
                if exist(file,'file')
                    y = IBWread(file);
                    dv_pos = y.y(key.quadrant_num+1,1);
                    nt_pos = y.y(key.quadrant_num+1,2);
                    orientation = y.y(key.quadrant_num+1,3:end);
                end
                pos = [0 0];
                
            % ganglion cell cell bodies
            elseif strcmp(fetch1(ret2p.Dataset(key),'target'),'RGC_CB')
                
                % field offset
                file = getLocalPath(fullfile(path,folder,'Cells.ibw'));
                if exist(file,'file')
                    y = IBWread(file);
                    pos = y.y(:,4:5);
                    pos = mean(pos,1);
                end
                
                % field position
                file = getLocalPath(fullfile(path,'FieldPosition.ibw'));
                if exist(file,'file')
                    y = IBWread(file);
                    dv_pos = y.y(1);
                    nt_pos = y.y(2);
                    orientation = y.y(3:end);
                end
                
            end      
            
            
            % fill tuple
            tuple = key;
            tuple.offset_x = pos(1);
            tuple.offset_y = pos(2);
            if exist('orientation','var')
                tuple.orientation = orientation;
                tuple.nt_pos = nt_pos;
                tuple.dv_pos = dv_pos;
            end
            self.insert(tuple);
        end
    end
    
end
