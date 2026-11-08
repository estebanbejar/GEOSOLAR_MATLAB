function verificarSeguimientoSuite
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'seguimiento_verificacion.txt'));diaryGuard=onCleanup(@()diary('off'));
before=timerfindall;g=iniciarGeosolar('PersistLocation',false);guard=onCleanup(@()delete(g));g.selectLab(5,'Seguimiento');t=g.Tracking;assert(t.Valid&&strcmp(g.NavigationButtons(5).Enable,'on'));
old=path;restore=onCleanup(@()path(old));addpath(fullfile(geosolar.referenceSourceRoot(),'src'));
p=t.physical();assert(strcmp(t.State.spacing,'manual')&&t.State.gcr==50);reference=pv_seguidor_diseno(p,.5);assert(abs(reference.P-t.Design.P)<1e-12&&reference.clearance==t.Design.clearance);
sun=pv_seguidor_solar(p.lat,datetime(p.date),[9 12 15]);ref=pv_seguidor_estado(p,sun,reference.P,false);actual=geosolartracking.pv_seguidor_estado(p,sun,reference.P,false);
assert(isequaln(ref,actual));
assert(abs(t.FreeHours-pv_seguidor_horas_libres(p,datetime(p.date),reference.P,false))<1e-12);
P=t.Design.P;t.setParameter('bt','yes');assert(t.Valid&&abs(t.Design.P-P)<1e-12);assert(all(t.Daily.track.geometric(t.Daily.track.front)<1e-8));
t.setParameter('gcr',40);assert(strcmp(t.State.spacing,'manual')&&abs(t.Design.P-5)<1e-12);
t.setParameter('ns',5);t.setParameter('eo',-3);p=t.physical();P=t.Design.P;clearance=t.Design.clearance;
t.setParameter('slopeUnits','percent');assert(abs(t.State.ns-100*tand(5))<1e-10);assert(abs(t.physical().ns-p.ns)<1e-10&&abs(t.Design.P-P)<1e-10&&abs(t.Design.clearance-clearance)<1e-10);
t.setParameter('slopeUnits','degrees');assert(abs(t.State.ns-5)<1e-10);
table=t.DataTable.Data;valid=isfinite(table.angulo_plano_grados);assert(max(abs(table.angulo_normal_grados(valid)+table.angulo_plano_grados(valid)-90))<1e-10);
assert(height(t.MonthlyData)==97&&width(t.MonthlyData)==25);assert(numel(findobj(t.MonthlyAxes(1),'Type','line'))==12&&numel(findobj(t.MonthlyAxes(2),'Type','line'))==12);
t.setParameter('time',0);assert(isnan(t.Current.track.theta)&&all(isnan(t.Current.fraccion)));
t.Controls.DatePresets.June.ButtonPushedFcn([],[]);assert(strcmp(t.State.date,'2026-06-21'));
t.setParameter('h',.1);assert(~t.Valid&&isempty(t.DataTable.Data));t.reset();assert(t.Valid&&height(t.MonthlyData)==97);
g.setLocation(-33.4,-70.6,'Sur');assert(t.Valid&&t.State.lat==-33.4&&g.Fixed.State.lon==-70.6&&g.EO.State.lat==-33.4);
t.setParameter('date','2026-06-21');t.setParameter('time',9);assert(t.Current.track.theta<0);
snapshot=t.State;g.selectLab(3,'Filas');g.selectLab(4,'E–O');g.selectLab(5,'Seguimiento');assert(isequal(t.State,snapshot));
t.saveScenario(fullfile(out,'seguimiento_escenario.json'));t.setParameter('bt','yes');t.loadScenario(fullfile(out,'seguimiento_escenario.json'));assert(isequal(t.State,snapshot));
t.exportCsv(fullfile(out,'seguimiento_diario.csv'));t.exportMonthly(fullfile(out,'seguimiento_mensual.csv'));
csv=readtable(fullfile(out,'seguimiento_diario.csv'),'Delimiter',';','NumHeaderLines',3);assert(height(csv)==97&&width(csv)==t.State.n+3);
monthly=readtable(fullfile(out,'seguimiento_mensual.csv'),'Delimiter',';','NumHeaderLines',3);assert(height(monthly)==97&&width(monthly)==25);
start=t.State.time;g.toggle();pause(.6);g.stop();assert(t.State.time>start&&strlength(g.LastError)==0);
g.setLocation(40,-5,'Referencia');t.reset();drawnow;pause(1);exportapp(g.Figure,fullfile(out,'seguimiento_suite.png'));
for k=1:3,exportgraphics(t.Axes(k),fullfile(out,sprintf('seguimiento_%02d.png',k)),'Resolution',160);end
for k=1:2,exportgraphics(t.MonthlyAxes(k),fullfile(out,sprintf('seguimiento_mensual_%d.png',k)),'Resolution',160);end
% TMY real ya descargado; misma ruta de carga/validación de la aplicación.
met=geosolartracking.pv_seguidor_tmy(40,-5);assert(size(met.sun,1)==8760);t.calculateAnnual(met);r=t.AnnualResult;assert(~isempty(r)&&all(isfinite(r.H),'all'));
assert(t.AnnualAxes.XLim(2)>=max(r.inverseGCR)&&t.AnnualAxes.YLim(2)>max(r.H,[],'all'));
expected=pv_seguidor_anual(t.physical(),met,r.inverseGCR([1,end]));assert(max(abs(expected.H-r.H([1,end],:)),[],'all')<1e-9);
t.exportAnnual(fullfile(out,'seguimiento_anual.csv'));annual=readtable(fullfile(out,'seguimiento_anual.csv'),'Delimiter','\t');assert(height(annual)==numel(r.inverseGCR));
exportgraphics(t.AnnualAxes,fullfile(out,'seguimiento_anual.png'),'Resolution',160);
g.selectLab(1,'Órbita');g.selectLab(5,'Seguimiento');assert(isequal(t.AnnualResult,r));
t.setParameter('L',2.1);assert(~isempty(t.AnnualResult)&&~isempty(t.TMYData)&&strcmp(t.AnnualExport.Enable,'on'));
g.Figure.WindowState='normal';g.Figure.Position=[30 30 1050 720];drawnow;pause(.5);exportapp(g.Figure,fullfile(out,'seguimiento_1050.png'));
delete(guard);assert(numel(timerfindall)==numel(before));disp('PASS: seguimiento, modelo original, BT, GCR, pendientes/unidades, altura libre, horas sin sombras, mensual, TMY real/anual, ubicación, JSON, CSV, animación y cierre.');
end
