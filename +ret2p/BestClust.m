%{
ret2p.BestClust (imported) # clustering based on features

-> ret2p.ClustSet

---
model           : longblob          # clustering model
bic             : float             # BIC of model
posterior       : longblob          # posterior of model
max_posterior   : longblob          # maximal posterior
assignment      : longblob          # cluster idx
clust_date      : date              # date

%}

classdef BestClust < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.BestClust');
        popRel = ret2p.ClustSet;
    end
    
    methods
        function self = BestClust(varargin)
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
            
            
            bic = fetchn(ret2p.Clust(key),'bic');
            [minBIC, idx] = min(bic);
            
            clustKeys = fetch(ret2p.Clust(key));
            optKey = clustKeys(idx);

            
            %% fill tuple
            tuple = key;
            tuple.model = fetch1(ret2p.Clust(optKey),'model');
            tuple.bic = minBIC;
            tuple.posterior = fetch1(ret2p.Clust(optKey),'posterior');
            tuple.max_posterior = max(tuple.posterior,[],2);
            tuple.assignment = fetch1(ret2p.Clust(optKey),'assignment');      
            tuple.clust_date = fetch1(ret2p.Clust(optKey),'clust_date');
            
            self.insert(tuple);
            
            relROIs = ret2p.ROISetMember(key) & 'is_member=1';
            newkey = fetch(self * relROIs & key);
            
            for i=1:length(newkey)
                disp(i)
                k = newkey(i);
                k.clust_idx = tuple.assignment(i);
                k.posterior = tuple.max_posterior(i);
                
                makeTuples(ret2p.ClustAssignment,newkey(i))
                
                
            end
            
            
        end
        
        
        
        
    end
end


