%{
ret2p.GeneticInfo (imported) # Information from genetic mouse lines

-> ret2p.Cells
---
cell_type="RGC"             : varchar(255)                  # cell type
pv_cell_info=null           : longblob                      # pv cell matrix
pcp_cell_info=null          : longblob                      # pcp cell matrix
pv_pos=null                   : float                         # pv label
pcp_pos=null                   : float                         # pcp label

%}

classdef GeneticInfo < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.GeneticInfo');
        popRel = ret2p.ROI;
    end
    
    methods
        function self = GeneticInfo(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            path = fetch1(ret2p.Dataset(key),'path');
            folder = fetch1(ret2p.Quadrant(key),'folder');
            cell_type = fetch1(ret2p.Dataset(key),'target');
            
            switch cell_type
                case 'RGC'
                    
                    % load pv info if present
                    pv_file = getLocalPath(fullfile(path,folder,'PvCellTypes.ibw'));
                    pv_present = exist(pv_file,'file');
                    if pv_present
                        y3 = IBWread(pv_file);
                        pv = y3.y;
                    end
                    
                    % load pv info if present
                    pcp_file = getLocalPath(fullfile(path,folder,'Pcp2CellTypes.ibw'));
                    pcp_present = exist(pcp_file,'file');
                    if pcp_present
                        y3 = IBWread(pcp_file);
                        pcp = y3.y;
                    end
                    
                case 'BC'
                    
                    pv_file = getLocalPath(fullfile(path,folder,'PvCellTypes.ibw'));
                    pv_present = exist(pv_file,'file');
                    pcp_file = getLocalPath(fullfile(path,folder,'Pcp2CellTypes.ibw'));
                    pcp_present = exist(pcp_file,'file');
                    
            end
            
            
            % enter cells
            
            tuple = key;            
            if pv_present && pv(key.cell_num,1)==1
                tuple.pv_cell_info = pv(key.cell_num,2:end);
                tuple.pv_pos = 1;
            elseif pv_present && pv(key.cell_num,1)~=1
                tuple.pv_pos = 0;
                tuple.pv_cell_info = zeros(1,8);
            else
                tuple.pv_pos = -1;
                tuple.pv_cell_info = NaN(1,8);
            end
            
            if pcp_present && pcp(key.cell_num,1)==1
                tuple.pcp_cell_info = pcp(key.cell_num,2:end);
                tuple.pcp_pos = 1;
            elseif pcp_present && pcp(key.cell_num,1)~=1
                tuple.pcp_pos = 0;
                tuple.pcp_cell_info = zeros(1,5);
            else
                tuple.pcp_pos = -1;
                tuple.pcp_cell_info = NaN(1,5);
            end
            
            self.insert(tuple);
            
        end
    end
    
end
