%{
ret2p.ScanInfo (imported) # info about scans

-> ret2p.Scans
---
offset_x = 0   : float                  # offset of the scan in microns
offset_y = 0   : float                  # offset of the scan in microns
        
%}

classdef ScanInfo < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.ScanInfo');
        popRel = ret2p.Scans;
    end
    
    methods 
        function self = ScanInfo(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            path = fetch1(ret2p.Datasets(key),'path');
            folder = fetch1(ret2p.Scans(key),'folder');
            file = 'Cells.ibw';
            
            if exist(getLocalPath(fullfile(path,folder,file)),'file')
                y = IBWread(getLocalPath(fullfile(path,folder,file)));
                pos = y.y(:,4:5);
            else
                pos = [0 0];
            end
            
            
            pos = mean(pos,1);
            
            % fill tuple
            tuple = key;
            tuple.offset_x = pos(1);
            tuple.offset_y = pos(2);
            self.insert(tuple);
        end
    end
    
end
