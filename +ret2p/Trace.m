%{
ret2p.Trace (imported) # Trace/display for each stimulus

-> ret2p.ROI
-> ret2p.Stimulus
---
sampling_rate       : float                 # sampling rate in Hz
quality=NULL        : float                 # quality index
mean_trace          : longblob              # average trace vector
dt_trace            : longblob              # differential trace vector
time                : longblob              # time vector
trace_by_trial      : longblob              # traces by trial
baseline            : longblob                 # baseline
scale               : float                 # normalization
%}

classdef Trace < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.Trace');
        popRel = ret2p.Stimulus * ret2p.ROI('tp=1');
    end
    
    methods
        function self = Trace(varargin)
            self.restrict(varargin{:})
        end
    end
    %
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            path = fetch1(ret2p.Dataset(key),'path');
            stim = fetch1(ret2p.Stimulus(key),'stim_type');
            scan = fetch1(ret2p.Quadrant(key),'folder');
            
            if strcmp(stim,'GB')
                file = sprintf('%s_data.ibw','colour');
            else
                file = sprintf('%s_data.ibw',stim);
            end
            
            y = IBWread(getLocalPath(fullfile(path,scan,file)));
            
            disp(getLocalPath(fullfile(path,scan,file)))
            
            target = fetchn(ret2p.Dataset(key),'target');
            
            % function for quality index
            f = @(d) var(mean(d,2),[],1)/mean(var(d,[],1),2);
            
            switch lower(stim)
                case {'ds','ds50'} % NOT CHECKED WITH NEW SETUP
                    % get data for cell i
                    data = y.y(:,:,key.roi_num);
                    
                    % sampling rate & time vector
                    nT = size(data,1);
                    sr = 1/y.dx(1);
                    dt = 1/sr;
                    time = (0:dt:(nT-1)*dt) + dt/2;
                    
                    baseline = median(data(1:5,:),1);
                    data = bsxfun(@minus,data,baseline);
                    
                    % stimuli for directions
                    stims = fetch1(ret2p.StimInfo(key),'stim');
                    ustims = sort(stims);
                    nTrials = size(data,2);
                    stims = repmat(stims,nTrials/length(stims),1);
                    
                    % sort traces after conditions
                    mean_trace = zeros(size(data,1),length(ustims));
                    trace_by_trial = zeros(size(data,1),length(ustims),nTrials/length(ustims));
                    qi = zeros(length(ustims),1);
                    for i=1:length(ustims)
                        idx = stims == ustims(i);
                        tmpdata = data(:,idx);
                        
                        mean_trace(:,i) = mean(tmpdata,2);
                        trace_by_trial(:,i,:) = tmpdata;
                        qi(i) = f(tmpdata);
                        
                    end
                    trace_by_trial = trace_by_trial/max(abs(mean_trace(:)));
                    scale = max(abs(mean_trace(:)));
                    mean_trace = mean_trace/max(abs(mean_trace(:)));
                    qi = max(qi);
                    
                    
                    
                    
                    if size(mean_trace,1)<32
                        mean_trace = [mean_trace; mean(mean_trace(end-2:end,:),1)];
                        trace_by_trial = cat(1,trace_by_trial,mean(trace_by_trial(end-2:end,:,:),1));
                    end
                    dt_trace = gradient(mean_trace);
                    
                case 'gb'  % NOT CHECKED WITH NEW SETUP
                    
                    % get data for cell i
                    data = y.y(:,:,key.roi_num);
                    
                    % sampling rate & time vector
                    nT = size(data,1);
                    sr = 1/y.dx(1);
                    dt = 1/sr;
                    time = (0:dt:(nT-1)*dt) + dt/2;
                    
                    % remove baseline
                    baseline = mean(data(1:ceil(sr),:),1);
                    data = bsxfun(@minus,data,baseline);
                    mean_trace = mean(data,2);
                    scale = max(abs(mean_trace(:)));
                    trace_by_trial = data/scale;
                    mean_trace = mean_trace/scale;
                    dt_trace = gradient(mean_trace);
                    
                    
                    qi = f(trace_by_trial);
                    
                case {'chirp','localchirp'}
                    % get data for roi i
                    data = y.y(:,:,key.roi_num);
                    
                    % sampling rate & time vector
                    [nT, ~] = size(data);
                    sr = 1/y.dx(1);
                    if sr==1 &&  strcmp(target,'BC_T')
                        sr = 500;
                    elseif sr==1 &&  strcmp(target,'RGC_CB')
                        sr = 7.8;
                    end
                    dt = 1/sr;
                    time = (0:dt:(nT-1)*dt) + dt/2;
                    
                    % for BCs, adjust sampling rates and length
                    if strcmp(target,'BC_T')
                        if sr ~=64
                            sr2 = 64;
                            nT2 = ceil(sr2/sr * nT);
                            dt2 = 1/sr2;
                            time2 = (0:dt2:(nT2-1)*dt2) + dt2/2;
                            data2 = zeros(nT2,size(data,2));
                            for i=1:size(data,2)
                                data2(:,i) = resample(data(:,i),sr2,sr);
                            end
                            data = data2;
                            time = time2;
                            sr = sr2;
                        end
                    end
                    
                    % remove baseline
                    baseline = median(data(1:ceil(sr),:),1);
                    data = bsxfun(@minus,data,baseline);
                    
                    % data quality index
                    a = var(mean(data,2),[],1);     % variance of the mean
                    b = mean(var(data,[],1),2);     % mean of the variances
                    qi = a/b;
                    
                    % compute trial average and normalize
                    mean_trace = nanmean(data,2);
                    scale = max(abs(mean_trace));
                    mean_trace = mean_trace/scale;
                    dt_trace = gradient(mean_trace);
                    trace_by_trial = data;
                    
                case {'dn', 'ringflicker'}
                    % get data for cell i
                    data = y.y(:,key.roi_num);
                    
                    
                    % sampling rate & time vector
                    yt = IBWread(getLocalPath(fullfile(path,scan, ...
                        [file(1:end-4) '_timing' file(end-3:end)])));
                    time = yt.y(:,key.roi_num)/1000;
                    
                    sr = 1000/diff(yt.y(1:2,key.roi_num));
                    
                    baseline = mean(data);
                    mean_trace = (data - baseline);
                    scale = median(abs(mean_trace))/0.6745;
                    mean_trace = mean_trace/scale;
                    dt_trace = gradient(mean_trace);
                    qi = NaN;
                    trace_by_trial = NaN;
                    
                case 'ff'
                    
                    
                case 'step'
                    % get data for roi i
                    data = y.y(:,:,key.roi_num);
                    
                    % sampling rate & time vector
                    [nT, ~] = size(data);
                    sr = 1/y.dx(1);
                    dt = 1/sr;
                    time = (0:dt:(nT-1)*dt) + dt/2;
                    
                    % remove baseline
                    baseline = median(data(1:20,:),1);
                    data = bsxfun(@minus,data,baseline);
                    
                    % data quality index
                    a = var(mean(data,2),[],1);     % variance of the mean
                    b = mean(var(data,[],1),2);     % mean of the variances
                    qi = a/b;
                    
                    % compute trial average and normalize
                    mean_trace = nanmean(data,2);
                    scale = max(abs(mean_trace));
                    mean_trace = mean_trace/scale;
                    dt_trace = gradient(mean_trace);
                    trace_by_trial = data;
                    
             
                    
            end
            
            % fill tuple
            tuple = key;
            tuple.sampling_rate = sr;
            tuple.mean_trace = mean_trace;
            tuple.dt_trace = dt_trace;
            tuple.time = time';
            tuple.trace_by_trial = trace_by_trial;
            tuple.baseline = baseline;
            tuple.scale = scale;
            
            if ~isnan(qi)
                tuple.quality = qi;
            end
            
            self.insert(tuple);
        end
    end
    
end
