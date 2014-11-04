%{
ret2p.ImmunoInfo (imported) # List of datasets to analyze

-> ret2p.Cells
---
cell_type="RGC"             : varchar(255)                  # cell type
gad=null                    : float                         # gad staining
chat=null                   : float                         # chat staining
melanopsin=null             : float                         # melanopsin immuno staining
smi32=null                  : float                         # smi32 immuno staining
%}

classdef ImmunoInfo < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.ImmunoInfo');
        popRel = ret2p.Cells;
    end
    
    methods
        function self = ImmunoInfo(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            % get path information & read file
            path = fetch1(ret2p.Datasets(key),'path');
            folder = fetch1(ret2p.Scans(key),'folder');
            cell_type = fetch1(ret2p.Cells(key),'cell_type');
            
            switch cell_type
                case 'RGC'
                    
                    % load gad staining if present
                    gad_file = getLocalPath(fullfile(path,folder,'GAD_Staining.ibw'));
                    gad_present = exist(gad_file,'file');
                    if gad_present
                        y3 = IBWread(gad_file);
                        gad = y3.y;
                    end
                    
                    % load SMI32 staining if present
                    smi_file = getLocalPath(fullfile(path,folder,'SMI32_Cells.ibw'));
                    smi_present = exist(smi_file,'file');
                    if smi_present
                        y3 = IBWread(smi_file);
                        smi = y3.y;
                    end
                    
                    % load chat staining if present
                    chat_file = getLocalPath(fullfile(path,folder,'ChAT_Staining.ibw'));
                    chat_present = exist(chat_file,'file');
                    if chat_present
                        y3 = IBWread(chat_file);
                        chat = y3.y;
                    end
                    
                    % load melanopsin staining if present
                    mel_file = getLocalPath(fullfile(path,folder,'Melanopsin_Cells.ibw'));
                    mel_present = exist(mel_file,'file');
                    if mel_present
                        y3 = IBWread(mel_file);
                        mel = y3.y;
                    end
                    
                case 'BC'
                    
                    % other things not relevant
                    gad_file = getLocalPath(fullfile(path,folder,'GAD_Staining.ibw'));
                    gad_present = exist(gad_file,'file');
                    
                    chat_file = getLocalPath(fullfile(path,folder,'ChAT_Staining.ibw'));
                    chat_present = exist(chat_file,'file');
                    
                    smi_file = getLocalPath(fullfile(path,folder,'SMI32_Cells.ibw'));
                    smi_present = exist(smi_file,'file');
                    
                    mel_file = getLocalPath(fullfile(path,folder,'Melanopsin_Cells.ibw'));
                    mel_present = exist(mel_file,'file');
                    
                    
            end
            
            
            
            % enter cells
            
            tuple = key;
            tuple.cell_type = cell_type;
            
            if gad_present
                tuple.gad = gad(key.cell_num);
            end
            
            if chat_present
                tuple.chat = chat(key.cell_num);
            end
            
            if mel_present
                tuple.melanopsin = mel(key.cell_num);
            end
            
            if smi_present
                tuple.smi32 = smi(key.cell_num);
            end
            
            self.insert(tuple);
            
            
            
            % populate traces
            %             for key = fetch(ret2p.Stimuli * (self & key))'
            %                 makeTuples(ret2p.Traces, key);
            %             end
        end
    end
    
end
