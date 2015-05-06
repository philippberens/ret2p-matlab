%{
ret2p.CentSurr (imported) # receptive field using ring flicker

-> ret2p.Trace
-> ret2p.CentSurrParams
---

rf          : longblob  # receptive field, smoothed
time        : longblob  # time of time kernel
cs_delay    : float     # timing difference center - surround
cs_ratio    : float     # center surround sd ratio
center      : longblob  # center time course
surround    : longblob  # surround time course

%}

classdef CentSurr < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.CentSurr');
        popRel = ret2p.CentSurrParams * ret2p.Trace * ...
            ret2p.Stimulus & 'stim_type="RingFlicker"';
    end
    
    methods
        function self = CentSurr(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self)
            
            
            
            
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            param_key = fetch1(ret2p.CentSurrParams(key),'param_key');
            switch param_key
                case 'der_sta'
                    [rf, center, surround, time] = rf_der_sta(ret2p.CentSurr,key);
                    
                case 'der_nmm'
                    [rf, center, surround, time] = rf_der_nmm(ret2p.CentSurr,key);
                    
                otherwise
                    error('not simplemented yet')
            end
            
            cs_ratio = std(center)/std(surround);
            [~,idx1] = max(abs(center));
            [~,idx2] = max(abs(surround));
            cs_delay =  time(idx1) - time(idx2);
            
            %% fill tuple
            tuple = key;
            tuple.rf = rf;
            tuple.time = time;
            tuple.center = center;
            tuple.surround = surround;
            tuple.cs_delay = cs_delay;
            tuple.cs_ratio = cs_ratio;
            tuplep.profiles = profiles;
            
            
            self.insert(tuple);
        end
        
        function [rf, center, surround, profiles, time] = rf_der_sta(~,key)
            
            % implements simple rf mapping via thresholding
            
            % get  trace
            switch fetch1(ret2p.Dataset(key),'target')
                case 'BC_T'
                    [dtrace, t_time] = fetch1(ret2p.Trace(key) & ...
                        ret2p.Stimulus('stim_type="RingFlicker"'),'mean_trace','time');
                otherwise
                    [dtrace, t_time] = fetch1(ret2p.Trace(key) & ...
                        ret2p.Stimulus('stim_type="RingFlicker"'),'dt_trace','time');
            end
            
            % get stimulus
            [stim, s_time] = fetch1(ret2p.StimInfo(key) & ...
                ret2p.Stimulus('stim_type="RingFlicker"'),'stim','time');
            
            stim = stim-mean(stim(:));
            stim = stim';
            dt = diff(s_time(1:2));
            
            % find peaks
            dtrace = dtrace - nanmean(dtrace);
            sd = nanmedian(abs(dtrace))/0.6745;
            zs = dtrace/sd;
            [pk,loc]=findpeaks(zs,'minpeakheight',1);
            
            % compute event triggered average & zscore
            b_idx = 50;
            a_idx = 300;
            S =  b_idx + a_idx;
            time = fliplr(-(b_idx)*dt:dt:(a_idx-1)*dt) + dt/2;
            pk(loc<=a_idx)=[];
            loc(loc<=a_idx)=[];
            pk(loc>size(stim,2)-b_idx)=[];
            loc(loc>size(stim,2)-b_idx)=[];
            
            tstim = zeros(size(stim,1),S,length(loc));
            for i=1:length(loc)
                tstim(:,:,i) = pk(i)*stim(:,(loc(i)-a_idx+1):loc(i)+b_idx);
            end
            mtstim = mean(tstim,3);
            clear tstim
            mtstim = mtstim-mean(mtstim(:));
            sd = median(abs(mtstim(:)))/0.6745;
            rf_raw = mtstim/sd;
            clear mtstim
            
            % smooth receptive field
            w = window(@gausswin,25)';
            w = w / sum(w(:));
            
            rf = zeros(size(rf_raw));
            for i=1:size(rf,1)
                rf(i,:) = imfilter(rf_raw(i,:),w);   % smooth for fitting
            end
            
            s = std(rf,[],2);
            [~,idx] = max(s);
            center = rf(idx,:);
            
            surround = mean(rf(min(idx+(3:5),size(rf,1)),:));
            
            
        end
        
        function [rf, center, surround, profiles, time] = rf_der_nmm(~,key)
            
            % implements rf mapping via optimizing model using NMM toolbox
            % by Dan Butts and Co
            
            addpath(getLocalPath('/lab/libraries/NIMtoolbox/'))
            addpath(getLocalPath('/lab/libraries/NMM/'))
            addpath(getLocalPath('/lab/libraries/minFunc_2012/minFunc/'))
            addpath(getLocalPath('/lab/libraries/minConf/minConf/'))
            addpath(getLocalPath('/lab/libraries/minConf/minFunc/'))
            addpath(genpath(getLocalPath('/lab/libraries/L1General/')))
            
            % get  trace
            [dtrace, ~] = fetch1(ret2p.Trace(key) & ...
                ret2p.Stimulus('stim_type="RingFlicker"'),'dt_trace','time');
            
            ds = 5; % downsample factor
            
            % process trace
            dtrace = dtrace - nanmean(dtrace);
            sd = nanmedian(abs(dtrace))/0.6745;
            zs = dtrace/sd;
            trace = decimate(zs,ds);
          
            % process stimulus
            [stim, s_time] = fetch1(ret2p.StimInfo(key) & ...
                ret2p.Stimulus('stim_type="RingFlicker"'),'stim','time');
            
            stim = stim-mean(stim(:));
            [NT,nFreq] = size(stim);
            dt = diff(s_time(1:2))*ds;
            
            Xstim = zeros(ceil(NT/ds),nFreq);
            for i=1:nFreq
                Xstim(:,i) = decimate(stim(:,i),ds);
            end
            
            nLags = 50; % number of time lags for estimating stimulus filters
            tent_basis_spacing = 1; % represent stimulus filters using tent-bases with this spacing (in up-sampled time units)
            stim_dt = 1;
            up_samp_fac = 1;
            params_stim = NMMcreate_stim_params([nLags nFreq], stim_dt, up_samp_fac, tent_basis_spacing );
            
            Xstim = create_time_embedding(Xstim, params_stim);
            
            % fit a (regularized) GLM
            
            params_reg = NMMcreate_reg_params( 'lambda_d2X',50,'lambda_d2T',200);
            fit0 = NMMinitialize_model( params_stim, 1, {'lin'}, params_reg, 1, [], 'linear' );
            fit0 = NMMfit_filters( fit0, trace, Xstim, [],[], 1);
            
            
            rf = reshape(fit0.mods.filtK,[nLags nFreq])';
            
            s = std(rf,[],2);
            [~,idx] = max(s(1:4));
            center = rf(idx,:);
            
            surround = mean(rf(min(idx+(2:4),size(rf,1)),:));
            
            profiles = [center*rf'; surround*rf'];
            
            time = (0:dt:(nLags-1)*dt) + dt/2;
            
            rmpath(getLocalPath('/lab/libraries/NIMtoolbox/'))
            rmpath(getLocalPath('/lab/libraries/NMM/'))
            rmpath(getLocalPath('/lab/libraries/minFunc_2012/minFunc/'))
            rmpath(getLocalPath('/lab/libraries/minConf/minConf/'))
            rmpath(getLocalPath('/lab/libraries/minConf/minFunc/'))
            rmpath(genpath(getLocalPath('/lab/libraries/L1General/')))
            
            
        end
    end
    
end

