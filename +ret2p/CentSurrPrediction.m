%{
ret2p.CentSurrPrediction (imported) # receptive field using ring flicker

-> ret2p.CentSurr
---
yy_all              : longblob               # predicted trace with all rings
yy_center           : longblob               # predicted trace with center rings
y                   : longblob               # real trace
c_all               : float                  # correlation between real and predicted
c_center            : float                  # dito
w_all               : longblob               # learned weights
w_center            : longblob               # learned weights
%}

classdef CentSurrPrediction < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.CentSurrPrediction');
        popRel = ret2p.CentSurr;
    end
    
    methods
        function self = CentSurrPrediction(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self)
            key = fetch(self);
            
            f = Figure(1,'size',[100 120]);
            
            
            for i=1:length(key)
                
                f.cleanup()
                pause
                clf
            end
            
            
            
            
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            
            % get  trace
            [dtrace, t_time] = fetch1(ret2p.Trace(key) & ...
                ret2p.Stimulus('stim_type="RingFlicker"'),'mean_trace','time');
            dtrace2 = resample(dtrace,1,10);
            
            % get stimulus
            [stim, s_time] = fetch1(ret2p.StimInfo(key) & ...
                ret2p.Stimulus('stim_type="RingFlicker"'),'stim','time');
            stim2 = resample(stim,1,10);
            
            % fetch 
            rf = fetch1(ret2p.CentSurr(key),'rf');
            [~, idx] = max(max(abs(rf')));
            idx = unique(max(idx+ (-1:1),1));
            
            X_all = [];
            dT = 20;
            for j=1:dT 
                X_all =[X_all stim2((dT-j+1):(end-j+1),:)]; 
            end
            
            X_center = [];
            dT = 20;
            for j=1:dT, X_center =[X_center stim2((dT-j+1):(end-j+1),idx)]; end
            
            y = dtrace2(dT:end);
            yy_center = zeros(size(y));
            yy_all = zeros(size(y));
            
            T = size(X_all,1);            
            nSplits = 2;
            sT = floor(T/nSplits);
            
            idx = 1:T;
            for i=1:nSplits
                idxTest = idx((1:sT)+(i-1)*sT);
                idxTrain = setdiff(idx,idxTest);
                
                % full model
                lm = fitglm(X_all(idxTrain,:),y(idxTrain));
                
                w_all(:,:,i) = reshape(lm.Coefficients.Estimate(2:end),[],dT);
             
                yy_all(idxTest) = predict(lm,X_all(idxTest,:));
                
                % restricted model
                lm = fitglm(X_center(idxTrain,:),y(idxTrain));
                
                w_center(:,:,i) = reshape(lm.Coefficients.Estimate(2:end),[],dT);
                
                yy_center(idxTest) = predict(lm,X_center(idxTest,:));

            end
            
            c_all = corr(y,yy_all);
            c_center = corr(y,yy_center);
            
            
            %% fill tuple
            tuple = key;
            tuple.yy_center = yy_center;
            tuple.yy_all = yy_all;
            tuple.c_all = c_all;
            tuple.c_center = c_center;
            tuple.w_all = w_all;
            tuple.w_center = w_center;
            tuple.y = y;
            
            
            
            self.insert(tuple);
        end
        
      
        
    end
    
end

