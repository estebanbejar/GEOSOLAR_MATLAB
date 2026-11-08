function verificarBarrasAnualesLeyenda()
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'barras_anuales_verificacion.txt'));d=onCleanup(@()diary('off'));
g=iniciarGeosolar('PersistLocation',false);guard=onCleanup(@()delete(g));g.selectLab(7,'Series horarias');h=g.Hourly;
[~,order]=sort(arrayfun(@(b)b.Layout.Column,h.Controls.series));assert(isequal(order,[4 1 2 3 5 6]));
assert(isequal({h.Controls.series(order).Text},{'Global','Directa','Difusa','Reflejada','Global comparada','Temperatura (°C)'}));
for k=1:4,assert(strcmp(h.Controls.series(k).FontWeight,'bold')&&isequal(h.Controls.series(k).BackgroundColor,[1 1 1]));end
h.Controls.series(2).ButtonPushedFcn([],[]);assert(strcmp(h.Controls.series(2).FontWeight,'normal')&&isequal(h.Controls.series(2).BackgroundColor,[.85 .85 .85]));h.Controls.series(2).ButtonPushedFcn([],[]);
h.Controls.mode.Value='yearly';h.update();assert(~isempty(h.Current)&&height(h.Current.Points)==1);
bars=findobj(h.Axes,'Type','bar');assert(numel(bars)==4);b=findobj(h.Axes,'DisplayName','Global (suma)');assert(isequal(b.YData(:),h.Current.Points.Global));
h.fullPeriod();h.Controls.mode.Value='yearly';h.Controls.compare.Value=h.Files{2};h.update();assert(numel(findobj(h.Axes,'Type','bar'))==5&&numel(findobj(h.Axes,'Type','line'))==1);
assert(isequal(findobj(h.Axes,'DisplayName','Global (suma)').YData(:),h.Current.Points.Global));
assert(isequal(findobj(h.Axes,'DisplayName','Global del CSV comparado').YData(:),h.Comparison.Points.Global));
summary=h.Current.Summary;tableData=h.DataTable.Data;h.setSeriesVisible(3,false);assert(strcmp(findobj(h.Axes,'DisplayName','Reflejada').Visible,'off')&&isequal(summary,h.Current.Summary)&&isequal(tableData,h.DataTable.Data));
h.exportPlot(fullfile(out,'series_horarias_barras_anuales.png'));drawnow;pause(.5);exportapp(g.Figure,fullfile(out,'series_horarias_barras_suite.png'));
for k=1:6,h.setSeriesVisible(k,false);end
assert(isequal(h.Axes.YLim,[0 1]));h.exportPlot(fullfile(out,'series_horarias_barras_ocultas.png'));
for k=1:6,h.setSeriesVisible(k,true);end
h.Controls.start.Value=datetime(2023,6,21);h.setPeriod('day');assert(numel(findobj(h.Axes,'Type','line'))==6&&isempty(findobj(h.Axes,'Type','bar')));
h.exportPlot(fullfile(out,'series_horarias_lineas_tras_barras.png'));h.fullPeriod();h.Controls.mode.Value='yearly';h.update();assert(numel(findobj(h.Axes,'Type','bar'))==5);
% Coberturas distintas: ausencia de un año comparado debe quedar NaN.
a=h.Current;c=h.Comparison;c.Points=c.Points(2:end,:);fig=figure('Visible','off');cleanup=onCleanup(@()delete(fig));ax=axes(fig);handles=geosolarhourly.annualBars(ax,a,c);assert(isnan(handles(5).YData(1))&&isequal(handles(5).YData(2:end)',c.Points.Global));delete(cleanup);
delete(guard);disp('PASS: orden Global/Directa/Difusa/Reflejada; negrita y blanco activas, normal y gris ocultas; barras anuales exactas, un año y 19 años, comparación con huecos, PNG y retorno a líneas.');
end
