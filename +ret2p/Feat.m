%{
ret2p.Feat (imported) # Features for clustering and other things

-> ret2p.FeatType
-> ret2p.FeatStim
---

feat            : longblob  # feature value
basis           : longblob  # basis function
quality=null    : longblob  # some measure of feature quality


%}

classdef Feat < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.Feat');
        %         popRel = ret2p.ROISet * ret2p.FeatSetParams;
    end
    
    methods
        function self = Feat(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self,filter)
            
            if nargin > 1
                self.restrict(filter);
            end
            T = fetch(self,'*');
        end
        
        function makeTuples(self, key)
            
            stim = fetch1(ret2p.FeatStim(key),'feat_stim');
            
            feat_type = fetch1(ret2p.FeatTypeParams(key),'feat_type_key');
            
            relROIs = ret2p.ROISetMember(key) & 'is_member=1';
            
            
            switch lower(stim)
                case {'step','chirp','bg','localchirp'}
                    relTrace = ret2p.Trace & relROIs & ...
                        ret2p.Stimulus(sprintf('stim_type="%s"',stim));
                    data = fetchn(relTrace, 'mean_trace');
                    data = cat(2,data{:});
                    
                    
                    
                case 'dn'
                    relRF = ret2p.CaRF & relROIs;
                    data = fetchn(relRF, 'tc');
                    data = cat(2,data{:});
                    
                    
            end
            
            if strcmp(key.roi_set_target,'BC_T')
                relStep = ret2p.Trace & relROIs & ...
                    ret2p.Stimulus('stim_type="Step"');
                qi = fetchn(relStep, 'quality');
            elseif strcmp(key.roi_set_target,'RGC_CB')
                relStep = ret2p.Trace & relROIs & ...
                    ret2p.Stimulus('stim_type="Chirp"');
                qi = fetchn(relStep, 'quality');
            end
            
            switch feat_type
                case 'pca'
                    [feat, basis, quality] = feat_pca;
                case 'spca'
                    [feat, basis, quality] = feat_spca;
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
            function [feat, basis, quality] = feat_pca
                
                selIdx = qi>.3;
                coeff = princomp(data(:,selIdx)');
                basis = coeff(:,1:20);
                
                feat = basis' * data;
                
                % use weight in sparse regression for depth
                % as quality measure
                if strcmp(key.roi_set_target,'BC_T')
                    depth = fetchn(ret2p.ROI & relROIs,'depth');
                    X = zscore(feat(:,selIdx)');
                    y = zscore(depth(selIdx));
                    [b, fitinfo] = lasso(X,y,'CV',10,'alpha',1);
                    quality = abs(b(:,fitinfo.Index1SE));
                else
                    quality = nan*ones(1,size(feat,1));
                end
                
            end
            
            function [feat, basis, quality] = feat_spca
                
                addpath('Z:\lab\libraries\matlablib\spasm\')
                
                selIdx = qi>.3;
                
                
                
                switch lower(stim)
                    case {'chirp','localchirp'}
                        nNonZero = 50;
                        nComp = 20;
                    case 'step'
                        nNonZero = 20;
                        nComp = 20;
                    case 'dn'
                        nNonZero = 10;
                        nComp = 20;
                end
                
                basis = spca(data(:,selIdx)',[],nComp,inf,-nNonZero);
                
                feat = basis' * data;
                
                % use weight in sparse regression for depth
                % as quality measure
                if false
                    depth = fetchn(ret2p.ROI & relROIs,'depth');
                    X = zscore(feat(:,selIdx)');
                    y = zscore(depth(selIdx));
                    [b, fitinfo] = lasso(X,y,'CV',10,'alpha',1);
                    quality = abs(b(:,fitinfo.Index1SE));
                else
                    quality = nan*ones(1,size(feat,1));
                end
                
                rmpath('Z:\lab\libraries\matlablib\spasm\')
            end
        end
    end
    
end

