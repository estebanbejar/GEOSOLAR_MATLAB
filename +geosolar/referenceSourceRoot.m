function folder=referenceSourceRoot()
% Solo para comprobaciones comparativas; la aplicación no usa IRRADIANCE.
folder=getenv('GEOSOLAR_IRRADIANCE_ROOT');
if isempty(folder)
    suite=fileparts(fileparts(mfilename('fullpath')));folder=fullfile(fileparts(suite),'IRRADIANCE');
end
assert(isfolder(fullfile(folder,'src')),'geosolar:referenceSource', ...
    'Esta comprobación comparativa necesita las fuentes originales de IRRADIANCE. Defina GEOSOLAR_IRRADIANCE_ROOT o sitúe IRRADIANCE junto a GEOSOLAR_MATLAB. La suite funciona sin esas fuentes.');
end
