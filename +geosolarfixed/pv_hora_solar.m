function value = pv_hora_solar(fecha, longitude, input, direction, zone)
% Conversión didáctica entre hora solar aparente y civil (horas decimales).
% Incluye longitud, ecuación del tiempo aproximada y huso IANA con DST.
if nargin<5, zone='Europe/Madrid'; end
B=2*pi*(day(fecha,'dayofyear')-81)/364;
eot=9.87*sin(2*B)-7.53*cos(B)-1.5*sin(B); % minutos
if strcmp(direction,'civilToSolar')
    % Construir horas de reloj, evitando contar la hora extra/faltante de DST.
    local=datetime(year(fecha),month(fecha),day(fecha),floor(input), ...
        floor(mod(input,1)*60),mod(input*3600,60),'TimeZone',zone);
    value=input-hours(tzoffset(local))+longitude/15+eot/60;
else
    utc=datetime(year(fecha),month(fecha),day(fecha),'TimeZone','UTC') ...
        +hours(input-longitude/15-eot/60);
    utc.TimeZone=zone;
    value=input-longitude/15-eot/60+hours(tzoffset(utc));
end
end
