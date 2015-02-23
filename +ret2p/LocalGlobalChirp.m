%{
ret2p.LocalGlobalChirp (imported) # receptive field using dense noise

-> ret2p.Trace
---

mean_diff       : longblob  # difference in means, z-scored
mod_idx          : float     # modulation index
mod_idx_on        : float     # modulation index
mod_idx_off       : float     # modulation index
mod_idx_f         : float     # modulation index
mod_idx_c         : float     # modulation index
loc_f            : longblob  # local smoothed frequency part
glo_f            : longblob  # global smoothed frequency part
loc_c            : longblob  # local smoothed contrast part
glo_c            : longblob  # global smoothed contrast part
loc_spectrogram : longblob # spectromgram
glo_spectrogram : longblob # spectromgram
f               : longblob # frequencies
t               : longblob # times
loc_power       : longblob # power estimate
glo_power       : longblob # power estimate
loc_glo_corr    : float     # correlation between global and local

%}

classdef LocalGlobalChirp < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.LocalGlobalChirp');
        popRel = ret2p.Trace & ret2p.Stimulus('stim_type="LocalChirp"');
    end
    
    methods
        function self = LocalGlobalChirp(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self,filter)
            
            if nargin > 1
                self.restrict(filter);
            end
            T = fetch(self,'*');
            f = Figure(1, 'size', [100 50]);
            
            for t = 1:length(T)

            end
            
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            localChirp = fetch1(ret2p.Trace(key),'mean_trace');
            globalChirp = fetch1(ret2p.Trace(rmfield(key,'stim_num')) & ...
                ret2p.Stimulus('stim_type="Chirp"'), 'mean_trace');
            
            % calculate difference between global and local
            meanDiff = globalChirp - localChirp;
            noiseSd = median(abs(meanDiff(1:100)))/.6745;
            meanDiffZ = (meanDiff - mean(meanDiff(1:100)))/noiseSd;
            
            % calculate z-scored modulation index
            modIdx = mean(abs(meanDiffZ));
            
            onIdx = 129:319;
            offIdx = 321:512;
            fIdx = 649:1150;
            cIdx = 1290:1790;
            
            modIdxOn = median(meanDiffZ(onIdx));
            modIdxOff = median(meanDiffZ(offIdx));
            modIdxF = median(meanDiffZ(fIdx));
            modIdxC = median(meanDiffZ(cIdx));
            
            % calculate difference in frequency modulation
            locS = spectrogram(localChirp(fIdx),128,120,[],64);
            locS = abs(locS);
            [gloS,f,t] = spectrogram(globalChirp(fIdx),128,120,[],64);
            gloS = abs(gloS);
            [~,ii] = min(abs(bsxfun(@minus,f,t)));

            for i=1:length(ii)
                locPower(i) = locS(ii(i),i);
                gloPower(i) = gloS(ii(i),i);
            end
            
            gloF = imfilter(abs(globalChirp(fIdx)),gausswin(101)/sum(gausswin(101)));
            locF = imfilter(abs(localChirp(fIdx)),gausswin(101)/sum(gausswin(101)));
            
            
            % calculate difference in contrast response
            gloC = imfilter(globalChirp(cIdx),gausswin(101)/sum(gausswin(101)));
            locC = imfilter(localChirp(cIdx),gausswin(101)/sum(gausswin(101)));          
            
            %% fill tuple
            tuple = key;
            tuple.mean_diff = meanDiffZ;
%             tuple.mean_diff_z = meanDiffZ;
            tuple.mod_idx = modIdx;
            tuple.mod_idx_on = modIdxOn;
            tuple.mod_idx_off = modIdxOff;
            tuple.mod_idx_f = modIdxF;
            tuple.mod_idx_c = modIdxC;
            tuple.loc_f = locF;
            tuple.glo_f = gloF;
            tuple.f = f;
            tuple.t = t; 
            tuple.loc_c = locC;
            tuple.glo_c = gloC;
            tuple.loc_spectrogram = locS;
            tuple.glo_spectrogram = gloS;
            tuple.loc_power = locPower;
            tuple.glo_power = gloPower;
            tuple.loc_glo_corr = corr(localChirp,globalChirp);
                       
            self.insert(tuple);
        end
        
        
    end
    
end

