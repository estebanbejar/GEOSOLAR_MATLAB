function result=aggregate(data,startDate,endDate,mode)
% Agregación original sin interpolar, ampliada con anual y límites de periodo.
startDate=datetime(year(startDate),month(startDate),day(startDate),'TimeZone','UTC');
endDate=datetime(year(endDate),month(endDate),day(endDate),'TimeZone','UTC');mode=char(mode);
assert(startDate<=endDate,'geosolar:hourlyRange','La fecha inicial debe ser anterior o igual a la final.');
assert(ismember(mode,{'hourly','daily','monthly','yearly'}),'geosolar:hourlyMode','Resolución desconocida.');
t=data.Rows;selected=t.Time>=startDate&t.Time<endDate+days(1);t=t(selected,:);
assert(~isempty(t),'geosolar:hourlyPeriod','No hay datos en el periodo seleccionado.');
first=max(startDate,dateshift(t.Time(1),'start','day'));last=min(endDate,dateshift(t.Time(end),'start','day'));
allowed=geosolarhourly.resolutionModes(first,last);
assert(ismember(mode,allowed),'geosolar:hourlyResolution','Resolución incompatible: horaria hasta 31 días; mensual desde un mes; anual desde un año de datos.');
components=[t.Direct t.Diffuse t.Reflected];
switch mode
    case 'hourly',group=t.Time;units='W/m²';
    case 'daily',group=dateshift(t.Time,'start','day');units='kWh/m²';
    case 'monthly',group=dateshift(t.Time,'start','month');units='kWh/m²';
    case 'yearly',group=dateshift(t.Time,'start','year');units='kWh/m²';
end
[times,~,id]=unique(group);n=numel(times);values=zeros(n,3);
for k=1:3,values(:,k)=accumarray(id,components(:,k),[n 1]);end
if ~strcmp(mode,'hourly'),values=values/1000;end
records=accumarray(id,ones(height(t),1),[n 1]);
points=table(times,values(:,1),values(:,2),values(:,3),sum(values,2),records, ...
    'VariableNames',{'Time','Direct','Diffuse','Reflected','Global','Records'});
valid=isfinite(t.Temperature);sums=accumarray(id(valid),t.Temperature(valid),[n 1]);counts=accumarray(id(valid),ones(nnz(valid),1),[n 1]);
temperature=sums./counts;temperature(counts==0)=NaN;points.Temperature=temperature;
summary=struct('hours',height(t),'irradiation',sum(components,'all')/1000, ...
    'components',sum(components,1)/1000,'peak',max(sum(components,2)), ...
    'temperature',mean(t.Temperature,'omitnan'),'wind',mean(t.Wind,'omitnan'),'first',t.Time(1),'last',t.Time(end));
result=struct('Points',points,'Units',units,'Summary',summary,'File',data.File,'Mode',mode);
end
