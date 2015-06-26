%{
ret2p.FeatStim (manual) # 

feat_stim_num   : tinyint unsigned      # number of parameter set
---
stim_type       : enum('Chirp','DN','Step','DS','LocalChirp')  # stims
%}

classdef FeatStim < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.FeatStim');
    end
    
    methods 
        function self = FeatStim(varargin)
            self.restrict(varargin{:})
        end
    end
end
