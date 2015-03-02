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
            
            param_key = fetch1(ret2p.CentSurrParams(key),'param_key');
            switch param_key
                case 'der_sta'
                    [rf, center, surround, time] = rf_der_sta(ret2p.CentSurr,key);
                    
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

            
            self.insert(tuple);
        end
        
        function [rf, center, surround, time] = rf_der_sta(~,key)
            
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
            center = mean(rf(idx,:));

            surround = mean(rf(min(idx+(3:5),10),:));
            
            
        end
    end
    
end

