%{
ret2p.CentSurrChirpPrediction (imported) # receptive field using ring flicker

-> ret2p.CentSurr
---




%}

classdef CentSurrChirpPrediction < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.CentSurrChirpPrediction');
        popRel = ret2p.CentSurr;
    end
    
    methods
        function self = CentSurrChirpPrediction(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self)
            key = fetch(self);
            
            f = Figure(1,'size',[100 120]);
            
            
            for i=1:length(key)
                
                f.cleanup()
                pause
                clf
            end
            
            
            
            
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get center and surround kernels
            [center, surround, time] = ...
                fetch1(ret2p.CentSurr(key),'center','surround','time');
            
%             center = center - mean(center(time<0.015));
%             surround = surround - mean(surround(time<0.015));
            
            if key.param_set_num == 2
                center = center(time>0);
                surround = surround(time>0);
                time = time(time>0);
            elseif key.param_set_num == 1
                center = fliplr(center(time>0));
                surround = fliplr(surround(time>0));
                time = fliplr(time(time>0));
            end
            
            
            % get chirp traces for local and global chirp
            chirpKey = rmfield(key,'stim_num');
            [gChirp, gTime] = fetch1(ret2p.Stimulus * ret2p.Trace(chirpKey) & ...
                'stim_type="Chirp"','mean_trace','time');
            lChirp = fetch1(ret2p.Stimulus * ret2p.Trace(chirpKey) & ...
                'stim_type="LocalChirp"','mean_trace');
            
            % get stimulus
            [stim, sTime] = fetch1(ret2p.Stimulus * ret2p.StimInfo(chirpKey) & ...
                'stim_type="Chirp"','stim','time');
            
            stim = stim / max(stim);
            
            % all to same sampling rate
            %             gChirp =  interp1(gTime,gChirp,sTime);
            %             lChirp =  interp1(gTime,lChirp,sTime);
            stim =  interp1(1/1.03125*sTime,stim,gTime);
            
            dt = diff(gTime(1:2));
            iTime = time(1):dt:time(end);
            center = interp1(time,center,iTime);
            surround = interp1(time,surround,iTime);
            
            center = center/sum(abs(center));
            surround = surround/sum(abs(surround));
            
            pred = zeros(1,length(stim));
            fL = length(center);
            
            if key.param_set_num == 2
                center = fliplr(center)';
                surround = fliplr(surround)';
            
            elseif key.param_set_num == 1
                center = fliplr(center)';
                surround = fliplr(surround)';
            end
            
            for i=fL+1:length(stim)
                pred(i) = stim(i-fL:i-1)'*center/mean(abs(center));
            end
            
            
            
            param_key = fetch1(ret2p.CentSurrParams(key),'param_key');
            
            
            %% fill tuple
            tuple = key;
            tuple.rf = rf;
            tuple.time = time;
            tuple.center = center;
            tuple.surround = surround;
            tuple.cs_delay = cs_delay;
            tuple.cs_ratio = cs_ratio;
            tuple.profiles = profiles;
            tuple.lin_sep = lin_sep;
            
            
            self.insert(tuple);
        end
        
    end
    
end

