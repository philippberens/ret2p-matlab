%{
ret2p.Dataset (manual) # Recording in a single animal and retina

date            : date                  # date of recording
mouse_id        : double                # id of mouse
retina          : tinyint unsigned      # number of retina 
qset            : tinyint unsigned      # multiple contiguous regions
---
mouse_type="Bl/6"           : enum("Bl/6","ChATCre","PvCreTdT","PCP2TdT") # mouse line
indicator="OGB1"            : enum("OGB1","GCamp6s","GCamp6f","GCamp6m","iGluSnFr")   # indicator used in experiments
virus_type=null             : enum("ubi","flexed")          # virus type
target="RGC_CB"             : enum("RGC_CB", "BC_T")        # RGC/BCT/...
path                        : varchar(255)                  # path to files
sampling_rate=7.815         : double                        # scan rate
data_type="2p"              : enum("2p", "sp", "sim")       # which type of recording
%}

classdef Dataset < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.Dataset');
    end
    
    methods 
        function self = Dataset(varargin)
            self.restrict(varargin{:})
        end
    end
end
