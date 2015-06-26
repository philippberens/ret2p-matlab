%{
ret2p.ROISet (imported) # Enter date

-> ret2p.ROISetParams
---


%}

classdef ROISet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.ROISet');
        popRel = ret2p.ROISetParams;
    end
    
    methods
        function self = ROISet(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % first insert tuple into self
            tuple = key;
            self.insert(tuple);
            
            % populate RoiSetMember table
            restrict = fetch1(ret2p.ROISetParams(key),'restrict');
            start_date = fetch1(ret2p.ROISetParams(key), 'roi_set_start_date');
            stop_date = fetch1(ret2p.ROISetParams(key), 'roi_set_stop_date');
            require_stim = fetch1(ret2p.ROISetParams(key),'require_stim');
            require_drug = fetch1(ret2p.ROISetParams(key),'require_drug');
            
            filter = [restrict ' and date>="' ...
                start_date '" and date <"' stop_date '"'];
            
            relROI = ret2p.Dataset * ret2p.ROI & filter;
            roiKey = fetch(relROI);
            
            for i=1:length(roiKey)
                
                % stimulus
                if ~isempty(require_stim)
                    s = fetch(ret2p.Stimulus(roiKey(i)) & sprintf('stim_type="%s"',require_stim));
                    stim_present = ~isempty(s);
                end
                
                % drug
                if ~isempty(require_drug)
                    s = fetch(ret2p.DrugTreatment(roiKey(i)) & sprintf('drug_type="%s"',require_drug));
                    drug_present = ~isempty(s);
                end
                
                if stim_present && drug_present
                    
                    % fill tuple
                    tuple = roiKey(i);
                    tuple.roi_set_num = key.roi_set_num;
                    
                    insert(ret2p.ROISetMember,tuple);
                end
            end
            
            % populate traceset
            if ~isempty(require_drug)
                relTrace =(ret2p.Trace * ret2p.DrugTreatment) &...
                    ret2p.ROISetMember(key) &  sprintf('drug_type="%s"',require_drug);
            else
                relTrace =(ret2p.Trace * ret2p.DrugTreatment) &...
                    ret2p.ROISetMember(key);
            end
            
            traceKey = fetch(relTrace);
            
            for i=1:length(traceKey)
                
                
                % fill tuple
                tuple = traceKey(i);
                tuple.roi_set_num = key.roi_set_num;

                insert(ret2p.TraceSetMember,tuple);

            end
            
            
            
            
            
        end
        
        
    end
end
