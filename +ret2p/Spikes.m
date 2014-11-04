%{
ret2p.Spikes (imported) # Trace/display for each stimulus

-> ret2p.ROI
-> ret2p.Stimuli
---
sampling_rate       : float                 # sampling rate in Hz
quality=NULL        : float                 # quality index
spikes              : longblob              # all spike times
spikes_binned       : longblob              # binned spike times (ie. psth)
time                : longblob              # time vector
spikes_by_trial     : longblob              # spike times by trial
spikes_binned_by_trial : longblob           # traces by trial

%}

% THIS FUNCTION HAS NOT BEEN UPDATED YET

classdef Spikes < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.Spikes');
        popRel = ret2p.Stimuli * ret2p.ROI('ephys=1');  % needs to be tested
    end
    
    methods
        function self = Spikes(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            path = fetch1(ret2p.Datasets(key),'path');
            stim = fetch1(ret2p.Stimuli(key),'stim_type');
            scan = fetch1(ret2p.Scans(key),'folder');
            cell = sprintf('Cell%d/',key.cell_num);
            
            if strcmp(stim,'GB')
                file = getLocalPath(fullfile(path,scan,cell,sprintf('%s_spikes.ibw','BG')));
                if exist(file)
                    y = IBWread(file);
                else
                    file = getLocalPath(fullfile(path,scan,cell,sprintf('%s_spikes.ibw','colour')));
                    y = IBWread(file);
                end
                
                
            else
                file = sprintf('%s_spikes.ibw',stim);
                y = IBWread(getLocalPath(fullfile(path,scan,cell,file)));
            end
            
            
            
            % function for quality index
            f = @(d) var(mean(d,2),[],1)/mean(var(d,[],1),2);
            
            % calcium prediction
            sr = 1/0.128;
            tau = 0.7;
            t = 0:1/sr:2;
            ca = exp(-t/tau) / 100;
            
            switch stim
                case {'DS','DS50'}
                    
                    nTrials = size(y.y,2);
                    time = 0:1/sr:4;
                                        
                    data = zeros(size(time,2),nTrials);
                    for i=1:nTrials
                        spikes_raw{i} = y.y(~isnan(y.y(:,i)),i)/1000;
                        data(:,i) = histc(spikes_raw{i},time);
                    end
                    data = data(1:end-1,:);
                    time = time+1/sr/2;
                    
                    % stimuli for directions
                    stims = fetch1(ret2p.StimInfo(key),'stim');
                    ustims = sort(stims);
                    nTrials = size(data,2);
                    stims = repmat(stims,nTrials/length(stims),1);
                    
                    % sort traces after conditions
                    spikes_binned = zeros(size(data,1),length(ustims));
                    ca_trace = zeros(size(data,1),length(ustims),nTrials/length(ustims));
                    spikes_binned_by_trial = zeros(size(data,1), ...
                        length(ustims),nTrials/length(ustims));
                    qi = zeros(length(ustims),1);
                    for i=1:length(ustims)
                        idx = stims == ustims(i);
                        tmpdata = data(:,idx);
                        
                        spikes_binned(:,i) = mean(tmpdata,2);
                        spikes_binned_by_trial(:,i,:) = tmpdata;
                        spikes_by_trial(:,i) = spikes_raw(idx);
                        spikes{i} = cat(1,spikes_by_trial{:,i});
                        
                        
                        for t=1:nTrials/length(ustims)
                            ca_trace(:,i,t) = MMfunction(spikes_binned_by_trial(:,i,t),ca);
                        end
                        qi(i) = f(squeeze(ca_trace(:,i,:)));
                    end
                    ca_trace = mean(ca_trace,3);
                    qi = max(qi);
                    
                case 'GB'
                    
                    nTrials = size(y.y,2);
                    
                    time = 0:1/sr:12.5;
                    spikes_binned_by_trial = zeros(size(time,2),nTrials);
                    for i=1:nTrials
                        spikes{i} = y.y(~isnan(y.y(:,i)),i)/1000;
                        spikes_binned_by_trial(:,i) = histc(spikes{i},time);
                    end
                    time = time(1:end-1)+1/sr/2;
                    spikes_binned_by_trial = spikes_binned_by_trial(1:end-1,:);
                    
                    spikes_by_trial = spikes;
                    spikes = cat(1,spikes{:});
                    spikes_binned = mean(spikes_binned_by_trial,2);
                    
                    for t=1:nTrials
                        ca_trace(:,t) = MMfunction(spikes_binned_by_trial(:,t),ca);
                    end
                    
                    qi = f(ca_trace);
                    
                    ca_trace = mean(ca_trace,2);
%                     ca_trace = ca_trace - median(ca_trace(1:ceil(sr)),1);
                    ca_trace = ca_trace/max(abs(ca_trace));
                    
                    
                    
                case 'chirp'
                    nTrials = size(y.y,2);
                    time = 0:1/sr:32;
                    spikes_binned_by_trial = zeros(size(time,2),nTrials);
                    for i=1:nTrials
                        spikes{i} = y.y(~isnan(y.y(:,i)),i)/1000;
                        spikes_binned_by_trial(:,i) = histc(spikes{i},time);
                    end
                    time = time(1:end-1)+1/sr/2;
                    spikes_binned_by_trial = spikes_binned_by_trial(1:end-1,:);
                    
                    spikes_by_trial = spikes;
                    spikes = cat(1,spikes{:});
                    spikes_binned = mean(spikes_binned_by_trial,2);
                    
                    for t=1:nTrials
                        ca_trace(:,t) = MMfunction(spikes_binned_by_trial(:,t),ca);
                    end
                    
                    qi = f(ca_trace);
                    
                    ca_trace = mean(ca_trace,2);
                    ca_trace = ca_trace - median(ca_trace(1:ceil(sr)));
                    ca_trace = ca_trace/max(abs(ca_trace));
                    
                case 'DN'
                    % get data for cell i
                    data = y.y(~isnan(y.y(:)))/1000;
                   time = 0:1/sr:max(data)+10;
                    
                    spikes_binned = histc(data,time);
                    spikes_binned = spikes_binned(1:end-1);
                    time = time(1:end-1)+1/sr/2;
                    spikes{1} = data;
                    
                    ca_trace = MMfunction(spikes_binned,ca);
                    
                    qi = NaN;
                    spikes_binned_by_trial = NaN;
                    spikes_by_trial = NaN;
                    
                case 'FF'
                    
                    % get data for cell i
                    data = y.y(~isnan(y.y(:)))/1000;
 
                    time = 0:1/sr:max(data)+10;
                    
                   
                    spikes_binned = histc(data,time);
                    spikes_binned = spikes_binned(1:end-1);
                    time = time(1:end-1)+1/sr/2;
                    spikes{1} = data;
                    
                    ca_trace = MMfunction(spikes_binned,ca);
                    
                    qi = NaN;
                    spikes_binned_by_trial = NaN;
                    spikes_by_trial = NaN;
                    
            end
            
            % fill tuple
            tuple = key;
            tuple.sampling_rate = sr;
            tuple.spikes_binned_by_trial = spikes_binned_by_trial;
            tuple.spikes_by_trial = spikes_by_trial;
            tuple.spikes = spikes;
            tuple.ca_trace = ca_trace;
            tuple.tau = tau;
            tuple.spikes_binned = spikes_binned;
            
            tuple.time = time;
            
            
            if ~isnan(qi)
                tuple.quality = qi;
            end
            
            self.insert(tuple);
        end
    end
    
end

% normalize each trial
% data = bsxfun(@rdivide,data,max(abs(data)));


