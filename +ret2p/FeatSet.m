%{
ret2p.FeatSet (imported) # Features for clustering and other things

-> ret2p.ROISet
-> ret2p.FeatSetParams
---

feat            : longblob  # feature value
basis           : longblob  # basis function
quality=null    : longblob  # some measure of feature quality


%}

classdef FeatSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.FeatSet');
        popRel = ret2p.ROISet * ret2p.FeatSetParams;
    end
    
    methods
        function self = FeatSet(varargin)
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
            
            [stim, param_key] = fetch1(ret2p.FeatSetParams(key),'stim','param_key');
            
            
            relROIs = ret2p.ROISetMember(key) & 'is_member=1';
            
            
            switch lower(stim)
                case {'step','chirp','bg'}
                    relTrace = ret2p.Trace & relROIs & ...
                        ret2p.Stimulus(sprintf('stim_type="%s"',stim));
                    data = fetchn(relTrace, 'mean_trace');
                    data = cat(2,data{:});
                    
                    relStep = ret2p.Trace & relROIs & ...
                        ret2p.Stimulus('stim_type="Step"');
                    qi = fetchn(relStep, 'quality');
                    
                case 'rf'
                    relRF = ret2p.CaRF & relROIs;
                    data = fetchn(relRF, 'tc');
                    
                    relStep = ret2p.Trace & relROIs & ...
                        ret2p.Stimulus('stim_type="Step"');
                    qi = fetchn(relStep, 'quality');
            end
            
            switch param_key
                case 'bc_pca'
                    [feat, basis, quality] = feat_bc_pca;
                    
                otherwise
                    error('not implemented yet')
            end

            % fill tuple
            tuple = key;
            
            tuple.feat = feat;
            tuple.basis = basis;
            if exist('quality','var')
                tuple.quality = quality;
            end
            
            self.insert(tuple);
            
            % functions for computing features
            function [feat, basis, quality] = feat_bc_pca
                
                selIdx = qi>.3;
                coeff = princomp(data(:,selIdx)');
                basis = coeff(:,1:20);
                
                feat = basis' * data;

                % use weight in sparse regression for depth 
                % as quality measure
                depth = fetchn(ret2p.ROI & relROIs,'depth');
                X = zscore(feat(:,selIdx)');
                y = zscore(depth(selIdx));
                [b, fitinfo] = lasso(X,y,'CV',10,'alpha',1);
                quality = abs(b(:,fitinfo.Index1SE));
                
                
                
            end
        end
    end
    
end

