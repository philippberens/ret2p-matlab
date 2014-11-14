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
        function self = FeatTyper(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self,filter)
            
            if nargin > 1
                self.restrict(filter);
            end
            T = fetch(self,'*');
            
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            self.insert(key)
            
            stims = fetchn(ret2p.Stimulus & ret2p.ROISetMember(key),'stim_type');
            uStims = unique(stims);
            
            quads = fetch(ret2p.Quadrant & ret2p.ROISetMember(key));
            nQ = length(quads);
            
            for i=1:length(uStims)
                if sum(strcmp(uStims{i},stims))== nQ
                    newKey = key;
                    stim_num = fetch1(ret2p.FeatStim & ...
                        sprintf('feat_stim="%s"', uStims{i}),'feat_stim_num');
                    newKey.feat_stim_num=stim_num;
                    
                    makeTuples(ret2p.Feat,newKey)
                end
                
            end
            
            
        end
    end
    
end

