%{
ret2p.ClustSet (imported) # clustering based on features

-> ret2p.FeatType
-> ret2p.ClustSetParams
---
%}

classdef ClustSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.ClustSet');
        popRel = ret2p.ClustSetParams * ret2p.FeatType;
    end
    
    methods
        function self = ClustSet(varargin)
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
    
    methods(Access = protected)
        function makeTuples(self, key)
            
           
            
            self.insert(key)
            

            
            
            
            
        end
        
        
        
        
    end
end


