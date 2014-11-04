%{
ret2p.Traces (imported) # Trace/display for each stimulus

-> ret2p.Cells
-> ret2p.Stimuli
---
sampling_rate       : float                 # sampling rate in Hz
quality=NULL        : float                 # quality index
mean_trace          : longblob              # average trace vector
dt_trace            : longblob              # differential trace vector
time                : longblob              # time vector
trace_by_trial      : longblob              # traces by trial
%}

classdef Traces < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.Traces');
        popRel = ret2p.Stimuli * ret2p.Cells;
    end
    
    methods
        function self = Traces(varargin)
            self.restrict(varargin{:})
        end
    end
    %
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            path = fetch1(ret2p.Datasets(key),'path');
            stim = fetch1(ret2p.Stimuli(key),'stim_type');
            scan = fetch1(ret2p.Scans(key),'folder');
            if strcmp(stim,'GB')
                file = sprintf('%s_data.ibw','colour');
            else
                file = sprintf('%s_data.ibw',stim);
            end
            
            y = IBWread(getLocalPath(fullfile(path,scan,file)));
            
            cell_type = fetchn(ret2p.Cells(key),'cell_type');
            
            % function for quality index
            f = @(d) var(mean(d,2),[],1)/mean(var(d,[],1),2);
            
            switch stim
                case {'DS','DS50'}
                    % get data for cell i
                    data = y.y(:,:,key.cell_num);
                    
                    % sampling rate & time vector
                    nT = size(data,1);
                    sr = 1/y.dx(1);
                    dt = 1/sr;
                    time = (0:dt:(nT-1)*dt) + dt/2;
                    
                    data = bsxfun(@minus,data,median(data(1:5,:),1));
                    
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
                        
                        mean_trace(:,i) = median(tmpdata,2);
                        trace_by_trial(:,i,:) = tmpdata;
                        qi(i) = f(tmpdata);
                        
                    end
                    trace_by_trial = trace_by_trial/max(mean_trace(:));
                    mean_trace = mean_trace/max(abs(mean_trace(:)));
                    qi = max(qi);
                    
                    
                    if size(mean_trace,1)<32
                        mean_trace = [mean_trace; mean(mean_trace(end-2:end,:),1)];
                        trace_by_trial = cat(1,trace_by_trial,mean(trace_by_trial(end-2:end,:,:),1));
                    end
                    dt_trace = gradient(mean_trace);
                    
                case 'GB'
                    
                    % get data for cell i
                    data = y.y(:,:,key.cell_num);
                    
                    % sampling rate & time vector
                    nT = size(data,1);
                    sr = 1/y.dx(1);
                    dt = 1/sr;
                    time = (0:dt:(nT-1)*dt) + dt/2;
                    
                    % remove baseline
                    data = bsxfun(@minus,data,mean(data(1:ceil(sr),:),1));
                    mean_trace = mean(data,2);
                    trace_by_trial = data/max(abs(mean_trace));
                    mean_trace = mean_trace/max(abs(mean_trace));
                    dt_trace = gradient(mean_trace);
                    
                    
                    qi = f(trace_by_trial);
                    
                case 'chirp'
                    % get data for cell i
                    data = y.y(:,:,key.cell_num);
%                     idx = sum(abs(diff(data))==0)>100;
%                     data = data(:,~idx);
                    
                    % sampling rate & time vector
                    [nT, nR] = size(data);
                    sr = 1/y.dx(1);
                    dt = 1/sr;
                    time = (0:dt:(nT-1)*dt) + dt/2;
                    
                    % for BCs, adjust sampling rates and length
                    if strcmp(cell_type,'BC')
                        data = reshape(data,1,[]);
                        [b,a] = butter(7,0.005,'low');
                        data = data - filtfilt(b,a,data);
                        data = reshape(data,nT,nR);
                        data = data(:,1:end-1);
                        
                        if sr ~=31.25
                            sr2 = 31.25;
                            nT2 = ceil(sr2/sr * nT);
                            dt2 = 1/sr2;
                            time2 = (0:dt2:(nT2-1)*dt2) + dt2/2;
                            data2 = zeros(nT2,size(data,2));
                            for i=1:size(data,2)
                                data2(:,i) = interp1(time,data(:,i),time2);
                            end
                            data = data2;
                            time = time2;
                            sr = sr2;
                        end
                        data = data(1:1000,:);
                        time = time(1:1000);
                    end
                    
                    
                    % remove baseline
                    data = bsxfun(@minus,data,median(data(1:ceil(sr),:),1));
                    
                    % data quality index
                    a = var(mean(data,2),[],1);     % variance of the mean
                    b = mean(var(data,[],1),2);     % mean of the variances
                    qi = a/b;
                    
                    % compute trial average and normalize
                    mean_trace = nanmedian(data,2);
                    mean_trace = mean_trace/max(abs(mean_trace));
                    dt_trace = gradient(mean_trace);
                    trace_by_trial = data;
                    
                case 'DN'
                    % get data for cell i
                    data = y.y(:,key.cell_num);
                    
                    
                    % sampling rate & time vector
                    yt = IBWread(getLocalPath(fullfile(path,scan, ...
                        [file(1:end-4) '_timing' file(end-3:end)])));
                    time = yt.y(:,key.cell_num)/1000;
                    
                    sr = 1000/diff(yt.y(1:2,key.cell_num));
                    
                    %                     mean_trace = detrend(data);
                    mean_trace = (data - mean(data));
                    mean_trace = mean_trace/median(abs(mean_trace))/0.6745;
                    dt_trace = gradient(mean_trace);
                    qi = NaN;
                    trace_by_trial = NaN;
                    
                    
            end
            
            % fill tuple
            tuple = key;
            tuple.sampling_rate = sr;
            tuple.mean_trace = mean_trace;
            tuple.dt_trace = dt_trace;
            tuple.time = time;
            tuple.trace_by_trial = trace_by_trial;
            
            if ~isnan(qi)
                tuple.quality = qi;
            end
            
            self.insert(tuple);
        end
    end
    
end

% normalize each trial
% data = bsxfun(@rdivide,data,max(abs(data)));


