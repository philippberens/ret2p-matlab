%{
ret2p.CaRF (imported) # receptive field using dense noise

-> ret2p.Trace
-> ret2p.CaRFp
---

rf          : longblob  # receptive field, smoothed
map         : longblob  # 2D RF map
tc          : longblob  # time course of activiation, 1SD of center
tc2          : longblob  # time course of activiation, 1SD of center
m           : longblob  # mean of receptive field averaged over all clean RFs
s           : longblob  # SD of receptive field averaged over all clean RFs
y           : longblob  # y position
x           : longblob  # x position
time        : longblob  # time of time kernel
size        : float     # size of the rf
quality     : float     # quality index: variance accounted for by fit
aspect_ratio: float     # aspect ratio of SD ellipse
rad_bins    : longblob  # radial bin positions
rad         : longblob  # radial bin amplitude
%}

classdef CaRF < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.CaRF');
        popRel = (ret2p.CaRFp * ret2p.Trace) & ret2p.Stimulus('stim_type="DN"');
    end
    
    methods
        function self = CaRF(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self)
            
            key = fetch(self);
            
            f = Figure(1,'size',[80 60]);
            
            
            for i=1:length(key)
                key(i)
                [~, tc, map, time, x, y] = ...
                    fetch1(ret2p.CaRF(key(i)),'rf', 'tc', 'map', ...
                    'time', 'x', 'y');
                
                subplot(211)
                imagesc(y,x,map)
                hold on
                if fetch1(ret2p.CaRF(key(i)),'quality')<.8
                    [m, s] = fetch1(ret2p.CaRF(key(i)),'m','s');
                    h = plotGauss(m,diag(s.^2),1,'r');
                    set(h,'color','r')
                    h = plotGauss(m,diag(s.^2),2,'r');
                    set(h,'color','r','linestyle','--')
                    plot(m(1),m(2),'r+')
                end
                xlabel('\mu m')
                ylabel('\mu m')
                set(gca,'DataAspectRatio',[1.3 1 1])
                set(gca,'PlotBoxAspectRatio',[400 300 1])
                
                subplot(212)
                plot(time,tc)
                xlabel('Time (s)')
                set(gca,'ytick',[])
                
                f.cleanup();
                pause
                
                
            end
            
        end
        
        
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            param_key = fetch1(ret2p.CaRFp(key),'param_key');
            switch param_key
                case 'der_sta'
                    [rf, map, tc, time] = rf_der_sta(ret2p.CaRF,key);
                    
                case 'der_nmm'
                    [rf, map, tc, time] = rf_der_nmm(ret2p.CaRF,key);
                    
                    
                otherwise
                    error('not implemented yet')
            end
            
            [nX, nY, nT] = size(rf);
            
            
            %% fit rf with gauss
            dmu = fetch1(ret2p.StimInfo(key),'spatial_sz');
            [xo, yo] = fetchn(ret2p.QuadrantInfo(key),'offset_x','offset_y');
            y = dmu/2 : dmu : size(map,1)*dmu; y = y - (y(1)+y(end))/2; y = y + yo;
            x = dmu/2 : dmu : size(map,2)*dmu; x = x - (x(1)+x(end))/2; x = x + xo;
            [xx, yy] = meshgrid(x,y);
            xx = [xx(:) yy(:)];
            
            % 2d gaussian
            gauss2d = @(par,arg) par(1) + par(2) * ...
                exp(-(arg(:,1)-par(3)).^2/par(4)^2 - ...
                (arg(:,2)-par(5)).^2/par(6)^2);
            opt = optimset('Display','off','MaxFunEvals',1e4,'MaxIter',1e4);
            
            % initialize gaussian
            p(1) = median(map(:));
            [m, i] = max(abs(map(:)));
            p(2) = sign(map(i)) * m;
            [~, p(3)]=max(max(abs(map),[],1)); p(3) = x(p(3));
            p(4) = 2*dmu;
            [~, p(5)]=max(max(abs(map),[],2)); p(5) = y(p(5));
            p(6) = 2*dmu;
            
            % fit
            p = lsqcurvefit(gauss2d,p,xx,map(:),[],[],opt);
            
            %% compute parameters
            
            % quality index: error variance by total variance
            v1=var(gauss2d(p,xx)-map(:));
            v2=var(map(:));
            
            var_ratio = v1./v2;
            
            % receptive field parameters
            m = [p(3); p(5)];
            s = [p(4); p(6)];
            
            rf_size = pi*prod(s);
            
            % time course in rf (8 closest pixels to center averaged)
            d = pdist2(xx,m','mahalanobis',diag(s.^2));
            [dd, dnx] = sort(d,'ascend');
            foo = reshape(rf,nX*nY,nT);
            w = exp(-dd(1:8)); w = w/sum(w(:));
            tc2 = w'*foo(dnx(1:8),:);
            
            % radial rf shape
            rad1 = map(:);
            bins = 0:.2:8;
            [~, binIdx] = histc(d,bins);
            rad = zeros(size(bins));
            for i=1:length(bins)
                rad(i) = mean(rad1(binIdx==i));
            end
            
            % aspect ratio
            aspect_ratio = s(1)/s(2);
            if aspect_ratio<1
                aspect_ratio = 1/aspect_ratio;
            end
            
            %% fill tuple
            tuple = key;
            tuple.rf = rf;
            tuple.map = map;
            tuple.tc = tc;
            tuple.tc2 = tc2;
            tuple.m = m;
            tuple.s = s;
            tuple.x = x;
            tuple.y = y;
            tuple.time = time;
            tuple.quality = var_ratio;
            tuple.size = rf_size;
            tuple.aspect_ratio = aspect_ratio;
            tuple.rad_bins = bins;
            tuple.rad = rad;
            
            self.insert(tuple);
        end
        
        function [rf, map, tc, time] = rf_der_sta(~,key)
            
            % implements simple rf mapping via thresholding
            
            % get  trace
            switch fetch1(ret2p.Dataset(key),'target')
                case 'BC_T'
                    [dtrace, t_time] = fetch1(ret2p.Trace(key) & ...
                        ret2p.Stimulus('stim_type="DN"'),'dt_trace','time');
                otherwise
                    [dtrace, t_time] = fetch1(ret2p.Trace(key) & ...
                        ret2p.Stimulus('stim_type="DN"'),'dt_trace','time');
            end
            
            % get stimulus
            [stim, s_time] = fetch1(ret2p.StimInfo(key) & ...
                ret2p.Stimulus('stim_type="DN"'),'stim','time');
            stim = reshape(stim,[],size(stim,3));
            
            % interpolate trace
            dt = diff(s_time(1:2))/10;
            s_time_hr = s_time(1):dt:s_time(end);
            dtrace = interp1(t_time,dtrace,s_time_hr);
            stim = interp1(s_time,stim',s_time_hr,'nearest')';
            stim = stim-mean(stim(:));
            
            % find peaks
            dtrace = dtrace - nanmean(dtrace);
            sd = nanmedian(abs(dtrace))/0.6745;
            zs = dtrace/sd;
            [pk,loc]=findpeaks(zs,'minpeakheight',1);
            
            % compute event triggered average & zscore
            b_idx = 20;
            a_idx = 60;
            S =  b_idx + a_idx;
            time = fliplr(-b_idx*dt:dt:(S-21)*dt) + diff(s_time(1:2))/2;
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
            mtstim = mtstim(:)-mean(mtstim(:));
            sd = median(abs(mtstim(:)))/0.6745;
            zs = mtstim/sd;
            rf_raw = reshape(zs,size(mtstim,1),size(mtstim,2));
            rf_raw = flipdim(reshape(rf_raw,20,15,[]),1);
            clear mtstim
            
            
            % smooth receptive field
            w = window(@gausswin,3);
            w = w * w';
            w = w / sum(w(:));
            
            rf = zeros(size(rf_raw));
            for i=1:S
                rf(:,:,i) = imfilter(rf_raw(:,:,i),w,'circular');   % smooth for fitting
            end
            
            % generate tc/2D map from 20 most activated pixels
            rf2 = reshape(rf,[],size(rf,3));
            [~, i] = sort(abs(rf2(:)),'descend');
            [i1, ~] = ind2sub(size(rf2),i(1:30));
            
            tc = mean(rf2(unique(i1),:));
            map = reshape((tc*rf2'),size(rf,1),size(rf,2));
            
        end
        
        
        function [rf, map, tc, time] = rf_der_nmm(~,key)
            
            % implements rf mapping based on NMM model by Butts et al.
            
            addpath(getLocalPath('/lab/libraries/NIMtoolbox/'))
            addpath(getLocalPath('/lab/libraries/NMM/'))
            addpath(getLocalPath('/lab/libraries/minFunc_2012/minFunc/'))
            addpath(getLocalPath('/lab/libraries/minConf/minConf/'))
            addpath(getLocalPath('/lab/libraries/minConf/minFunc/'))
            addpath(genpath(getLocalPath('/lab/libraries/L1General/')))
            
            % get  trace
            switch fetch1(ret2p.Dataset(key),'target')
                case 'BC_T'
                    [dtrace, t_time] = fetch1(ret2p.Trace(key) & ...
                        ret2p.Stimulus('stim_type="DN"'),'dt_trace','time');
                otherwise
                    [dtrace, t_time] = fetch1(ret2p.Trace(key) & ...
                        ret2p.Stimulus('stim_type="DN"'),'dt_trace','time');
            end
            
            % get stimulus
            [stim, s_time] = fetch1(ret2p.StimInfo(key) & ...
                ret2p.Stimulus('stim_type="DN"'),'stim','time');
            [nX, nY, nT] = size(stim);
            stim = reshape(stim,[],nT);
            
            % interpolate and process trace
            dt = diff(s_time(1:2))/10;
            s_time_hr = s_time(1):dt:s_time(end);
            
            dtrace = interp1(t_time,dtrace,s_time_hr);
            dtrace = dtrace - nanmean(dtrace);
            sd = nanmedian(abs(dtrace))/0.6745;
            dtrace = dtrace/sd;
            
            % interpolate preprocess stimulus
            stim = interp1(s_time,stim',s_time_hr,'nearest')';
            stim = stim-mean(stim(:));
            
            nLags = 35;
            params_stim = NMMcreate_stim_params([nLags nX nY], 1, 1, 1 );
            
            Xstim = create_time_embedding( ...
                permute(reshape(stim,nX,nY,[]),[3 1 2]), params_stim );
            
            % initialize and fit NMM model
            params_reg = NMMcreate_reg_params('lambda_d2X',100,'lambda_d2T',100);
            
            fit = NMMinitialize_model(params_stim, 1, {'lin'}, params_reg, 1, [], 'linear' );
            fit = NMMfit_filters(fit, dtrace, Xstim, [],[], 1);
            
            rf = permute(reshape(fit.mods(1).filtK, ...
                params_stim.stim_dims), [2 3 1]);
            
            % generate tc/2D map from 20 most activated pixels
            rf2 = reshape(rf,[],size(rf,3));
            [~, i] = sort(abs(rf2(:)),'descend');
            [i1, ~] = ind2sub(size(rf2),i(1:30));
            
            tc = mean(rf2(unique(i1),:));
            %             map = reshape(mean(rf2(:,unique(i2)),2),size(rf,1),size(rf,2));
            map = reshape((tc*rf2'),nX,nY);
            
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

