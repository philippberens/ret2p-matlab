%{
ret2p.DirSel (imported) # direction selectivity

-> ret2p.Traces
contrast        : float     # contrast
---
ds_index        : float     # direction selectivity index
os_index        : float     # orientation selectivity index
pref_dir        : float     # preferred direction
pref_ori        : float     # preferred orientation
curve_par       : longblob  # parameters of tuning function

time_course     : longblob  # time course extracted by SVD
tuning_curve    : longblob  # tuning function extraced by SVD

ctrace          : longblob # centered trace
sv              : float     # singular value
ds_p              : float     # p-value for direction tuning
os_p              : float     # p-value for direction tuning
svd_u            : longblob  # SVD resulting matrix U
svd_s            : longblob  # SVD resulting matrix S
svd_v            : longblob  # SVD resulting matrix V


%}

classdef DirSel < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.DirSel');
        popRel = ret2p.Traces & ret2p.Stimuli('stim_type="DS" or stim_type="DS50"');
    end
    
    methods
        function self = DirSel(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self,filter)
            
            if nargin > 1
                self.restrict(filter);
            end
            T = fetch(self,'*');
            figure
            
            for t = 1:length(T)
                dsStim = ret2p.Stimuli('stim_type="DS" or stim_type="DS50"');
                dir = fetch1(ret2p.StimInfo(T(t)) & dsStim,'stim');
                dir = unique(dir);
                
                x = T(t).tuning_curve;
                
                % tuning curve
                dd = 0:.01:2*pi;
                %                 f = @(p,theta) exp(p(1) + p(2) * (cos(theta - p(4)) - 1) ...
                %                     + p(3) * (cos(2 * (theta - p(4))) - 1));
                f = @(p,theta) p(1) + p(2)*exp(p(3)*(cos(theta-p(4))-1)) + ...
                    p(5)*exp(p(3)*(cos(theta-p(4)+pi)-1));
                
                xx = f(T(t).curve_par,dd);
                
                % polar plot of data
                polar(dir,x/max(x),'sk'), hold on
                polar(dd,xx/max(x),'k:')
                
                formatSubplot(gca)
                
                % plot of mean resultant vector
                zm = T(t).ds_index * exp(1i*T(t).pref_dir);
                plot([0 real(zm)], [0, imag(zm)], 'r', 'linewidth',2)
                %                 if T(t).ds_index>.4
                %                     line(mod([T(t).pref_dir T(t).pref_dir],2*pi),[1 1.1],'color','r')
                %                 end
                
                % add text
                
                text(5.4,1.3,sprintf('ds index = %1.2f\nos index = %1.2f\nquality = %1.2f', ...
                    T(t).ds_index,T(t).os_index,fetch1(ret2p.Traces(T(t),dsStim),'quality')), ...
                    'fontsize',8)
                title(sprintf('date: %s, scan: %d, cell: %d',...
                    T(t).date,T(t).scan_num,T(t).cell_num));
                
                pause
                clf
                
            end
        end
        
        function plotDetails(self,filter)
            
            if nargin > 1
                self.restrict(filter);
            end
            T = fetch(self,'*');
            figure
            
            for t = 1:length(T)
                
                dsStim = ret2p.Stimuli('stim_type="DS"');
                dir = fetch1(ret2p.StimInfo(T(t)) & dsStim,'stim');
                dir = unique(dir);
                
                %                 trace = fetch1(ret2p.Traces(T(t)) & dsStim,'mean_trace');
                trace = T(t).ctrace;
                
                x = T(t).tuning_curve;
                
                % tuning curve
                dd = 0:.01:2*pi;
                f = @(p,theta) p(1) + p(2)*exp(p(3)*(cos(theta-p(4))-1)) + ...
                    p(5)*exp(p(3)*(cos(theta-p(4)+pi)-1));
                xx = f(T(t).curve_par,dd);
                
                % plot response
                subplot(2,2,1)
                dt=1/7.8;
                tt=dt:dt:size(trace,1)*dt;
                imagesc(1:8,tt,trace)
                colormap gray
                formatSubplot(gca,'xl','Direction','yl','Time (s)')
                
                
                % plot reconstruction
                subplot(2,2,2)
                rec = T(t).svd_u(:,1)*T(t).svd_v(:,1)';
                imagesc(1:8,tt,rec)
                colormap gray
                formatSubplot(gca,'xl','Direction','yl','Time (s)')
                
                % plot tuning curve
                subplot(2,2,3)
                plot(dir,x/max(x),'r.')
                hold on
                plot(dd,xx/max(x),'k')
                xlim([0 2*pi])
                ylim([-.1 1.3])
                formatSubplot(gca,'xl','Direction')
                
                % plot time course
                subplot(2,2,4)
                plot(tt,T(t).time_course,'k')
                axis square
                formatSubplot(gca,'xl','Time (s)', 'yl','Activity')
                ylim([-.5 1.1])
                xlim([tt(1) tt(end)])
                
                suptitle(sprintf('date: %s, scan: %d, cell: %d, dsip=%.2f, osp=%.2f',...
                    T(t).date,T(t).scan_num,T(t).cell_num,T(t).ds_p,T(t).os_p));
                
                pause
                clf
                
            end
            
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get mean trace
            dsStim = ret2p.Stimuli('stim_type="DS" or stim_type="DS50"');
            sets = fetch(ret2p.Traces(key) & dsStim);
            
            for sIdx=1:length(sets)
                trace = fetch1(ret2p.Traces(sets(sIdx)),'mean_trace');
                trace = bsxfun(@minus,trace, mean(trace(1:6,:)));
                trace = trace./max(abs(trace(:)));
                
                traceByTrial = fetch1(ret2p.Traces(sets(sIdx)),'trace_by_trial');
                                            
                % get stimulus
                dir = fetch1(ret2p.StimInfo(sets(sIdx)) & dsStim,'stim');
                dir = unique(dir);
                
                % statistics
                [U,S,V] = svd(trace);
                
                sv = sign(mean(sign(V(:,1))));
                if  mean((-1*U(:,1)-mean(trace(:,1),2)).^2) <  ...
                        mean((U(:,1)-mean(trace(:,1),2)).^2)
                    su = -1;
                else
                    su = 1;
                end
%                 su = sign(mean(sign(U(10:30,1))));
                if sv==1 && su==1
                    s = 1;
                elseif sv==-1 && su==-1
                    s = -1;
                elseif sv==1 && su==-1
                    s = 1;
                elseif sv==0
                    s = su;
                else
                    s = 1;
                end
                
                x = s * V(:,1);
                x = x - min(x);
                x = x/max(x);
                
                tc = s * U(:,1);
                tc = tc - mean(tc(1:7));
                tc = tc/max(abs(tc));
                
                xx = zeros(size(traceByTrial,2),size(traceByTrial,3));
                for i=1:size(traceByTrial,3)
                    xx(:,i) = tc'*traceByTrial(:,:,i);
                end
                
                 % circular shifted trace
                [~, idx] = max(x);
                ctrace = circshift(trace,[0 4-idx]);
%                 x = circshift(x,[0 4-idx]);
                                
                % ds/os indices
                ds_index = circ_r(dir,x,diff(dir(1:2)));
                ds_p = testTuning(dir,xx',1);
                pref_dir = circ_mean(dir,x);
                
                os_index = circ_r(2*dir,x,2*diff(dir(1:2)));
                os_p = testTuning(dir,xx',2);
                pref_ori = circ_mean(2*dir,x);
                
%                 [rp idx] = max(x);
%                 xc = circshift(x,4);
%                 rn = xc(idx);
%                 dir_index =  (rp-rn)/(rp+rn);
%                 
%                 [rp idx] = max(x);
%                 xc = circshift(x,2);
%                 rn = xc(idx);
%                 ori_index =  (rp-rn)/(rp+rn);
%                 
                % fit tuning functions
                %             f = @(p,theta) p(1)*exp(p(2) * (cos(theta - p(4)) - 1) ...
                %                 + p(3) * (cos(2 * (theta - p(4))) - 1));
                f = @(p,theta) p(1) + p(2)*exp(p(3)*(cos(theta-p(4))-1)) + ...
                    p(5)*exp(p(3)*(cos(theta-p(4)+pi)-1));
                
                [~, maxDir] = max(x);
                par = [0,1, 1/diff(dir(1:2)), dir(maxDir),0];
                
                opt = optimset;
                opt.MaxFunEvals = 1000;
                opt.Display = 'off';
                opt.MaxIter = 10000;
                par = lsqcurvefit(f,par,dir,x,[0 0 0 -inf 0],[inf 1.5 inf inf 1.5],opt);
                
                % frequency
                f = abs(fft(x));
                f = f(1:3)/f(1);
                
                % fill tuple
                tuple = key;
                tuple.ds_index = ds_index;
                tuple.os_index = os_index;
                tuple.pref_dir = pref_dir;
                tuple.pref_ori = pref_ori;
                tuple.curve_par = par;
                tuple.sv = S(1)/sum(diag(S));
                tuple.time_course = tc;
                tuple.tuning_curve = x;
                tuple.svd_u = U;
                tuple.svd_v = V;
                tuple.svd_s = diag(S);
                tuple.ctrace = ctrace;
                tuple.ds_p = ds_p;
                tuple.os_p = os_p;
                
                tuple.contrast = 100;
                if sets(sIdx).stim_num==5
                    tuple.contrast = 50;
                end
                tuples(sIdx) = tuple;
            end
            
            self.insert(tuples);
        end
    end
    
    
end



