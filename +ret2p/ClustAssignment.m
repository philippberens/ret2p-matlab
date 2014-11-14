%{
ret2p.ClustAssignment(imported) # Collects ROIs present at a given date

-> ret2p.BestClust
-> ret2p.ROI
---
is_member=0     : tinyint(1)              # true if ROI in set
clust_idx=Null  : int                     # cluster index
posterior=Null  : float                   # posterior
%}

classdef ClustAssignment < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.ClustAssignment');
        %         popRel = ret2p.ROI * ret2p.ROISet;
    end
    
    methods
        function self = ClustAssignment(varargin)
            self.restrict(varargin{:})
        end
        
        %
        function makeTuples(self, key)
            
            
            
            
            % fill tuple
            tuple = key;
            
            tuple.is_member = 1;
            
            self.insert(tuple);
            
        end
        
    end
end
