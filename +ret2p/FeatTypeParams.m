%{
ret2p.FeatTypeParams (manual) # List of parameter sets for caRF

feat_type_num    : tinyint unsigned  # number of parameter set
---
feat_type_key    : enum("pca")   # key for parameter set
%}

classdef FeatTypeParams < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.FeatTypeParams');
    end
    
    methods 
        function self = FeatTypeParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
