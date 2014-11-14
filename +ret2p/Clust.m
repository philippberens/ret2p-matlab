%{
ret2p.Clust (imported) # clustering based on features

-> ret2p.ClustSet
-> ret2p.ClustParams

---
model           : longblob          # clustering model
bic             : float             # BIC of model
posterior       : longblob          # posterior of model
max_posterior   : longblob          # maximal posterior
assignment      : longblob          # cluster idx
clust_date      : date              # date

%}

classdef Clust < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.Clust');
        popRel = ret2p.ClustSet * ret2p.ClustParams;
    end
    
    methods
        function self = Clust(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self,filter)
            
            if nargin > 1
                self.restrict(filter);
            end
            T = fetch(self,'*');
            f = Figure(1, 'size', [100 50]);
            
            
            
            
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            rng(42);
            
            feat = fetchn(ret2p.Feat(key),'feat');
            feat = cat(1,feat{:});
            quality = fetchn(ret2p.Feat(key),'quality');
            quality = cat(1,quality{:});
            
            relROIs = ret2p.ROISetMember(key) & 'is_member=1';
            
            if strcmp(key.roi_set_target,'BC_T')
                relStep = ret2p.Trace & relROIs & ...
                    ret2p.Stimulus('stim_type="Step"');
                qi = fetchn(relStep, 'quality');
            elseif strcmp(key.roi_set_target,'RGC_CB')
                relStep = ret2p.Trace & relROIs & ...
                    ret2p.Stimulus('stim_type="Chirp"');
                qi = fetchn(relStep, 'quality');
            end
            
            selIdx = qi>.3;
            
            feat = feat(quality>0,selIdx)';
            
            opt = statset('MaxIter',500);
            gm=gmdistribution.fit(feat,key.ncomp,'regularize',key.ridge, ...
                'CovType', key.cov_type,'Options',opt,'Replicates',1);
            
            posterior = NaN(size(qi,1),key.ncomp);
            posterior(selIdx,:) = gm.posterior(feat);
            
            clusterIdx = NaN(size(qi,1),1);
            clusterIdx(selIdx) = gm.cluster(feat);
            
            
            %% fill tuple
            tuple = key;
            tuple.model = struct(gm);
            tuple.bic = gm.BIC;
            tuple.posterior = posterior;
            tuple.max_posterior = max(posterior,[],2);
            tuple.assignment = clusterIdx;      
            tuple.clust_date = datestr(date,'yyyy-mm-dd');
            
            self.insert(tuple);
            
            
            
            
        end
        
        
        
        
    end
end


