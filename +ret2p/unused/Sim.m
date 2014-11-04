%{
ret2p.Sim (imported) # info about quadrants

-> ret2p.Traces
-> ret2p.Spikes
---
linked=0   
%}

classdef Sim < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.Sim');
    end
    
    methods 
        function self = Sim(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            
            % get path information & read file
            path = fetch1(ret2p.Dataset(key),'path');
            folder = fetch1(ret2p.Quadrant(key),'folder');

            % simultaneous recordings
            file = 'Sim.ibw';
            
            if exist(getLocalPath(fullfile(path,folder,file)),'file')
                y = IBWread(getLocalPath(fullfile(path,folder,file)));
                ephys_ids = y.y(:,1);
                twop_ids = y.y(:,2);
                sim = true;
            end
            
            if sim
                for i=1:length(ephys_ids)
                    tuple(i) = key;
                    tuple(i).id_ephys = ephys_ids(i);
                    tuple(i).id_2p = twop_ids(i);
                end
            end
            
            self.insert(tuple);
        end
    end
    
end
