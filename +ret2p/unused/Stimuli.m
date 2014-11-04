%{
ret2p.Stimuli (manual) # List of datasets to analyze

-> ret2p.Scans
stim_num        : tinyint unsigned      # number of stimulus
---
stim_type                   : enum('chirp','DS','DN','GB','DS50','FF')# name of stimulus
stim_file                   : varchar(255)                  # path to stim file
%}

classdef Stimuli < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.Stimuli');
    end
    
    methods 
        function self = Stimuli(varargin)
            self.restrict(varargin{:})
        end
    end    
end

