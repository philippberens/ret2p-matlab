%{
ret2p.ROISetMember (imported) # Collects ROIs present at a given date

-> ret2p.ROISet
-> ret2p.ROI
---
%}

classdef ROISetMember < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.ROISetMember');
    end
    
    methods
        function self = ROISetMember(varargin)
            self.restrict(varargin{:})
        end
    end
    %
    methods(Access = protected)
 
    end
    
end
