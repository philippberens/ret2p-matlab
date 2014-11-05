%{
ret2p.QuadrantInfo (imported) # info about quadrants

-> ret2p.Quadrant
---
offset_x = 0   : float                  # offset of the quadrant in microns
offset_y = 0   : float                  # offset of the quadrant in microns
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
            target = fetch1(ret2p.Dataset(key),'target');
            
            % offset
            file = 'Cells.ibw';
            
            if exist(getLocalPath(fullfile(path,folder,file)),'file') && ...
                    strcmp(target,'RGC')
                y = IBWread(getLocalPath(fullfile(path,folder,file)));
                pos = y.y(:,4:5);
            else
                pos = [0 0];
            end
            
            pos = mean(pos,1);
            
            % fill tuple
            tuple = key;
            tuple.offset_x = pos(1);
            tuple.offset_y = pos(2);
            
            self.insert(tuple);
            
            makeTuples(ret2p.Sim,key)           
            
        end
    end
    
end
