function verificarFilasSuite
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'filas_verificacion.txt'));d=onCleanup(@()diary('off'));
before=timerfindall;g=iniciarGeosolar('PersistLocation',false);c=onCleanup(@()delete(g));g.setLocation(40,-5,'Referencia de prueba');g.selectLab(3,'Filas');f=g.Fixed;assert(f.Valid&&strcmp(g.NavigationButtons(3).Enable,'on'));
s=f.State;m=geosolarfixed.pv_filas_modelo(s,datetime(s.date),[9 10.5 12 13.5 15]);
assert(abs(m.d-2.15828)<1e-4&&abs(m.LCR-.44523)<1e-4);assert(max(m.fraccion(2:4,:),[],'all')<1e-8);assert(any(m.fraccion([1 5],:)>0,'all'));
originalPath=path;restore=onCleanup(@()path(originalPath));addpath(fullfile(geosolar.referenceSourceRoot(),'src'));
reference=pv_filas_modelo(s,datetime(s.date),[9 12 15]);actual=geosolarfixed.pv_filas_modelo(s,datetime(s.date),[9 12 15]);assert(isequaln(reference.fraccion,actual.fraccion)&&reference.P==actual.P);
t=f.DataTable.Data;assert(height(t)==97);valid=isfinite(t.angulo_plano_grados);assert(max(abs(t.angulo_normal_grados(valid)+t.angulo_plano_grados(valid)-90))<1e-12);
P=f.Current.P;f.setParameter('date','2026-07-21');assert(f.Valid&&abs(f.Current.P-P)<1e-12);
f.setParameter('time',18.86);assert(f.Current.posterior&&all(f.Current.fraccion==1)&&f.Current.incidencia<0);
f.setParameter('time',0);assert(f.Current.alt<0&&all(isnan(f.Current.fraccion)));
f.reset();f.setParameter('reference','civil');civil=f.State.time;assert(civil>13&&civil<14);f.setParameter('reference','solar');assert(abs(f.State.time-12)<1e-8);
f.setParameter('n',1);assert(max(f.Daily.fraccionGeometrica,[],'all')==0);f.setParameter('beta',0);assert(f.Current.d==0&&f.Current.LCR==1);
f.reset();f.setParameter('camera',70);f.setParameter('time',9);[az,~]=view(f.Axes(1));assert(abs(az-70)<1e-10);
f.saveScenario(fullfile(out,'filas_escenario.json'));saved=f.State;f.reset();f.loadScenario(fullfile(out,'filas_escenario.json'));assert(isequal(f.State,saved));
f.exportCsv(fullfile(out,'filas_diario.csv'));csv=readtable(fullfile(out,'filas_diario.csv'),'Delimiter',';','NumHeaderLines',3);assert(height(csv)==97&&width(csv)==f.State.n+3);
snapshot=f.State;g.selectLab(2,'Geometría');g.setParameter('lat',-20);g.selectLab(1,'Órbita');g.Orbit.selectDay(200);g.selectLab(3,'Filas');assert(isequal(rmfield(f.State,{'lat','lon','zone'}),rmfield(snapshot,{'lat','lon','zone'}))&&f.State.lat==-20);
start=f.State.time;g.toggle();pause(.7);g.stop();assert(f.State.time>start&&strlength(g.LastError)==0);
assert(numel(findall(f.Axes(3),'Tag','selectedHour'))==1);
f.setParameter('lat',65);assert(~f.Valid&&isempty(f.DataTable.Data));g.toggle();assert(~g.Playing);g.setLocation(40,-5,'Punto seleccionado');f.reset();assert(f.Valid);
drawnow;pause(1);exportapp(g.Figure,fullfile(out,'filas_suite.png'));
for k=1:3,exportgraphics(f.Axes(k),fullfile(out,sprintf('filas_%02d.png',k)),'Resolution',160);end
f.setParameter('date','2026-07-21');f.setParameter('time',18.86);exportgraphics(f.Axes(1),fullfile(out,'filas_posterior.png'),'Resolution',160);
f.setParameter('time',0);exportgraphics(f.Axes(1),fullfile(out,'filas_noche.png'),'Resolution',160);
f.reset();g.Figure.WindowState='normal';g.Figure.Position=[30 30 1050 720];drawnow;pause(.5);exportapp(g.Figure,fullfile(out,'filas_1050.png'));
delete(c);assert(numel(timerfindall)==numel(before));disp('PASS: referencia original, diseño invernal, sombras, incidencia, noche, hora civil, estados, animación, errores, JSON, CSV, PNG y cierre.');
end
