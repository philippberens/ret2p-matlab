%{
ret2p.ROISetParams (manual) # Enter date

roi_set_num   : smallint          # number of parameter set
---
roi_set_start_date  : date              # date after which datasets are included
roi_set_stop_date   : date              # date before which datasets are included
note=null           : varchar(1000)     # notes
restrict=null       : varchar(255)      # restrictions which ROIs to include (target, indicator...)
require_stim        : varchar(255)      # 
require_drug        : varchar(255)      #     
%}

classdef ROISetParams < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.ROISetParams');
    end
    
    methods 
        function self = ROISetParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
