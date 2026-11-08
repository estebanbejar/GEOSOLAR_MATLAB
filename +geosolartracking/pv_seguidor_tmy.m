function met = pv_seguidor_tmy(lat,lon)
% PVGIS 5.3 TMY, raw response cached by coordinates and endpoint version.
root=fullfile(fileparts(fileparts(mfilename('fullpath'))),'data','pvgis_tmy');
if ~isfolder(root),mkdir(root);end
file=fullfile(root,sprintf('tmy_v53_%.6f_%.6f.json',lat,lon));
url=sprintf('https://re.jrc.ec.europa.eu/api/v5_3/tmy?lat=%.6f&lon=%.6f&outputformat=json&usehorizon=1',lat,lon);
fresh=~isfile(file);
if fresh
    try
        raw=webread(url,weboptions('Timeout',180,'ContentType','text'));
    catch err
        if contains(err.identifier,'HTTP400')||contains(err.message,'status 400')
            geosolartracking.explainTmyRequest(url,lat,lon,err);
        end
        rethrow(err);
    end
else
    raw=fileread(file);
end
j=jsondecode(raw);
if ~isfield(j,'outputs') || ~isfield(j.outputs,'tmy_hourly')
    error('pv:tmy','Respuesta PVGIS sin año meteorológico típico.');
end
rows=j.outputs.tmy_hourly; f=fieldnames(rows); tf=f{find(startsWith(f,'time'),1)};
stamp=string({rows.(tf)})';
date=datetime(stamp,'InputFormat','yyyyMMdd:HHmm');
ghi=reshape([rows.(matlab.lang.makeValidName('G(h)'))],[],1);
dni=reshape([rows.(matlab.lang.makeValidName('Gb(n)'))],[],1);
dhi=reshape([rows.(matlab.lang.makeValidName('Gd(h)'))],[],1);
if numel(date)~=8760 || any(~isfinite([ghi;dni;dhi])) || any([ghi;dni;dhi]<0)
    error('pv:tmy','Se esperaba un TMY completo de 8760 horas con irradiancias válidas.');
end
% Selected months can come from different years. Verify the canonical calendar.
canonical=datetime(2001,month(date),day(date),hour(date),minute(date),0);
if any(diff(canonical)~=hours(1)),error('pv:tmy','Calendario TMY discontinuo.');end
offset=0; location=j.inputs.location;
if isfield(location,'irradiance_time_offset'), offset=location.irradiance_time_offset; end
if isfield(j.inputs.meteo_data,'irradiance_time_offset'),offset=j.inputs.meteo_data.irradiance_time_offset;end
sunTime=date+hours(offset);
B=2*pi*(day(sunTime,'dayofyear')-81)/364;
eot=9.87*sin(2*B)-7.53*cos(B)-1.5*sin(B);
solar=hour(sunTime)+minute(sunTime)/60+second(sunTime)/3600+lon/15+eot/60;
met=struct('sun',geosolartracking.pv_seguidor_solar(lat,sunTime,solar),'ghi',ghi,'dni',dni,'dhi',dhi, ...
    'source',url,'file',file,'offset',offset,'inputs',j.inputs,'date',date);
if fresh
    fid=fopen(file,'w','n','UTF-8');
    if fid<0,error('pv:cache','No se puede guardar la caché PVGIS.');end
    clean=onCleanup(@() fclose(fid));fprintf(fid,'%s',raw);
end
end
