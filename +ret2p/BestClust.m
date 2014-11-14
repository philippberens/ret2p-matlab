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
nclust          : int               # number of clusters

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
        
        
        function plotClustering(self,filter)
            
            if nargin > 1
                self.restrict(filter);
            end
            T = fetch(self,'*');
            f = Figure(1, 'size', [100 50]);
            
            SortedTraces = [];
            SortedRFs = [];
            SortedDS = [];
            
          
            nCellsPerClust = zeros(data.clust.K,1);
            
            for i = 1:T.nclust
                
                
                tt = data.chirp.traces(:,cI==i);
                rt = data.rf.tc(:,cI==i);
                dst = data.ds.tc(:,cI==i);
                
                p = data.info.posterior(cI==i);
                [~, bidx] = sort(p,'descend');
                SortedTraces = [SortedTraces tt(:,bidx)]; %#ok<AGROW>
                SortedRFs = [SortedRFs rt(:,bidx)]; %#ok<AGROW>
                SortedDS = [SortedDS dst(:,bidx)]; %#ok<AGROW>
                nCellsPerClust(i) = sum(cI==i);
            end
            
            f = figure;
            
            subplot(1,4,1:2)
            last = [0; cumsum(nCellsPerClust)];
            imagesc(data.chirp.time,1:sum(nCellsPerClust),SortedTraces',[-1 1])
            
            for i=1:length(data.chirp.events)
                line([data.chirp.events(i) data.chirp.events(i)],[0 sum(nCellsPerClust)],'color','k')
            end
            
            for i=2:length(nCellsPerClust)
                if nCellsPerClust(i)>0
                    line([0 data.chirp.time(end)],[last(i) last(i)],'color','k')
                end
            end
            
            formatSubplot(gca,'xl','Time (s)','tt','Chirp')
            axis normal
            tick = unique(ceil(last(1:end-1) + diff(last)/2));
            set(gca,'ytick',tick,'yticklabels',1:data.clust.K)
            
            
            subplot(1,4,3)
            imagesc(data.rf.time,1:sum(nCellsPerClust),SortedRFs',[-4 4])
            
            for i=2:length(nCellsPerClust)
                if nCellsPerClust(i)>0
                    line([data.rf.time(1) data.rf.time(end)],[last(i) last(i)],'color','k')
                end
            end
            
            formatSubplot(gca,'xl','Time (s)','tt','RF time course')
            set(gca,'ytick',tick,'yticklabel',1:data.clust.K)
            axis normal
            
            dt = 1/7.8;
            ds_time=dt:dt:size(SortedDS,1)*dt;
            
            subplot(1,4,4)
            imagesc(ds_time,1:sum(nCellsPerClust),SortedDS',[-.5 1])
            
            for i=2:length(nCellsPerClust)
                if nCellsPerClust(i)>0
                    line([ds_time(1) ds_time(end)],[last(i) last(i)],'color','k')
                    if data.clust.frac_ds(i-1) > .4
                        text(ds_time(end)+.1,(last(i)-last(i-1))/2 + last(i-1),'DS')
                    end
                    
                    %         if data.clust.frac_os(i-1) > .4
                    %             text(ds_time(end)+.1,(last(i)-last(i-1))/2 + last(i-1),'OS')
                    %         end
                    
                end
            end
            
            formatSubplot(gca,'xl','Time (s)','tt','DS response')
            set(gca,'ytick',tick,'yticklabel',1:data.clust.K)
            axis normal
            
            
            
            
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
            tuple.nclust = tuple.model.NComponents;
            
            self.insert(tuple);
            
            relROIs = ret2p.ROISetMember(key) & 'is_member=1';
            newkey = fetch(self * relROIs & key);
            
            for i=1:length(newkey)
                disp(i)
                k = newkey(i);
                k.clust_idx = tuple.assignment(i);
                k.posterior = tuple.max_posterior(i);
                
                makeTuples(ret2p.ClustAssignment,k)
                
                
            end
            
            
        end
        
        
        
        
    end
end


