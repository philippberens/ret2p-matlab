%{
ret2p.ColorPref (imported) # color preference

-> ret2p.Traces
---
color_index     : float     # standard index; idx>0  means green preference
color_index_on  : float     # standard index; idx>0  means green preference
color_index_off : float     # standard index; idx>0  means green preference
color_opp       : float     # standard index; idx>0  means green preference
color_index2     : float     # standard index; idx>0  means green preference
color_index_on2  : float     # standard index; idx>0  means green preference
color_index_off2 : float     # standard index; idx>0  means green preference
color_opp2       : float     # standard index; idx>0  means green preference
mean_trace      : longblob  # response trace to blue green stim
qi  : float     # quality index

%}

classdef ColorPref < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.ColorPref');
        popRel = ret2p.Traces & ret2p.Stimuli('stim_type="GB"');
    end
    
    methods
        function self = ColorPref(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self,filter)
            
            if nargin > 1
                self.restrict(filter);
            end
            T = fetch(self,'*');
            figure
            
            for t = 1:length(T)
                gbStim = ret2p.Stimuli('stim_type="GB"');
                [stim,stime] = fetch1(ret2p.StimInfo(T(t)) & gbStim,'stim','time');
                %                 [trace t_time] = fetch1(ret2p.Traces(T(t)) & gbStim,'mean_trace','time');
                
                
                figure
                %                 plot(stime,stim(:,1),'g')
                %                 hold on
                %                 plot(stime,stim(:,2),'b')
                plot(T(t).mean_trace,'k'), hold on
                plot(gradient(T(t).mean_trace).^2,'r')
                
                %                 formatSubplot(gca,'xl','Time (s)','lim',[stime(1) stime(end) -.7 1.1])
                axis normal
                
                
                % add text
                l = axis;
                text(8,0.5,sprintf('ON = %1.2f\nOFF = %1.2f\nOPP = %1.2f\n', ...
                    T(t).color_index_on,T(t).color_index_off, T(t).color_opp),'fontsize',8)
                title(sprintf('date: %s, scan: %d, cell: %d',...
                    T(t).date,T(t).scan_num,T(t).cell_num));
                
                pause
                clf
                
            end
        end
        
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get mean trace
            gbStim = ret2p.Stimuli('stim_type="GB"');
            [trace t_time] = fetch1(ret2p.Traces(key) & gbStim,'mean_trace','time');
            trace_by_trial = fetch1(ret2p.Traces(key) & gbStim,'trace_by_trial');
            
            % get stimulus
            [stim s_time] = fetch1(ret2p.StimInfo(key) & gbStim,'stim','time');
            
            % downsample stimulus
            stim = interp1(s_time,stim,t_time,'nearest');
            
            % compute response
            win = 2:12;
 
            gOn = find(diff(stim(:,1))==1);
            gOff = find(diff(stim(:,1))==-1);
            bOn = find(diff(stim(:,2))==1);
            bOff = find(diff(stim(:,2))==-1);
            
            
            f = @(d) var(mean(d,2),[],1)/mean(var(d,[],1),2);
            
            %
            gtrace = gradient(trace).^2;
            gOnMax = max(gtrace(gOn+win));
            bOnMax = max(gtrace(bOn+win));
            gOffMax = max(gtrace(gOff+win));
            bOffMax = max(gtrace(bOff+win));
            dOnIdx = (gOnMax-bOnMax)/(gOnMax+bOnMax);
            dOffIdx = (gOffMax-bOffMax)/(gOffMax+bOffMax);
            if bOnMax+gOnMax>bOffMax+gOffMax
                d_color_index = dOnIdx;
            else
                d_color_index = dOffIdx;
            end
            
            dColorOpp = (max(gOnMax*bOffMax,bOnMax*gOffMax) - ...
                max(gOnMax*bOnMax,bOffMax*gOffMax))/...
                (max(gOnMax*bOffMax,bOnMax*gOffMax) + ...
                max(gOnMax*bOnMax,bOffMax*gOffMax));
            
            gtrace = trace.^2;
            gOnMax = max(gtrace(gOn+win));
            bOnMax = max(gtrace(bOn+win));
            gOffMax = max(gtrace(gOff+win));
            bOffMax = max(gtrace(bOff+win));
            onIdx = (gOnMax-bOnMax)/(gOnMax+bOnMax);
            offIdx = (gOffMax-bOffMax)/(gOffMax+bOffMax);
            if bOnMax+gOnMax>bOffMax+gOffMax
                color_index = onIdx;
            else
                color_index = offIdx;
            end
            
            colorOpp = (max(gOnMax*bOffMax,bOnMax*gOffMax) - ...
                max(gOnMax*bOnMax,bOffMax*gOffMax))/...
                (max(gOnMax*bOffMax,bOnMax*gOffMax) + ...
                max(gOnMax*bOnMax,bOffMax*gOffMax));
            
            
            % fill tuple
            tuple = key;
            tuple.color_index = color_index;
            tuple.color_index_on = onIdx;
            tuple.color_index_off = offIdx;
            tuple.color_opp = colorOpp;
            
            tuple.color_index2 = d_color_index;
            tuple.color_index_on2 = dOnIdx;
            tuple.color_index_off2 = dOffIdx;
            tuple.color_opp2 = dColorOpp;
            tuple.mean_trace = trace;
            tuple.qi = f(trace_by_trial);
            
            self.insert(tuple);
        end
    end
    
end

