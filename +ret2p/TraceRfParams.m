%{
ret2p.TraceRfParams (manual) # List of parameter sets for caRF$
rf_param_num   : tinyint unsigned       # number of parameter set
---
rf_param_key                   : enum('der_sta','der_nmm')     # key for parameter set
%}

classdef TraceRfParams < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.TraceRfParams');
    end
    
    methods 
        function self = TraceRfParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
