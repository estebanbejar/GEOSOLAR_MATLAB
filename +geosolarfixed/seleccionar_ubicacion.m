function [lat,lon,aceptado,nombre] = seleccionar_ubicacion(latInicial,lonInicial,options)
% Shared modal map picker; cancellation preserves original values.
% [lat,lon,ok,name]=seleccionar_ubicacion(40,-5,Nombre="Mi planta",
%                                      LatitudeLimits=[-65 65]);
arguments
    latInicial (1,1) double {mustBeFinite,mustBeGreaterThanOrEqual(latInicial,-90),mustBeLessThanOrEqual(latInicial,90)}
    lonInicial (1,1) double {mustBeFinite,mustBeGreaterThanOrEqual(lonInicial,-180),mustBeLessThanOrEqual(lonInicial,180)}
    options.Nombre (1,1) string = ""
    options.LatitudeLimits (1,2) double = [-90 90]
    options.Visible (1,1) string = "on"
end
limits=options.LatitudeLimits;
if any(~isfinite(limits))||limits(1)<-90||limits(2)>90||limits(1)>=limits(2)
    error('ubicacion:limits','Límites de latitud no válidos.');
end
lat=latInicial;lon=lonInicial;nombre=char(options.Nombre);aceptado=false;
fig=uifigure('Name','Seleccionar ubicación · mapa y localidades','Position',[100 100 1080 760], ...
    'Visible',options.Visible,'Tag','locationPicker','CloseRequestFcn',@cancel);
movegui(fig,'center');clean=makeCleanup(fig);
grid=uigridlayout(fig,[1 1]);grid.Padding=[0 0 0 0];
tileFailed=false;
html=uihtml(grid,'Tag','locationHTML','DataChangedFcn',@changed,'HTMLEventReceivedFcn',@tileRequested);
html.Data=struct('type','init','lat',lat,'lon',lon,'name',nombre,'minLat',limits(1),'maxLat',limits(2));
html.HTMLSource=fullfile(fileparts(fileparts(mfilename('fullpath'))),'assets','location_picker','picker.html');
uiwait(fig);
deletePicker(fig);
    function tileRequested(src,event)
        if ~strcmp(event.HTMLEventName,'tile'),return;end
        r=event.HTMLEventData;
        try
            if tileFailed,error('ubicacion:tile','Mapa no disponible en esta sesión.');end
            source=geosolarfixed.ubicacion_mapa_tile(r.z,r.x,r.y);
        catch
            source='';tileFailed=true;
        end
        if isvalid(src),sendEventToHTMLSource(src,'tile',struct('id',r.id,'source',source));end
    end
    function changed(src,~)
        data=src.Data;if ~isstruct(data)||~isfield(data,'type'),return;end
        switch char(data.type)
            case 'search'
                id=data.id;
                try
                    results=geosolarfixed.buscar_localidades(data.q);message='';
                catch err
                    results=[];message=['No se pudo buscar. Compruebe la conexión. ' err.message];
                end
                if isvalid(src),src.Data=struct('type','results','id',id,'results',results,'error',message);end
            case 'accept'
                if ~all(isfield(data,{'lat','lon','name'})),return;end
                if ~isnumeric(data.lat)||~isscalar(data.lat)||~isfinite(data.lat)||data.lat<limits(1)||data.lat>limits(2)|| ...
                        ~isnumeric(data.lon)||~isscalar(data.lon)||~isfinite(data.lon)||data.lon< -180||data.lon>180
                    return;
                end
                name=strtrim(string(data.name));if ~isscalar(name)||strlength(name)==0||strlength(name)>200,return;end
                lat=data.lat;lon=data.lon;nombre=char(name);aceptado=true;uiresume(fig);
            case 'cancel'
                cancel();
        end
    end
    function cancel(varargin),if isvalid(fig),uiresume(fig);end,end
end
function cleanup=makeCleanup(fig),cleanup=onCleanup(@()deletePicker(fig));end
function deletePicker(fig),if isvalid(fig),delete(fig);end,end
