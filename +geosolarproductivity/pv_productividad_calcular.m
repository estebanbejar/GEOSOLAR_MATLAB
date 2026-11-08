function r = pv_productividad_calcular(localidad,latitud,longitud,progressFcn,datosIniciales,numPasadas)
%PV_PRODUCTIVIDAD_CALCULAR Consulta PVGIS para la malla anual de orientación.
% r = pv_productividad_calcular(nombre,latitud,longitud,progressFcn)
% r = pv_productividad_calcular(...,datosIniciales,numPasadas) conserva los
% puntos válidos y vuelve a consultar solo los puntos incompletos.
% La malla contiene inclinaciones 0:5:90 y acimuts -170:10:180.
if nargin<4,progressFcn=[];end
if nargin<5,datosIniciales=[];end
if nargin<6||isempty(numPasadas),numPasadas=1;end
validateattributes(numPasadas,{'numeric'},{'scalar','integer','positive','finite'});
if isstring(localidad),localidad=char(localidad);end
if ~ischar(localidad)||isempty(strtrim(localidad)),error('pv:location','Indique un nombre de localidad.');end
validateattributes(latitud,{'numeric'},{'scalar','real','finite','>=',-90,'<=',90});
validateattributes(longitud,{'numeric'},{'scalar','real','finite','>=',-180,'<=',180});

inclinaciones=0:5:90;acimuts=-170:10:180;
matSize=[numel(inclinaciones),numel(acimuts)];
if isempty(datosIniciales)
    productividad=nan(matSize);irradiacion=nan(matSize);
    perd_aoi=nan(matSize);perd_esp=nan(matSize);perd_temp=nan(matSize);
else
    if ~isstruct(datosIniciales)||~isfield(datosIniciales,'productividad')|| ...
            ~isfield(datosIniciales,'irradiacion')|| ...
            ~isequal(size(datosIniciales.productividad),matSize)|| ...
            ~isequal(size(datosIniciales.irradiacion),matSize)
        error('pv:seed','Los datos existentes no tienen el formato esperado para completar la carta.');
    end
    productividad=datosIniciales.productividad;irradiacion=datosIniciales.irradiacion;
    perd_aoi=campoInicial(datosIniciales,'perd_aoi',matSize);
    perd_esp=campoInicial(datosIniciales,'perd_esp',matSize);
    perd_temp=campoInicial(datosIniciales,'perd_temp',matSize);
end

fallos=0;pendientes=~(isfinite(productividad)&isfinite(irradiacion));
intentosMax=nnz(pendientes)*numPasadas;intentos=0;
for pasada=1:numPasadas
    [ii,jj]=find(~(isfinite(productividad)&isfinite(irradiacion)));
    if isempty(ii),break;end
    % Separar las pasadas ayuda a que el servicio recupere capacidad tras una
    % respuesta fallida, especialmente cuando muchos alumnos consultan a la vez.
    if pasada>1,pause(min(2^(pasada-2),4));end
    for k=1:numel(ii)
        i=ii(k);j=jj(k);intentos=intentos+1;
        try
            [ey,hi,laoi,lspec,ltg]=consultaPVGIS(latitud,longitud,inclinaciones(i),acimuts(j));
            if isfinite(ey)&&isfinite(hi)
                productividad(i,j)=ey;irradiacion(i,j)=hi;
                perd_aoi(i,j)=laoi;perd_esp(i,j)=lspec;perd_temp(i,j)=ltg;
            else
                fallos=fallos+1;
            end
        catch
            fallos=fallos+1;
        end
        if ~isempty(progressFcn)
            continuar=progressFcn(intentos,intentosMax,fallos);
            if isequal(continuar,false),error('pv:cancelled','Consulta cancelada por el usuario.');end
        end
    end
end
max_pro=max(productividad,[],'all','omitnan');
max_irr=max(irradiacion,[],'all','omitnan');
r=struct('localidad',strtrim(localidad),'latitud',latitud,'longitud',longitud, ...
    'lat',latitud,'lon',longitud,'productividad',productividad,'irradiacion',irradiacion, ...
    'perd_aoi',perd_aoi,'perd_esp',perd_esp,'perd_temp',perd_temp, ...
    'max_pro',max_pro,'max_irr',max_irr,'inclinaciones',inclinaciones,'acimuts',acimuts, ...
    'fecha_consulta',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
end

function value=campoInicial(s,name,expectedSize)
if isfield(s,name)&&isnumeric(s.(name))&&isequal(size(s.(name)),expectedSize)
    value=s.(name);
else
    value=nan(expectedSize);
end
end

function [ey,hi,laoi,lspec,ltg]=consultaPVGIS(lat,lon,angle,aspect)
url=sprintf(['https://re.jrc.ec.europa.eu/api/v5_2/PVcalc?lat=%.6f&lon=%.6f&peakpower=1' ...
    '&loss=14&angle=%.1f&aspect=%.1f&outputformat=json'],lat,lon,angle,aspect);
data=webread(url,weboptions('Timeout',30));
fixed=data.outputs.totals.fixed;
ey=fixed.E_y;hi=fixed.H_i__y;laoi=fixed.l_aoi;
lspec=valorNumerico(fixed.l_spec);ltg=fixed.l_tg;
end

function x=valorNumerico(x)
if ischar(x)||isstring(x),x=str2double(x);end
if isempty(x)||~isnumeric(x)||~isscalar(x)||~isfinite(x),x=NaN;end
end
