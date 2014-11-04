%{
ret2p.Scans (manual) # List of Scans for each dataset

-> ret2p.Datasets
scan_num        : tinyint unsigned  # number of scan
---
folder          : varchar(255)      # path to files
%}

classdef Scans < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.Scans');
    end
    
    methods 
        function self = Scans(varargin)
            self.restrict(varargin{:})
        end
    end
end
