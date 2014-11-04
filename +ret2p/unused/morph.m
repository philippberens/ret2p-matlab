morph_id = null        : longblob      # ids with morphology
morph_files =null      : longblob      # 

                    % load morphology file if present
                    mo_file = getLocalPath(fullfile(path,folder,'CellsWithMorphology.ibw'));
                    mo_present = exist(mo_file,'file');
                    if mo_present
                        y4 = IBWread(mo_file);
                        mo = y4.y;
                    end