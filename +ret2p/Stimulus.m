%{
ret2p.Stimulus (manual) # List of stimuli to analyze

-> ret2p.Quadrant
stim_num        : tinyint unsigned      # number of stimulus
---
stim_type                   : enum("Chirp","DS","BG","DN","FF","Step","SmallChirp")           # name of stimulus
stim_file                   : varchar(255)                  # path to stim file
data_file                   : varchar(255)                  # path to data file

%}

classdef Stimulus < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.Stimulus');
    end
    
    methods 
        function self = Stimulus(varargin)
            self.restrict(varargin{:})
        end
    end    
end

