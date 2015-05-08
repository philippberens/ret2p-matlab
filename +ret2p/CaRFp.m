%{
ret2p.CaRFp (manual) # List of parameter sets for caRF$
param_set_num   : tinyint unsigned       # number of parameter set
---
param_key                   : enum('der_sta','der_nmm')     # key for parameter set
%}

classdef CaRFp < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.CaRFp');
    end
    
    methods 
        function self = CaRFp(varargin)
            self.restrict(varargin{:})
        end
    end
end
