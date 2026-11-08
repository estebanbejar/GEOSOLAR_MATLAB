function verificarTemperaturaSeries()
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'temperatura_series_verificacion.txt'));d=onCleanup(@()diary('off'));
g=iniciarGeosolar('PersistLocation',false);guard=onCleanup(@()delete(g));g.selectLab(7,'Series horarias');h=g.Hourly;
assert(numel(h.Controls.series)==6&&h.Controls.series(6).Layout.Column==6&&strcmp(h.Controls.series(6).Text,'Temperatura (°C)'));
assert(numel(h.Axes.YAxis)==2&&contains(h.Axes.YAxis(2).Label.String,'°C'));
raw=h.Primary.Rows;yearRows=year(raw.Time)==2023;assert(abs(mean(raw.Temperature(yearRows))-h.Current.Summary.temperature)<1e-10);
for k=1:height(h.Current.Points)
    date=h.Current.Points.Time(k);chosen=dateshift(raw.Time,'start','day')==date;
    assert(abs(mean(raw.Temperature(chosen))-h.Current.Points.Temperature(k))<1e-10);
end
curve=findobj(h.Axes,'DisplayName','Temperatura del aire');assert(isequal(curve.YData(:),h.Current.Points.Temperature));
summary=h.Current.Summary;left=h.Axes.YAxis(1).Limits;right=h.Axes.YAxis(2).Limits;
h.Controls.series(6).ButtonPushedFcn([],[]);assert(strcmp(curve.Visible,'off')&&strcmp(h.Axes.YAxis(2).Visible,'off')&&strcmp(h.Controls.series(6).FontWeight,'normal'));
assert(isequal(h.Axes.YAxis(1).Limits,left)&&isequal(h.Current.Summary,summary));h.Controls.series(6).ButtonPushedFcn([],[]);assert(strcmp(curve.Visible,'on')&&isequal(h.Axes.YAxis(2).Limits,right));
h.Controls.start.Value=datetime(2023,6,21);h.setPeriod('day');chosen=dateshift(raw.Time,'start','day')==datetime(2023,6,21,'TimeZone','UTC');assert(isequal(h.Current.Points.Temperature,raw.Temperature(chosen)));
h.Controls.compare.Value=h.Files{2};h.update();assert(numel(findobj(h.Axes,'Type','line'))==6);h.navigate(1);assert(h.Controls.series(6).UserData);
h.exportData(fullfile(out,'series_horarias_temperatura.csv'));t=readtable(fullfile(out,'series_horarias_temperatura.csv'),'Delimiter',';','NumHeaderLines',3,'VariableNamingRule','preserve');assert(ismember('temperatura_aire_C',t.Properties.VariableNames)&&max(abs(t.temperatura_aire_C-h.Current.Points.Temperature))<1e-8);
h.exportPlot(fullfile(out,'series_horarias_temperatura_horaria.png'));h.capture(fullfile(out,'series_horarias_temperatura_suite.png'));assert(numel(findobj(h.Axes,'Type','line'))==6);
h.fullPeriod();h.Controls.mode.Value='yearly';h.update();assert(numel(findobj(h.Axes,'Type','bar'))==5&&numel(findobj(h.Axes,'Type','line'))==1);
for k=1:height(h.Current.Points)
    y=year(h.Current.Points.Time(k));assert(abs(h.Current.Points.Temperature(k)-mean(raw.Temperature(year(raw.Time)==y)))<1e-10);
end
h.exportPlot(fullfile(out,'series_horarias_temperatura_anual.png'));
h.Controls.mode.Value='monthly';h.update();assert(numel(h.Axes.YAxis)==2&&numel(findobj(h.Axes,'Type','bar'))==0);
for k=[1 2 12 14]
    date=h.Current.Points.Time(k);chosen=year(raw.Time)==year(date)&month(raw.Time)==month(date);assert(abs(h.Current.Points.Temperature(k)-mean(raw.Temperature(chosen)))<1e-10);
end
h.setSeriesVisible(6,false);h.Controls.mode.Value='yearly';h.update();assert(strcmp(h.Axes.YAxis(2).Visible,'off'));for k=1:5,h.setSeriesVisible(k,false);end;h.exportPlot(fullfile(out,'series_horarias_temperatura_ocultas.png'));
% Temperaturas negativas y medias, sin sumar ni sustituir ausencia por cero.
time=datetime(2020,1,1,0,30,0,'TimeZone','UTC')+hours((0:47)');temperature=[-10*ones(24,1);4*ones(24,1)];
sample=struct('Rows',table(time,ones(48,1),ones(48,1),ones(48,1),temperature,ones(48,1),'VariableNames',{'Time','Direct','Diffuse','Reflected','Temperature','Wind'}),'File','prueba');
a=geosolarhourly.aggregate(sample,datetime(2020,1,1),datetime(2020,1,2),'daily');assert(isequal(a.Points.Temperature,[-10;4]));
fig=figure('Visible','off');cleanup=onCleanup(@()delete(fig));ax=axes(fig);p=geosolarhourly.temperaturePlot(ax,a,true);assert(isgraphics(p)&&ax.YAxis(2).Limits(1)<-10&&ax.YAxis(2).Limits(2)>4);delete(cleanup);
sample.Rows.Temperature(:)=NaN;a=geosolarhourly.aggregate(sample,datetime(2020,1,1),datetime(2020,1,2),'daily');assert(all(isnan(a.Points.Temperature)));
fig=figure('Visible','off');cleanup=onCleanup(@()delete(fig));ax=axes(fig);p=geosolarhourly.temperaturePlot(ax,a,true);assert(~isgraphics(p));delete(cleanup);
delete(guard);disp('PASS: T2m horaria exacta y medias diarias/mensuales/anuales, eje derecho independiente con negativos, botón persistente, barras anuales, comparación, CSV/PNG y ausencia sin ceros.');
end
