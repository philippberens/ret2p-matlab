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
        popRel = ret2p.CaRFp * (ret2p.Trace & ret2p.Stimulus('stim_type="DN"'));
    end
    
    methods
        function self = CaRF(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self,filter)
            
            if nargin > 1
                self.restrict(filter);
            end
            T = fetch(self,'*');
            f = Figure(1, 'size', [100 50]);
            
            for t = 1:length(T)
                time = T(t).time;
                
                % plot receptive field
                subplot(1,3,1)
                map = T(t).map;
                imagesc(T(t).y,T(t).x,map')
                colormap gray
                hold on
                if T(t).quality<0.8
                    h = plotGauss(flipud(T(t).m),diag(flipud(T(t).s.^2)),1,'r');
                    set(h,'color','r')
                    plot(T(t).m(2),T(t).m(1),'r+')
                end
                formatSubplot(gca,'xl','microns', ...
                    'yl','microns','ax','normal', ...
                    'DataAspectRatio',[1.3 1 1])
                set(gca,'PlotBoxAspectRatio',[400 300 1])
                
                
                % plot time course
                subplot(1,3,2)
                plot(time,T(t).tc,'k'), hold on
                line([time(end) time(1)],[0 0],'color',[0.7 0.7 0.7])
                formatSubplot(gca,'xl','Time from stimulus onset (s)', ...
                    'yl','Response ','lim',[time(end) time(1) ...
                    -.7 .7],'ax','normal')
                set(gca,'PlotBoxAspectRatio',[400 300 1])
                
                % plot surround
                subplot(1,3,3)
                [xx, yy] = meshgrid(T(t).x,T(t).y);
                xx = [xx(:) yy(:)];
                d = pdist2(xx,T(t).m','mahalanobis',diag(T(t).s.^2));
                plot(d,T(t).map(:),'k.','markersize',1)
                hold on
                plot(T(t).rad_bins,T(t).rad,'r')
                formatSubplot(gca,'xl','Distance from center (s.d.)', ...
                    'yl','RF Amplitude','lim',[0 T(t).rad_bins(end) ...
                    0 .6],'ax','normal')
                set(gca,'PlotBoxAspectRatio',[400 300 1])
                
                f.cleanup();
                pause
                clf
                
            end
            
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            param_key = fetch1(ret2p.CaRFp(key),'param_key');
            switch param_key
                case 'der_sta'
                    [rf, map, tc, time] = rf_der_sta(ret2p.CaRF,key);
                    
                otherwise
                    error('not implemented yet')
            end
            

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
            foo = reshape(rf,300,80);
            w = exp(-dd(1:8)); w = w/sum(w(:));
            tc2 = w'*foo(dnx(1:8),:);
            
            % radial rf shape
            rad1 = map(:);
            bins = 0:.25:10;
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
                        ret2p.Stimulus('stim_type="DN"'),'mean_trace','time');
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
            
            % extract time and space kernels with svd
            [U,~,V] = svd(reshape(rf,[],length(rf)));
            tc = V(:,1);
            map = reshape(U(:,1),size(rf,1),size(rf,2));
            
            % adjust sign
            [~, i] = max(abs(map(:)));
            s = sign(map(i));
            map = map*s;
            tc = tc*s;
            
            
        end
    end
    
end

