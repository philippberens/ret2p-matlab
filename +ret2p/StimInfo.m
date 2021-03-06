%{
ret2p.StimInfo (imported) # Stimulus

-> ret2p.DrugTreatment
---
stim                : longblob               # stimulus trace or frames
time                : longblob               # time vector
sampling_rate = 0   : float                  # sampling rate in Hz
spatial_sz = null   : float                  # spatial size of stim
       
%}

classdef StimInfo < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.StimInfo');
        popRel = ret2p.DrugTreatment;
    end
    
    methods 
        function self = StimInfo(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            stimType = lower(fetch1(ret2p.Stimulus(key),'stim_type'));
            
            switch lower(fetch1(ret2p.DrugTreatment(key),'drug_type'))
                case 'none'
                    file = fetch1(ret2p.Stimulus(key),'stim_file');                    
                otherwise
                    file = fetch1(ret2p.Stimulus(key),'stim_file');
                    folder = fetch1(ret2p.DrugTreatment(key),'folder');
                    k = strfind(file,'\');
                    file = [file(1:k(end)) folder '\' file(k(end)+1:end)];   
            end
            
            if ~strcmp(stimType,'ringflicker')
                y = IBWread(getLocalPath(file));
            else
                y = [];
            end
            
            
            % process stimulus
            switch stimType
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
                    
                case {'chirp','localchirp','surroundchirp'}
                    % for all other stimuli, time and sr are available
                    s = y.y;
                    sr = 1/y.dx;
                    time = 0:y.dx:(length(s)*y.dx);
                    time = time(1:end-1)';
                    spatial_sz = 500;
                    
                case {'ff100', 'ff500'} 
                    s = y.y;
                    sr = 1000/y.dx;
                    time = 0:y.dx:(size(s,1)-1)*y.dx;
                    
%                     y = IBWread(getLocalPath([file(1:end-12) 'Stim_timing.ibw']));
%                     time = (time + y.y(1))/1000;                    
                case 'step'
                    s = y.y;
                    sr = 1/y.dx;
                    time = 0:y.dx:(length(s)-1)*y.dx; 
                    
                case 'ringflicker'
                    idx = strfind(file,'\');
                    path = getLocalPath(file(1:idx(end)));
                    dl = dir(path);
                    idx = strncmp('RingFlicker_Stimulus',{dl.name},17);
                    
                    dl = dl(idx);
                    
                    y = IBWread([path dl(1).name]);
                    s = zeros(size(y.y,1),length(dl));
                    for i=1:length(dl)
                        y = IBWread([path dl(i).name]);
                        s(:,i) = y.y;                        
                    end
                    
                    sr = 1000/y.dx;
                    time = 0:y.dx:(size(s,1)-1)*y.dx;

                    y = IBWread([path 'RingFlicker_Stim_Timing.ibw']);
                    time = (time + y.y(1))/1000;
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
