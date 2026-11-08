classdef GeosolarEOLab < GeosolarFixedLab
    methods
        function lab=GeosolarEOLab(sideHost,host,owner)
            lab@GeosolarFixedLab(sideHost,host,owner,'eo');
        end
    end
end
