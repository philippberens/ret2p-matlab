%{
ret2p.FeatBasis (imported) # Features for clustering and other things

-> ret2p.FeatType
-> ret2p.FeatStim
---

basis           : longblob  # basis function
mean            : longblob  # mean across dataset
sd              : longblob  # sd across dataset
varexp          : longblob  # variance explained by basis functions

%}

classdef FeatBasis < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.FeatBasis');
    end
    
    methods
        function self = FeatBasis(varargin)
            self.restrict(varargin{:})
        end
        
        
        function makeTuples(self, key)
            
            stim = fetch1(ret2p.FeatStim(key),'feat_stim');
            
            feat_type = fetch1(ret2p.FeatTypeParams(key),'feat_type_key');
            
            
            switch lower(stim)
                case {'step','chirp','bg','localchirp'}
                    relTrace = ret2p.Trace * ret2p.Stimulus ...
                        * ret2p.TraceSetMember & sprintf('stim_type="%s"',stim);
                    data = fetchn(relTrace, 'mean_trace');
                    data = cat(2,data{:});
                    
                case 'dn'
                    relRF =ret2p.TraceRf * ret2p.TraceRfParams* ...
                        ret2p.TraceSetMember(key) & 'rf_param_key="der_nmm"';
                    data = fetchn(relRF, 'tc');
                    data = cat(2,data{:});
                    
            end
            
            target = unique(fetchn(ret2p.Dataset * ret2p.ROISet(key),'target'));
            assert(numel(target)==1,'No multiple recording targets allowed in one ROI set.')
            if strcmp(target,'BC_T')
                relStep = ret2p.Trace * ret2p.Stimulus ...
                    * ret2p.TraceSetMember & 'stim_type="Step"';
                qi = fetchn(relStep, 'quality');
            elseif strcmp(key.roi_set_target,'RGC_CB')
                relStep = ret2p.Trace * ret2p.Stimulus ...
                    * ret2p.TraceSetMember & 'stim_type="Step"';
                qi = fetchn(relStep, 'quality');
            end
            
            switch feat_type
                case 'pca'
                    [basis, m, s, v] = feat_pca;
                case 'spca'
                    [basis, m, s, v] = feat_spca;
                otherwise
                    error('not implemented yet')
            end
            
            % fill tuple
            tuple = key;
            tuple.basis = basis;
            tuple.mean = m;
            tuple.sd = s;
            tuple.varexp = v;
            self.insert(tuple);
            
            % functions for computing features
            function [basis, m, s, v] = feat_pca
                
                selIdx = qi>.2;
                [coeff, ~, v] = pca(data(:,selIdx)');
                basis = coeff(:,1:min(20,size(coeff,2)));
                
                m = mean(data(:,selIdx),2);
                s = std(data(:,selIdx),[],2);
                
                v = cumsum(v(1:20))/sum(v);
                
            end
            
            function [basis, m, s, v] = feat_spca
                
                addpath(getLocalPath('\lab\libraries\spasm\'))
                
                selIdx = qi>.2;
                
                switch lower(stim)
                    case {'chirp','localchirp'}
                        nNonZero = 50;
                        nComp = 20;
                    case 'step'
                        nNonZero = 20;
                        nComp = 20;
                    case 'dn'
                        nNonZero = 10;
                        nComp = 10;
                end
                
                X = data(:,selIdx)';
                m = mean(X,1);
                s = std(X,[],1);
                
                X = bsxfun(@rdivide,bsxfun(@minus,X,m),s);
                [basis, v] = spca(X,[],nComp,inf,-nNonZero);
                
                v = cumsum(v(1:20))/sum(v);
                
                rmpath(getLocalPath('\lab\libraries\spasm\'))
            end
        end
    end
    
end

