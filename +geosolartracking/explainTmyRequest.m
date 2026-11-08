function explainTmyRequest(url,lat,lon,original)
% webread omite el cuerpo del error HTTP; recuperarlo solo para explicar un 400.
detail='';
try
    request=matlab.net.http.RequestMessage('GET');
    response=request.send(matlab.net.URI(url),matlab.net.http.HTTPOptions('ConnectTimeout',10,'ResponseTimeout',20));
    data=response.Body.Data;
    if ischar(data)||isstring(data),data=jsondecode(char(data));end
    if isstruct(data)&&isfield(data,'message'),detail=char(string(data.message));end
catch
    % La recuperación del mensaje no debe ocultar la petición original fallida.
end
if contains(lower(detail),'location over the sea')
    reason='PVGIS indica que el punto está en el mar y no puede generar un TMY para él.';
elseif isempty(detail)
    reason='PVGIS ha rechazado esta ubicación (HTTP 400). Compruebe que el emplazamiento dispone de datos.';
else
    reason=['PVGIS indica: ' detail];
end
err=MException('geosolar:tmyLocation', ...
    'No se puede cargar el TMY para latitud %+.6f°, longitud %+.6f°.\n%s\nRevise la ubicación compartida en el mapa o las coordenadas; no se ha cambiado automáticamente.',lat,lon,reason);
err=addCause(err,original);throwAsCaller(err);
end
