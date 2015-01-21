%{
ret2p.ROISet (manual) # Enter date

roi_set_num         : smallint          # number of set
roi_set_target      : varchar(255)      # target
roi_set_start_date  : date                  # date after which datasets are included
roi_set_stop_date   : date                  # date before which datasets are included
---
note            : varchar(1000)         # notes
restrict=null   : varchar(255)          # restrictions which ROIs to include

%}

classdef ROISet < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.ROISet');
    end
    
    methods 
        function self = ROISet(varargin)
            self.restrict(varargin{:})
        end
    end
end
