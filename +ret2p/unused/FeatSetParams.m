%{
ret2p.FeatSetParams (manual) # List of parameter sets for caRF

feat_set_num    : tinyint unsigned  # number of parameter set
stim            : enum("Chirp","RF","Step","DS","BG")    # which traces
---
feat_key       : enum("bc_pca")   # key for parameter set
%}

classdef FeatSetParams < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.FeatSetParams');
    end
    
    methods 
        function self = FeatSetParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
