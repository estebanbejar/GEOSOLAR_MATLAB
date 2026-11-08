function verificarNavegacionLeyenda(captures)
if nargin<1,captures=true;end
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'navegacion_leyenda_verificacion.txt'));d=onCleanup(@()diary('off'));
before=timerfindall;g=iniciarGeosolar('PersistLocation',false);guard=onCleanup(@()delete(g));g.selectLab(7,'Series horarias');h=g.Hourly;
assert(strcmp(h.Axes.Visible,'on'));
% Personalizado anual inicial: año anterior/siguiente, independientemente de resolución.
assert(strcmp(h.Controls.next.Enable,'off')&&strcmp(h.Controls.previous.Enable,'on'));
h.Controls.previous.ButtonPushedFcn([],[]);assert(h.Controls.start.Value==datetime(2022,1,1)&&h.Controls.finish.Value==datetime(2022,12,31));
h.Controls.next.ButtonPushedFcn([],[]);assert(h.Controls.start.Value==datetime(2023,1,1)&&h.Controls.finish.Value==datetime(2023,12,31));
h.Controls.mode.Value='yearly';h.update();h.navigate(-1);h.navigate(-1);h.navigate(-1);
assert(h.Controls.start.Value==datetime(2020,1,1)&&h.Controls.finish.Value==datetime(2020,12,31)&&h.Current.Summary.hours==8784&&strcmp(h.Current.Mode,'yearly'));
h.Controls.start.Value=datetime(2020,2,28);h.setPeriod('day');h.navigate(1);assert(h.Controls.start.Value==datetime(2020,2,29));h.navigate(1);assert(h.Controls.start.Value==datetime(2020,3,1));h.navigate(-1);assert(h.Controls.start.Value==datetime(2020,2,29));
h.Controls.start.Value=datetime(2020,2,27);h.setPeriod('week');h.navigate(1);assert(h.Controls.start.Value==datetime(2020,3,2)&&h.Controls.finish.Value==datetime(2020,3,8));h.navigate(-1);assert(h.Controls.start.Value==datetime(2020,2,24)&&h.Controls.finish.Value==datetime(2020,3,1));
h.Controls.start.Value=datetime(2020,1,31);h.setPeriod('month');h.navigate(1);assert(h.Controls.start.Value==datetime(2020,2,1)&&h.Controls.finish.Value==datetime(2020,2,29));h.navigate(1);h.navigate(-1);assert(h.Controls.finish.Value==datetime(2020,2,29));
h.setPeriod('custom');h.Controls.start.Value=datetime(2023,12,25);h.Controls.finish.Value=datetime(2023,12,30);h.update();h.navigate(1);
assert(h.Controls.start.Value==datetime(2023,12,31)&&h.Controls.finish.Value==datetime(2023,12,31)&&strcmp(h.Controls.next.Enable,'off'));
h.navigate(-1);assert(h.Controls.start.Value==datetime(2023,12,25)&&h.Controls.finish.Value==datetime(2023,12,30));
h.Controls.start.Value=datetime(2005,1,1);h.setPeriod('day');assert(strcmp(h.Controls.previous.Enable,'off'));h.navigate(-1);assert(h.Controls.start.Value==datetime(2005,1,1));
h.fullPeriod();assert(strcmp(h.Controls.previous.Enable,'off')&&strcmp(h.Controls.next.Enable,'off'));
h.Controls.mode.Value='yearly';h.update();h.setSeriesVisible(1,false);h.setSeriesVisible(3,false);
assert(strcmp(findobj(h.Axes,'DisplayName','Directa').Visible,'off')&&strcmp(findobj(h.Axes,'DisplayName','Reflejada').Visible,'off'));
assert(strcmp(h.Controls.series(5).Enable,'off'));
h.Controls.compare.Value=h.Files{2};h.update();assert(strcmp(h.Controls.series(5).Enable,'on')&&strcmp(findobj(h.Axes,'DisplayName','Directa').Visible,'off'));
summary=h.Current.Summary;tableData=h.DataTable.Data;h.Controls.series(4).ButtonPushedFcn(h.Controls.series(4),[]);
assert(strcmp(findobj(h.Axes,'DisplayName','Global (suma)').Visible,'off')&&isequal(h.Current.Summary,summary)&&isequal(h.DataTable.Data,tableData));
h.setSeriesVisible(5,false);h.setSeriesVisible(2,false);assert(all(strcmp({findobj(h.Axes,'Type','bar').Visible},'off')));
assert(isequal(h.Axes.YLim,[0 1]));h.exportPlot(fullfile(out,'series_horarias_todas_ocultas.png'));h.setSeriesVisible(1,true);assert(h.Axes.YLim(2)>1);
h.Controls.compare.Value='';h.update();assert(strcmp(h.Controls.series(5).Enable,'off')&&~h.Controls.series(5).UserData);
h.Controls.compare.Value=h.Files{2};h.update();assert(strcmp(h.Controls.series(5).Enable,'on')&&strcmp(findobj(h.Axes,'DisplayName','Global del CSV comparado').Visible,'off'));
for k=1:6,h.setSeriesVisible(k,true);end
h.Controls.start.Value=datetime(2023,6,21);h.setPeriod('day');h.setSeriesVisible(3,false);h.navigate(1);assert(~h.Controls.series(3).UserData&&strcmp(findobj(h.Axes,'DisplayName','Reflejada').Visible,'off'));
legendCount=numel(findall(g.Figure,'Type','legend'));h.exportPlot(fullfile(out,'series_horarias_leyenda_exportada.png'));assert(numel(findall(g.Figure,'Type','legend'))==legendCount);
assert(strcmp(h.Axes.Visible,'on'));png=imfinfo(fullfile(out,'series_horarias_leyenda_exportada.png'));assert(png.Width>400&&png.Height>200);
if captures
    drawnow;pause(.5);exportapp(g.Figure,fullfile(out,'series_horarias_navegacion.png'));
    g.Figure.WindowState='normal';g.Figure.Position=[30 30 1050 720];drawnow;pause(.5);exportapp(g.Figure,fullfile(out,'series_horarias_navegacion_1050.png'));
end
delete(guard);assert(numel(timerfindall)==numel(before));
disp('PASS: flechas en todos los periodos, límites, bisiesto, vuelta desde intervalo truncado, leyenda interactiva persistente, comparación, escala visible, datos intactos, PNG y cierre.');
end
