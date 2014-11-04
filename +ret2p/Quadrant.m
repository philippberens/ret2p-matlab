%{
ret2p.Quadrant (manual) # List of Quadrants for each dataset

-> ret2p.Dataset
quadrant_num                : tinyint unsigned  # number of scan
---
folder                      : varchar(255)      # path to files
orientation=null            : longblob          # upper, lower, right, left border
nt_pos=null                     : double        # nasal-temporal position
dv_pos=null                     : double        # dorso-ventral position
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
