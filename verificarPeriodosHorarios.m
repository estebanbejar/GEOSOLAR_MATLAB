function verificarPeriodosHorarios()
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'periodos_horarios_verificacion.txt'));d=onCleanup(@()diary('off'));
assert(~ismember('monthly',geosolarhourly.resolutionModes(datetime(2020,2,1),datetime(2020,2,28))));
assert(ismember('monthly',geosolarhourly.resolutionModes(datetime(2020,2,1),datetime(2020,2,29))));
assert(ismember('monthly',geosolarhourly.resolutionModes(datetime(2021,2,1),datetime(2021,2,28))));
assert(~ismember('yearly',geosolarhourly.resolutionModes(datetime(2020,1,1),datetime(2020,12,30))));
assert(ismember('yearly',geosolarhourly.resolutionModes(datetime(2020,1,1),datetime(2020,12,31))));
assert(ismember('hourly',geosolarhourly.resolutionModes(datetime(2023,1,1),datetime(2023,1,31))));
assert(~ismember('hourly',geosolarhourly.resolutionModes(datetime(2023,1,1),datetime(2023,2,1))));
g=iniciarGeosolar('PersistLocation',false);guard=onCleanup(@()delete(g));g.selectLab(7,'Series horarias');h=g.Hourly;
h.Controls.start.Value=datetime(2020,2,15);h.setPeriod('day');assert(h.Current.Summary.hours==24&&strcmp(h.Current.Mode,'hourly')&&h.Controls.start.Value==h.Controls.finish.Value);
assert(~ismember('monthly',h.Controls.mode.ItemsData)&&~ismember('yearly',h.Controls.mode.ItemsData));
h.setPeriod('week');assert(weekday(h.Controls.start.Value)==2&&weekday(h.Controls.finish.Value)==1&&h.Current.Summary.hours==168&&strcmp(h.Current.Mode,'hourly'));
h.Controls.start.Value=datetime(2020,2,15);h.setPeriod('month');assert(h.Controls.start.Value==datetime(2020,2,1)&&h.Controls.finish.Value==datetime(2020,2,29)&&h.Current.Summary.hours==696);
assert(ismember('monthly',h.Controls.mode.ItemsData)&&strcmp(h.Current.Mode,'hourly'));
h.Controls.mode.Value='monthly';h.update();assert(height(h.Current.Points)==1);
h.setPeriod('day');assert(strcmp(h.Current.Mode,'hourly')&&~ismember('monthly',h.Controls.mode.ItemsData));
h.Controls.start.Value=datetime(2023,5,20);h.setPeriod('month');assert(h.Current.Summary.hours==744&&strcmp(h.Current.Mode,'hourly'));
h.setPeriod('custom');assert(strcmp(h.Controls.finish.Enable,'on'));
h.Controls.start.Value=datetime(2023,1,1);h.Controls.finish.Value=datetime(2023,12,31);h.update();assert(ismember('yearly',h.Controls.mode.ItemsData)&&~ismember('hourly',h.Controls.mode.ItemsData));
h.Controls.mode.Value='yearly';h.update();assert(height(h.Current.Points)==1&&h.Current.Points.Records==8760);
bars=findobj(h.Axes,'Type','bar');assert(numel(bars)==4);
h.fullPeriod();h.Controls.mode.Value='yearly';h.Controls.compare.Value=h.Files{2};h.update();assert(height(h.Current.Points)==19&&height(h.Comparison.Points)==19);
a=h.Current;assert(a.Points.Records(year(a.Points.Time)==2020)==8784);h.Controls.mode.Value='monthly';h.update();m=h.Current;
for y=2005:2023,assert(abs(sum(m.Points.Global(year(m.Points.Time)==y))-a.Points.Global(year(a.Points.Time)==y))<1e-7);end
h.Controls.mode.Value='yearly';h.update();h.exportData(fullfile(out,'series_horarias_anual.csv'));t=readtable(fullfile(out,'series_horarias_anual.csv'),'Delimiter',';','NumHeaderLines',3,'VariableNamingRule','preserve');assert(height(t)==19);
drawnow;exportgraphics(h.Axes,fullfile(out,'series_horarias_anual.png'),'Resolution',150);exportapp(g.Figure,fullfile(out,'series_horarias_periodos.png'));
% El modelo también rechaza una resolución no permitida si se invoca sin UI.
failed=false;try,geosolarhourly.aggregate(h.Primary,datetime(2023,1,1),datetime(2023,1,7),'monthly');catch,failed=true;end;assert(failed);
failed=false;try,geosolarhourly.aggregate(h.Primary,datetime(2023,1,1),datetime(2023,6,30),'yearly');catch,failed=true;end;assert(failed);
h.Controls.start.Value=datetime(2023,1,2);h.Controls.finish.Value=datetime(2023,1,1);h.update();assert(isempty(h.Current));
delete(guard);disp('PASS: periodos diario/semanal/mensual/personalizado/completo; resoluciones adaptativas; meses de 28/29/31 días; año bisiesto; anual = suma mensual; comparación y CSV anual.');
end
