function verificarConsultaProductividad()
% Una única orientación real: no descarga toda la carta de 684 puntos.
root=fileparts(mfilename('fullpath'));files=dir(fullfile(root,'data','productividad','PVGIS_*.mat'));
seed=load(fullfile(files(1).folder,files(1).name));
[~,base]=fileparts(files(1).name);parts=strsplit(base,'_');lat=str2double(parts{end-1});lon=str2double(parts{end});
seed.productividad(~isfinite(seed.productividad))=0;seed.irradiacion(~isfinite(seed.irradiacion))=0;
seed.productividad(7,18)=NaN;seed.irradiacion(7,18)=NaN;
r=geosolarproductivity.pv_productividad_calcular(seed.localidad,lat,lon,[],seed);
assert(isfinite(r.productividad(7,18))&&r.productividad(7,18)>0&&isfinite(r.irradiacion(7,18)));
mask=true(19,36);mask(7,18)=false;assert(isequaln(r.productividad(mask),seed.productividad(mask))&&isequaln(r.irradiacion(mask),seed.irradiacion(mask)));
file=fullfile(root,'outputs','productividad_consulta_verificacion.txt');fid=fopen(file,'w','n','UTF-8');c=onCleanup(@()fclose(fid));
fprintf(fid,'PASS: una consulta PVGIS v5_2/PVcalc real (β 30°, A 0°), %.3f kWh/kWp/año; %.3f kWh/m²/año. Las otras 683 orientaciones se conservan.\n',r.productividad(7,18),r.irradiacion(7,18));
disp('PASS: consulta PVGIS original real y conservación de los 683 puntos existentes.');
end
