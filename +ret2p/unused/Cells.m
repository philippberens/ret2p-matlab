%{
ret2p.Cells (imported) # List of datasets to analyze

-> ret2p.Scans
cell_num        : tinyint unsigned      # number of stimulus
---
pos_x=0                     : float                         # x-coordinate of cell pos
pos_y=0                     : float                         # y-coordinate of cell pos
cell_type="RGC"             : varchar(255)                  # cell type
area2d                      : float                         # 2D size
area3d=null                 : float                         # 3D area
volume=null                 : float                         # 3D volume
pca1=null                   : float                         # 3D pca1
pca2=null                   : float                         # 3D pca2
pca3=null                   : float                         # 3D pca3
border_cell=null            : float                         # if cell is at border of scan
morphology=0                : float                         # morphological reconstruction
%}

classdef Cells < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.Cells');
        popRel = ret2p.Scans;
    end
    
    methods
        function self = Cells(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            path = fetch1(ret2p.Datasets(key),'path');
            folder = fetch1(ret2p.Scans(key),'folder');
            
            % determine cell type
            cell_type_file =  getLocalPath(fullfile(path,folder,'CellType.ibw'));
            cell_type_present = exist(cell_type_file,'file');
            if cell_type_present
                y3 = IBWread(cell_type_file);
                cell_type = y3.y;
                if strcmp(cell_type,'Bipolar Cell')
                    cell_type = 'BC';
                end
            else
                cell_type = 'RGC';
            end
            
            % cells info
            y = IBWread(getLocalPath(fullfile(path,folder,'Cells.ibw')));
            nCells = size(y.y,1);
            
            switch cell_type
                case 'RGC'
                    
                    pos = y.y(:,4:5);  % position of cells
                    scale = y.y(1,6);
                    mins = min(pos)+5;
                    maxs = max(pos)-5;
                    if nCells > 1
                        border_cell = pos(:,1) < mins(1) | pos(:,2) < mins(2) | ...
                            pos(:,1) > maxs(1) | pos(:,2) > maxs(2);
                    else
                        border_cell = false;
                    end
                    
                    % 2d/3d cell info
                    y2 = IBWread(getLocalPath(fullfile(path,folder,'info_3D_ROIs.ibw')));
                    area2d = y2.y(:,1) * scale^2;
                    area3d = y2.y(:,4);
                    volume = y2.y(:,3);
                    pca1 = y2.y(:,7);
                    pca2 = y2.y(:,8);
                    pca3 = y2.y(:,9);
                       
                    
                    % load morphology file if present
                    mo_file = getLocalPath(fullfile(path,folder,'CellsWithMorphology.ibw'));
                    mo_present = exist(mo_file,'file');
                    if mo_present
                        y4 = IBWread(mo_file);
                        mo = y4.y;
                    end
                    
                    
                case 'BC'
                    pos = [y.y(:,6) zeros(nCells,1)];  % position of cells
                    scale = y.y(1,9); % in microns
                    
                    area2d = y.y(:,10);
                    area3d = NaN(nCells,1);
                    volume = NaN(nCells,1);
                    border_cell = zeros(nCells,1);
                   
                    
                    % load morphology file if present
                    mo_file = getLocalPath(fullfile(path,folder,'CellsWithMorphology.ibw'));
                    mo_present = exist(mo_file,'file');
                    if mo_present
                        y = IBWread(mo_file);
                        mo = y.y;
                    end
                    
                    
            end
            
            % prepare key
            key.date = key.date; %#ok<*AGROW>
            key.scan_num = key.scan_num;
            key.eye_id = key.eye_id;
            key.mouse_id = key.mouse_id;
            
            % enter cells
            
            for i=1:nCells
                tuple = key;
                tuple.cell_type = cell_type;
                tuple.cell_num = i;
                tuple.pos_x = pos(i,1);
                tuple.pos_y = pos(i,2);
                tuple.area2d = area2d(i);
                
                if ~isnan(area3d(i))
                    tuple.area3d = area3d(i);
                    tuple.volume = volume(i);
                    tuple.pca1 = pca1(i);
                    tuple.pca2 = pca2(i);
                    tuple.pca3 = pca3(i);
                end

                
                if mo_present
                    tuple.morphology = mo(i);
                end
                
                if nCells>1
                    tuple.border_cell = border_cell(i);
                else
                    tuple.border_cell = 0;
                end
                disp(i)
                self.insert(tuple);
            end
            
            
            % populate traces
            %             for key = fetch(ret2p.Stimuli * (self & key))'
            %                 makeTuples(ret2p.Traces, key);
            %             end
        end
    end
    
end
