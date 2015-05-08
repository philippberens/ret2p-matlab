%{
ret2p.DrugTreatment (manual) # List of drugtreatments for that dataset

-> ret2p.Stimulus
drug_num        : tinyint unsigned      # number of drug
---
drug_type       : enum('None','Tpmpa/Gabazine','Washout')     # stimulus names
folder          : varchar(255)                      # path to files
%}

classdef DrugTreatment < dj.Relvar
    properties(Constant)
        table = dj.Table('ret2p.DrugTreatment');
    end
    
    methods 
        function self = DrugTreatment(varargin)
            self.restrict(varargin{:})
        end
    end    
end

