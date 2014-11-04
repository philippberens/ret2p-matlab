%{
ret2p.PatchedCells (manual) # List of datasets to analyze

-> ret2p.Scans
cell_num        : tinyint unsigned              # number of cell
---
pos_x = 0       : float                         # x-coordinate of cell pos
pos_y = 0       : float                         # y-coordinate of cell pos
ipl = 0       : float                         # ipl depth
cell_type = "ganglion" : enum("ganglion","bipolar","receptor")  # cell type
%}

classdef PatchedCells < dj.Relvar 
    properties(Constant)
        table = dj.Table('ret2p.PatchedCells');
    end
    
    methods 
        function self = PatchedCells(varargin)
            self.restrict(varargin{:})
        end
    end
    
    
end
