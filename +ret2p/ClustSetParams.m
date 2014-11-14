%{
ret2p.ClustSetParams (manual) # List of parameter sets for clustering params

clust_set_num   : tinyint unsigned  # number of cluster set
---
clust_key       : enum("mog")       # key for parameter set
%}

classdef ClustSetParams < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.ClustSetParams');
    end
    
    methods 
        function self = ClustSetParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
