%{
ret2p.DrugTreatment (manual) # List of drugtreatments for that dataset
-> ret2p.Stimulus
drug_num        : tinyint unsigned       # number of drug
---
drug_type                   : enum('None','Tpmpa/Gabazine','Tpmpa','Gabazine','Strychnine','Washout','L-AP4') # drug names
folder                      : varchar(255)                  # path to files
drug_concentration          : blob                          # drugconcentration
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

