%{
ret2p.TraceSetMember (imported) # Collects ROIs present at a given date

-> ret2p.ROISet
-> ret2p.Trace
---
%}

classdef TraceSetMember < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.TraceSetMember');
    end
    
    methods
        function self = TraceSetMember(varargin)
            self.restrict(varargin{:})
        end
    end
    %
    methods(Access = protected)
 
    end
    
end
