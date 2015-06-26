%{
ret2p.FeatType (imported) # Features for clustering and other things

-> ret2p.ROISet
-> ret2p.FeatTypeParams
---

%}

classdef FeatType < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.FeatType');
        popRel = ret2p.ROISet * ret2p.FeatTypeParams;
    end
    
    methods
        function self = FeatType(varargin)
            self.restrict(varargin{:})
        end
        
        
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            self.insert(key)
            
            stims = fetchn(ret2p.ROI * ret2p.Stimulus & ret2p.ROISetMember,'stim_type');
%             uStims = unique(stims);

            pStims = fetchn(ret2p.FeatStim,'feat_stim');
            
            roiKeys = fetch(ret2p.ROI & ret2p.ROISetMember);
            N = length(roiKeys);
            
            for i=1:length(pStims)
                if sum(strcmp(pStims{i},stims))== N
                    disp(pStims{i})
                    newKey = key;
                    stim_num = fetch1(ret2p.FeatStim & ...
                        sprintf('feat_stim="%s"', pStims{i}),'feat_stim_num');
                    newKey.feat_stim_num=stim_num;
                    
                    makeTuples(ret2p.FeatBasis,newKey)
                end
                
            end
            
            
        end
    end
    
end

