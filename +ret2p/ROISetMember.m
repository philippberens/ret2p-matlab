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
            
            restrict = fetch1(ret2p.ROISet(key),'restrict');
            target = fetch1(ret2p.ROISet(key), 'roi_set_target');
            start_date = fetch1(ret2p.ROISet(key), 'roi_set_start_date');
            stop_date = fetch1(ret2p.ROISet(key), 'roi_set_stop_date');
            
            filter = ['target="' target '" and date>="' ...
                start_date '" and date <"' stop_date '"'];
            
            rel = (ret2p.Dataset * ret2p.Quadrant(key) & filter);
            
            if ~isempty(restrict)
                ds_key = fetch(rel & eval(restrict));
            else
                ds_key = fetch(rel);
            end
            
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
