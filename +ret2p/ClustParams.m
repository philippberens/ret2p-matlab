%{
ret2p.ClustParams (manual) # List of parameter sets for clustering params

ncomp           : int               # number of clusters
ridge=1e-5      : float             # regularization of covariance
cov_type='diag' : char(25)          # type of covariance matrix
---

%}

classdef ClustParams < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.ClustParams');
    end
    
    methods 
        function self = ClustParams(varargin)
            self.restrict(varargin{:})
        end
    end
end
