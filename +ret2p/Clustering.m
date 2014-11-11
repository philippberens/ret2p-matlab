%{
ret2p.Clustering (imported) # clustering based on features

-> ret2p.Trace
-> ret2p.CaRFp
---

rf          : longblob  # receptive field, smoothed
map         : longblob  # 2D RF map
tc          : longblob  # time course of activiation, 1SD of center
tc2          : longblob  # time course of activiation, 1SD of center
m           : longblob  # mean of receptive field averaged over all clean RFs
s           : longblob  # SD of receptive field averaged over all clean RFs
y           : longblob  # y position
x           : longblob  # x position
time        : longblob  # time of time kernel
size        : float     # size of the rf
quality     : float     # quality index: variance accounted for by fit
aspect_ratio: float     # aspect ratio of SD ellipse
rad_bins    : longblob  # radial bin positions
rad         : longblob  # radial bin amplitude
%}

classdef CaRF < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.CaRF');
        popRel = ret2p.CaRFp * (ret2p.Trace & ret2p.Stimulus('stim_type="DN"'));
    end
    
    methods
        function self = CaRF(varargin)
            self.restrict(varargin{:})
        end
        
        
        function plot(self,filter)
            
            if nargin > 1
                self.restrict(filter);
            end
            T = fetch(self,'*');
            f = Figure(1, 'size', [100 50]);
            
  
                
            end
            
        end
    end
    
    methods(Access = protected)
        function makeTuples(self, key)
            
            param_key = fetch1(ret2p.CaRFp(key),'param_key');
           

            
            %% fill tuple
            tuple = key;

            
            self.insert(tuple);
        end

          
            
            
        end
    end
    
end

