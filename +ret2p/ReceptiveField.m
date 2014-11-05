%{
ret2p.ReceptiveField (imported) # receptive field using dense noise

-> ret2p.Traces
---

rf          : longblob  # receptive field, smoothed
rf_raw      : longblob  # receptive field, unsmoothed
rf_std      : longblob  # receptive field map, std over time
time_course : longblob  # time course of activiation, 1SD of center
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

classdef ReceptiveField < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.ReceptiveField');
        popRel = ret2p.Traces & ret2p.Stimuli('stim_type="DN"');
    end
    
    methods
        function self = ReceptiveField(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self,filter)
            
            if nargin > 1
                self.restrict(filter);
            end
            T = fetch(self,'*');
            figure
            
            for t = 1:length(T)
                time = T(t).time;
                
                % plot OFF receptive field
                subplot(1,3,1)
                map = T(t).rf_std;
                imagesc(T(t).x,T(t).y,(map-median(map(:)))/max(map(:)-median(map(:))),[0 1])
                colormap gray
                hold on
                if T(t).quality<0.8
                    h = plotGauss(T(t).m,diag(T(t).s.^2),1,'r');
                    set(h,'color','r')
                    plot(T(t).m(1),T(t).m(2),'r+')
                end
                text(600,100,sprintf('qi = %1.2f \nsz = %d \nar = %1.2f', ...
                    T(t).quality,round(T(t).size),T(t).aspect_ratio),'fontsize',7,'color','w')
                formatSubplot(gca,'xl','microns', ...
                    'yl','microns','ax','normal', ...
                    'DataAspectRatio',[1 1 1])
                set(gca,'PlotBoxAspectRatio',[400 300 1])
                
                
                % plot time course
                subplot(1,3,2)
                plot(time,T(t).time_course,'k'), hold on
                line([time(end) time(1)],[1 1],'color',[0.7 0.7 0.7])
                line([time(end) time(1)],[-1 -1],'color',[0.7 0.7 0.7])
                formatSubplot(gca,'xl','Time from stimulus onset (s)', ...
                    'yl','Response (z-score)','lim',[time(end) time(1) ...
                    -5 5],'ax','normal')
                set(gca,'PlotBoxAspectRatio',[400 300 1])
                
                % plot surround
                subplot(1,3,3)
                [xx yy] = meshgrid(T(t).x,T(t).y);
                xx = [xx(:) yy(:)];
                d = pdist2(xx,T(t).m','mahalanobis',diag(T(t).s.^2));
                plot(d,T(t).rf_std(:),'k.','markersize',1)
                hold on
                plot(T(t).rad_bins,T(t).rad,'r')
                formatSubplot(gca,'xl','Distance from center (s.d.)', ...
                    'yl','RF Amplitude (z-score)','lim',[0 T(t).rad_bins(end) ...
                    0 2],'ax','normal')
                set(gca,'PlotBoxAspectRatio',[400 300 1])
                
                pause
                clf
                
            end
            
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get mean trace
            dnStim = ret2p.Stimuli('stim_type="DN"');
            [dtrace t_time] = fetch1(ret2p.Traces(key) & dnStim,'dt_trace','time');
            
            % get stimulus
            [stim s_time] = fetch1(ret2p.StimInfo(key) & dnStim,'stim','time');
            stim = reshape(stim,[],size(stim,3));
            
            % interpolate trace
            dt = diff(s_time(1:2))/10;
            %             dt = diff(s_time(1:2));
            s_time_hr = s_time(1):dt:s_time(end);
            dtrace = interp1(t_time,dtrace,s_time_hr);
            stim = interp1(s_time,stim',s_time_hr,'nearest')';
            stim = stim-mean(stim(:));
            
            % find peaks
            sd = nanmedian(abs(dtrace))/0.6745;
            zs = (dtrace-nanmean(dtrace))/sd;
            [pk,loc]=findpeaks(zs,'minpeakheight',1);
            
            % compute event triggered average & zscore
            b_idx = 20;
            a_idx = 60;
            S =  b_idx + a_idx;
            pk(loc<=a_idx)=[];
            loc(loc<=a_idx)=[];
            pk(loc>size(stim,2)-b_idx)=[];
            loc(loc>size(stim,2)-b_idx)=[];
            
            tstim = zeros(size(stim,1),S,length(loc));
            for i=1:length(loc)
                tstim(:,:,i) = pk(i)*stim(:,(loc(i)-a_idx+1):loc(i)+b_idx);
            end
            mtstim = mean(tstim,3);
            sd = median(abs(mtstim(:)))/0.6745;
            zs = (mtstim(:)-mean(mtstim(:)))/sd;
            rf_raw = reshape(zs,size(mtstim,1),size(mtstim,2));
%             rf_raw = permute(reshape(rf_raw,20,15,[]),[2 1 3]);
            rf_raw = flipdim(reshape(rf_raw,20,15,[]),1);
            clear tstim mtstim
            
            
            %% smooth receptive field
            w = window(@gausswin,5);
            w = w * w';
            w = w / sum(w(:));
            
            rf = zeros(size(rf_raw));
            for i=1:S
                rf(:,:,i) = imfilter(rf_raw(:,:,i),w,'circular');   % smooth for fitting
            end
            rf_std = std(rf,[],3);
            
            
            
            %% fitting
            
            dmu = 40;
            [xo yo] = fetchn(ret2p.ScanInfo(key),'offset_x','offset_y');
            y = dmu/2 : dmu : 20*dmu; y = y - (y(1)+y(end))/2; y = y + yo;
            x = dmu/2 : dmu : 15*dmu; x = x - (x(1)+x(end))/2; x = x + xo;
            [xx yy] = meshgrid(x,y);
            xx = [xx(:) yy(:)];
            
            % 2d gaussian
            gauss2d = @(par,arg) par(1) + par(2) * ...
                exp(-(arg(:,1)-par(3)).^2/par(4)^2 - ...
                (arg(:,2)-par(5)).^2/par(6)^2);
            opt = optimset('Display','off','MaxFunEvals',1e4,'MaxIter',1e4);
            
            % initialize gaussian
            p(1) = median(rf_std(:));
            if max(abs(rf_std(:)))>max(rf(:))
                p(2) = min(rf_std(:))-median(rf_std(:));
            else
                p(2) = max(rf_std(:))-median(rf_std(:));
            end
            [~, p(3)]=max(max(abs(rf_std),[],1)); p(3) = x(p(3));
            p(4) = 2*dmu;
            [~, p(5)]=max(max(abs(rf_std),[],2)); p(5) = y(p(5));
            p(6) = 2*dmu;
            
            % fit
            p = lsqcurvefit(gauss2d,p,xx,rf_std(:),[],[],opt);
            
            %% compute parameters
            rf_std = rf_std - p(1);
            
            v1=var(gauss2d(p,xx)-rf_std(:));
            v2=var(rf_std(:));
            
            m = [p(3); p(5)];
            s = [p(4); p(6)];
            
            % quality index: error variance by total variance, per frame
            var_ratio = v1./v2;
            
            % receptive field size
            rf_size = sqrt(pi*prod(s));
            
            % time course in rf (8 closest pixels to center averaged)
            d = pdist2(xx,m','mahalanobis',diag(s.^2));
            [dd, dnx] = sort(d,'ascend');
            foo = reshape(rf_raw,300,80);
            w = exp(-dd(1:8)); w = w/sum(w(:)); 
            tc = w'*foo(dnx(1:8),:);
            
            % radial rf shape
            rad1 = rf_std(:);
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
            tuple.rf_raw = rf_raw;
            tuple.rf_std = rf_std;
            tuple.time_course = tc;
            tuple.m = m;
            tuple.s = s;
            tuple.x = x;
            tuple.y = y;
            tuple.time = fliplr(-b_idx*dt:dt:(S-21)*dt) + diff(s_time(1:2))/2;
            tuple.quality = var_ratio;
            tuple.size = rf_size;
            tuple.aspect_ratio = aspect_ratio;
            tuple.rad_bins = bins;
            tuple.rad = rad;
            
            self.insert(tuple);
        end
    end
    
end

