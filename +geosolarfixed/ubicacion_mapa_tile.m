function source = ubicacion_mapa_tile(z,x,y)
% Only visible map tiles requested interactively by Leaflet; seven-day cache.
validateattributes(z,{'numeric'},{'scalar','integer','>=',0,'<=',19});
validateattributes(x,{'numeric'},{'scalar','integer','>=',0,'<',2^z});
validateattributes(y,{'numeric'},{'scalar','integer','>=',0,'<',2^z});
folder=fullfile(fileparts(fileparts(mfilename('fullpath'))),'data','map_tiles');
if ~isfolder(folder),mkdir(folder);end
file=fullfile(folder,sprintf('osm_%d_%d_%d.png',z,x,y));
entry=dir(file);
if isempty(entry)||now-entry.datenum>7
    temp=[tempname(folder) '.png'];
    cleanup=onCleanup(@()removeTemp(temp));
    websave(temp,sprintf('https://tile.openstreetmap.org/%d/%d/%d.png',z,x,y), ...
        weboptions('Timeout',12,'UserAgent','IRRADIANCE-LocationPicker/1.0 (+https://github.com/estebanbejar/geometria_solar)'));
    info=imfinfo(temp);if ~strcmpi(info.Format,'png'),error('ubicacion:tile','Imagen de mapa no válida.');end
    movefile(temp,file,'f');
end
fid=fopen(file,'rb');if fid<0,error('ubicacion:tile','No se puede leer el mapa.');end
clean=onCleanup(@()fclose(fid));bytes=fread(fid,Inf,'*uint8');
source=['data:image/png;base64,' matlab.net.base64encode(bytes)];
end
function removeTemp(file),if isfile(file),delete(file);end,end
