function data=readSeries(file)
% Traducción del lector de pvgis_hourly/dashboard_pvgis.py. CSV intacto, UTC.
lines=readlines(file,'Encoding','UTF-8','EmptyLineRule','read');lines=erase(lines,char(65279));
head=find(startsWith(lower(strtrim(lines)),"time,"),1);
assert(~isempty(head),'geosolar:hourlyHeader','No se encuentra la tabla horaria PVGIS.');
columns=strtrim(split(lines(head),','))';required=["time","Gb(i)","Gd(i)","Gr(i)"];
assert(all(ismember(required,columns))&&columns(1)=="time",'geosolar:hourlyColumns','Faltan time, Gb(i), Gd(i) o Gr(i).');
tail=lines(head+1:end);matches=~cellfun('isempty',regexp(cellstr(tail),'^\d{8}:\d{4},','once'));
stop=find(~matches,1);if isempty(stop),count=numel(tail);else,count=stop-1;end
assert(count>0,'geosolar:hourlyEmpty','La tabla no contiene registros horarios.');
% Un registro truncado/mal formado en mitad de la serie no puede ocultar datos.
assert(~any(matches(count+1:end)),'geosolar:hourlyRows','Hay filas no válidas dentro de la serie horaria.');
block=strjoin(tail(1:count),newline);format=['%s' repmat('%f',1,numel(columns)-1)];
c=textscan(char(block),format,'Delimiter',',','ReturnOnError',false,'EmptyValue',NaN);
assert(all(cellfun(@numel,c)==count),'geosolar:hourlyRows','Una fila tiene columnas incompletas.');
time=datetime(c{1},'InputFormat','yyyyMMdd:HHmm','TimeZone','UTC');
assert(~any(isnat(time))&&all(diff(time)==hours(1)),'geosolar:hourlyContinuity','La serie contiene huecos, duplicados o marcas horarias desordenadas.');
values=zeros(count,5);needed=["Gb(i)","Gd(i)","Gr(i)","T2m","WS10m"];
for k=1:5
    index=find(columns==needed(k),1);
    if isempty(index),values(:,k)=NaN;
    else
        values(:,k)=c{index};assert(all(isfinite(values(:,k))),'geosolar:hourlyFinite','El CSV contiene valores no finitos en %s.',needed(k));
    end
end
tableData=table(time,values(:,1),values(:,2),values(:,3),values(:,4),values(:,5), ...
    'VariableNames',{'Time','Direct','Diffuse','Reflected','Temperature','Wind'});
data=struct('File',char(file),'Rows',tableData,'Metadata',lines(1:head-1),'Footer',tail(count+1:end),'Columns',columns);
end
