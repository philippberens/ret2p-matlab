%{
ret2p.StimInfo (imported) # Trace/display for each stimulus

-> ret2p.Stimuli
---
stim                : longblob               # stimulus trace or frames
time                : longblob               # time vector
sampling_rate = 0   : float                  # sampling rate in Hz
       
%}

classdef StimInfo < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.StimInfo');
        popRel = ret2p.Stimuli;
    end
    
    methods 
        function self = StimInfo(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            path = fetch1(ret2p.Datasets(key),'path');
            file = fetch1(ret2p.Stimuli(key),'stim_file');
            
            y = IBWread(getLocalPath(fullfile(path,file)));

          
            
            % process stimulus
            switch fetch1(ret2p.Stimuli(key),'stim_type')
                case {'DS','DS50'}
                    % for DS stimulus, each entry corresponds to 1 trial
                    s = y.y;
                    sr = 0;
                    time = 0;
                case 'DN' 
                    yt = IBWread(getLocalPath(fullfile(path,[file(1:end-4) '_timing' file(end-3:end)])));
                    time = yt.y(~isnan(yt.y))/1000;
                    l = min(length(time),size(y.y,3));
                    sr = mean(1./diff(time));
                    s = y.y(:,:,1:l);
                    time = time(1:l);
                case 'GB' 
                    s = y.y;
                    sr = 500;
                    time = 0:1/sr:(length(s)-1)*1/sr;
                case 'chirp'
                    % for all other stimuli, time and sr are available
                    s = y.y;
                    sr = 1/y.dx;
                    time = 0:y.dx:y.x1;
                    time = time(1:end-1)';
                    
                case 'FF'
                    s = y.y;
                    sr = 1/100;
                    time = (0:1:length(s)-1)/100; 
            end
            
            % fill tuple
            tuple = key;
            tuple.sampling_rate = sr;
            tuple.stim = s;
            tuple.time = time;
            self.insert(tuple);
        end
    end
    
end
