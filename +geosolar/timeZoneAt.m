function zone=timeZoneAt(lat,lon)
% Zona IANA por coordenadas; caché local para funcionar sin red posteriormente.
root=fileparts(fileparts(mfilename('fullpath')));folder=fullfile(root,'data','timezones');if ~isfolder(folder),mkdir(folder);end
file=fullfile(folder,sprintf('zone_%.6f_%.6f.json',lat,lon));
if isfile(file)
    saved=jsondecode(fileread(file));zone=char(saved.zone);check=datetime(2026,1,1,'TimeZone',zone);return;
end
data=webread('https://api.open-meteo.com/v1/forecast','latitude',lat,'longitude',lon,'timezone','auto','forecast_days',1,weboptions('Timeout',12,'ContentType','json'));
zone=char(data.timezone);check=datetime(2026,1,1,'TimeZone',zone); %#ok<NASGU>
fid=fopen(file,'w','n','UTF-8');if fid>=0,c=onCleanup(@()fclose(fid));fprintf(fid,'%s',jsonencode(struct('lat',lat,'lon',lon,'zone',zone)));end
end
