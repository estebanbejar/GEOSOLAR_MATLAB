function verificarEOSuite
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'eo_verificacion.txt'));d=onCleanup(@()diary('off'));
before=timerfindall;g=iniciarGeosolar('PersistLocation',false);c=onCleanup(@()delete(g));g.selectLab(4,'E–O');e=g.EO;
assert(e.Valid&&strcmp(g.NavigationButtons(4).Enable,'on'));assert(numel(findall(e.Axes(1),'Tag','fixedTable'))==2*e.State.n);
s=e.State;m=geosolarfixed.pv_este_oeste_modelo(s,datetime(2026,3,21),[9 12 15 0]);
assert(abs(m.width-2*s.L*cosd(s.beta)-.05)<1e-12&&abs(m.P-m.width-s.d)<1e-12);
assert(max(abs(m.incidencia(1,:)-fliplr(m.incidencia(3,:))))<1e-8);assert(all(isnan(m.incidencia(4,:))));
old=path;restore=onCleanup(@()path(old));addpath(fullfile(geosolar.referenceSourceRoot(),'src'));reference=pv_este_oeste_modelo(s,datetime(2026,3,21),[9 12 15]);
assert(isequaln(reference.fraccion,m.fraccion(1:3,:)));
e.setParameter('time',9);assert(e.Current.incidencia(1)>e.Current.incidencia(2));
e.setParameter('time',15);assert(e.Current.incidencia(2)>e.Current.incidencia(1));
table=e.DataTable.Data;assert(height(table)==97&&width(table)==2*s.n+5);
for face=1:2
    a=table.(sprintf('angulo_normal_%d_grados',face));b=table.(sprintf('angulo_plano_%d_grados',face));valid=isfinite(a);assert(max(abs(a(valid)+b(valid)-90))<1e-10);
end
e.setParameter('d',1.25);P=e.Current.P;e.setParameter('date','2026-06-21');assert(abs(e.Current.P-P)<1e-12);
for beta=[0 90 15]
    e.setParameter('beta',beta);assert(e.Valid);if beta==90,assert(abs(e.Current.LCR)<1e-12);end
end
% Ubicación común en ambas direcciones, sin cambiar el diseño de otros laboratorios.
e.setParameter('beta',25);design=g.Fixed.State.beta;g.setLocation(-33.45,-70.66,'Santiago');
assert(e.State.lat==-33.45&&g.Fixed.State.lat==-33.45&&g.State.lat==-33.45&&g.Location.lon==-70.66);
assert(g.Fixed.State.beta==design&&e.State.beta==25);e.reset();assert(e.State.lat==-33.45&&e.State.lon==-70.66&&strcmp(e.Controls.location.Value,'Santiago'));
g.selectLab(3,'Filas');assert(g.Fixed.Valid&&g.Fixed.State.lon==-70.66);g.Fixed.setParameter('lon',-71);assert(e.State.lon==-71);
g.selectLab(2,'Geometría');assert(g.State.lat==-33.45&&g.Controls.lat.Field.Value==-33.45);g.setParameter('lat',-25);assert(e.State.lat==-25&&g.Fixed.State.lat==-25);
g.selectLab(4,'E–O');assert(e.Valid);e.setParameter('n',1);assert(size(e.Daily.fraccionGeometrica,2)==2);
p=s;p.n=1;single=geosolarfixed.pv_este_oeste_modelo(p,datetime(2026,3,21),[9 12 15]);assert(all(single.fraccionGeometrica==0,'all'));
e.reset();e.setParameter('alpha',30);e.saveScenario(fullfile(out,'eo_escenario.json'));saved=e.State;e.reset();e.loadScenario(fullfile(out,'eo_escenario.json'));assert(isequal(e.State,saved));
e.exportCsv(fullfile(out,'eo_diario.csv'));csv=readtable(fullfile(out,'eo_diario.csv'),'Delimiter',';','NumHeaderLines',3);assert(height(csv)==97&&width(csv)==2*e.State.n+5);
t=e.State.time;g.toggle();pause(.7);g.stop();assert(e.State.time>t&&strlength(g.LastError)==0);
e.setParameter('beta',100);assert(~e.Valid);e.reset();assert(e.Valid);
g.setLocation(40,-5,'Punto de referencia');e.reset();drawnow;pause(1);exportapp(g.Figure,fullfile(out,'eo_suite.png'));
for k=1:3,exportgraphics(e.Axes(k),fullfile(out,sprintf('eo_%02d.png',k)),'Resolution',160);end
e.setParameter('time',0);exportgraphics(e.Axes(1),fullfile(out,'eo_noche.png'),'Resolution',160);
g.setLocation(-40,-70,'Hemisferio sur');e.setParameter('date','2026-06-21');e.setParameter('time',9);exportgraphics(e.Axes(1),fullfile(out,'eo_sur.png'),'Resolution',160);
g.Figure.WindowState='normal';g.Figure.Position=[30 30 1050 720];drawnow;pause(.5);exportapp(g.Figure,fullfile(out,'eo_1050.png'));
delete(c);assert(numel(timerfindall)==numel(before));
% Persistencia aislada, sin alterar la ubicación personal de la suite.
locationFile=[tempname(out) '.json'];g=iniciarGeosolar('LocationFile',locationFile);c=onCleanup(@()delete(g));g.setLocation(37.4,-6.4,'Prueba persistente');delete(c);
g=iniciarGeosolar('LocationFile',locationFile);c=onCleanup(@()delete(g));assert(g.Location.lat==37.4&&g.EO.State.lon==-6.4&&g.State.lat==37.4);delete(c);
assert(numel(timerfindall)==numel(before));disp('PASS: E–O, modelo original, dos caras, extremos, sombras, ángulos, ubicación compartida/persistente, reset, JSON, CSV, PNG, animación y cierre.');
end
