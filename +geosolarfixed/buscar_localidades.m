function results = buscar_localidades(query)
% Named settlements/postcodes, Open-Meteo GeoNames search. No API key.
% Called only on explicit search; cached for this MATLAB session.
query=strtrim(char(query));
if numel(query)<2 || numel(query)>150,error('ubicacion:query','Escriba entre 2 y 150 caracteres.');end
persistent cache
if isempty(cache),cache=containers.Map('KeyType','char','ValueType','any');end
key=lower(query);if isKey(cache,key),results=cache(key);return;end
data=webread('https://geocoding-api.open-meteo.com/v1/search','name',query, ...
    'count',10,'language','es','format','json',weboptions('Timeout',20,'ContentType','json'));
results=struct('name',{},'lat',{},'lon',{},'admin1',{},'admin2',{},'country',{});
if isfield(data,'results')
    for i=1:numel(data.results)
        if iscell(data.results),r=data.results{i};else,r=data.results(i);end
        if ~isfield(r,'latitude')||~isfield(r,'longitude')||~isfield(r,'name'),continue;end
        results(end+1)=struct('name',char(r.name),'lat',r.latitude,'lon',r.longitude, ...
            'admin1',field(r,'admin1'),'admin2',field(r,'admin2'),'country',field(r,'country')); %#ok<AGROW>
    end
end
cache(key)=results;
end
function value=field(s,key)
value='';if isfield(s,key),value=char(s.(key));end
end
