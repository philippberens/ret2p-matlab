%{
ret2p.Clust (imported) # clustering based on features

-> ret2p.ClustSet
-> ret2p.ClustParams

---


%}

classdef Clust < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ret2p.Clust');
        popRel = ret2p.ClustSet * ret2p.ClustParams;
    end
    
    methods
        function self = Clust(varargin)
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
            
            param_key = fetch1(ret2p.CaRFp(key),'param_key');
            
            
            
            %% fill tuple
            tuple = key;
            
            
            self.insert(tuple);
        end
        
        
        
        
    end
end


