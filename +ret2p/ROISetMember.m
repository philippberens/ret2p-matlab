%{
ret2p.ROISetMember (imported) # Collects ROIs present at a given date

-> ret2p.ROISet
-> ret2p.ROI
---
is_member=0     : tinyint(1)              # true if ROI in set
%}

classdef ROISetMember < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.ROISetMember');
        popRel = ret2p.ROI * ret2p.ROISet;
    end
    
    methods
        function self = ROISetMember(varargin)
            self.restrict(varargin{:})
        end
    end
    %
    methods(Access = protected)
        function makeTuples(self, key)
            
            restrict = fetch1(ret2p.ROISet,'restrict');
            ds_key = fetch(ret2p.Dataset(key) & restrict);
            
            if ~isempty(ds_key)
                is_member = true;
            else 
                is_member = false;
            end
                
            
            
            % fill tuple
            tuple = key;
            tuple.is_member = is_member;
          
            self.insert(tuple);
        end
    end
    
end
