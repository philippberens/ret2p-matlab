%{
ret2p.StimInfo (imported) # Stimulus

-> ret2p.Stimulus
---
stim                : longblob               # stimulus trace or frames
time                : longblob               # time vector
sampling_rate = 0   : float                  # sampling rate in Hz
spatial_sz = null   : float                  # spatial size of stim
       
%}

classdef StimInfo < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.StimInfo');
        popRel = ret2p.Stimulus;
    end
    
    methods 
        function self = StimInfo(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            file = fetch1(ret2p.Stimulus(key),'stim_file');
            
            y = IBWread(getLocalPath(file));

            % process stimulus
            switch lower(fetch1(ret2p.Stimulus(key),'stim_type'))
                case {'ds','ds50'} % not checked yet!
                    % for DS stimulus, each entry corresponds to 1 trial
                    s = y.y;
                    sr = 0;
                    time = 0;
                    
                case 'dn' 
                    yt = IBWread(getLocalPath([file(1:end-4) '_timing' file(end-3:end)]));
                    time = yt.y(~isnan(yt.y))/1000;
                    l = min(length(time),size(y.y,3));
                    sr = mean(1./diff(time));
                    s = y.y(:,:,1:l);
                    time = time(1:l);
                    
                    if strcmp(fetch1(ret2p.Dataset(key),'target'),'BC_T')
                        spatial_sz = 20;
                    elseif strcmp(fetch1(ret2p.Dataset(key),'target'),'RGC_CB')
                        spatial_sz = 40;
                    end
                    
                case 'gb'  % not checked yet
                    s = y.y;
                    sr = 500;
                    time = 0:1/sr:(length(s)-1)*1/sr;
                    
                case 'chirp'
                    % for all other stimuli, time and sr are available
                    s = y.y;
                    sr = 1/y.dx;
                    time = 0:y.dx:(length(s)*y.dx);
                    time = time(1:end-1)';
                    spatial_sz = 500;
                    
                case 'ff' % not checked yet
                    % replace by code to go from stim sequence to the
                    % stimulus
                    s = y.y;
                    sr = 1/100;
                    time = (0:1:length(s)-1)/100; 
                    
                case 'step'
                    s = y.y;
                    sr = 1/y.dx;
                    time = 0:y.dx:(length(s)-1)*y.dx; 
            end
            
            % fill tuple
            tuple = key;
            tuple.sampling_rate = sr;
            tuple.stim = s;
            tuple.time = time;
            if exist('spatial_sz','var')
                tuple.spatial_sz = spatial_sz;
            end
            self.insert(tuple);
        end
    end
    
end