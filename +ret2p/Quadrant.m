%{
ret2p.Quadrant (manual) # List of Quadrants for each dataset

-> ret2p.Dataset
quadrant_num    : tinyint unsigned      # number of scan
---
folder                      : varchar(255)                  # path to files
%}

classdef Quadrant < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.Quadrant');
    end
    
    methods 
        function self = Quadrant(varargin)
            self.restrict(varargin{:})
        end
    end
end
