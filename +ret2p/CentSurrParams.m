%{
ret2p.CentSurrParams (manual) # List of parameter sets for center surround

param_set_num   : tinyint unsigned       # number of parameter set
---
param_key                   : enum('der_sta','der_nmm')     # key for parameter set
%}

classdef CentSurrParams < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.CentSurrParams');
    end
    
    methods 
        function self = CentSurrParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
