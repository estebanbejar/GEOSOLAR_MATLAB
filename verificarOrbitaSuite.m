function verificarOrbitaSuite
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'orbita_verificacion.txt'));d=onCleanup(@()diary('off'));
before=timerfindall;g=iniciarGeosolar('PersistLocation',false);c=onCleanup(@()delete(g));assert(g.ActiveLab==1);o=g.Orbit;
p=geosolarorbit.state(0:364);assert(max(abs(p.eccentricAnomaly-p.eccentricity*sin(p.eccentricAnomaly)-p.meanAnomaly))<1e-12);
ev=geosolarorbit.events;p=geosolarorbit.state(ev.time(1:4));assert(max(abs(p.declination-[0 23.44 0 -23.44]))<1e-10);
assert(abs(geosolarorbit.state(2).distance-.9833)<1e-12);assert(abs(geosolarorbit.state(184.5).distance-1.0167)<1e-12);
objects=findall(o.OrbitAxes);
for k=1:6
    o.selectDay(ev.time(k)+1);assert(abs(o.TimeDays-ev.time(k))<1e-12);
    m=findobj(o.TimeAxes,'Type','line','Marker','o');assert(abs(m.YData-geosolarorbit.equationOfTime(ev.time(k)))<1e-12);
end
assert(isequal(objects,findall(o.OrbitAxes)),'Se recrearon objetos orbitales');
o.Controls.Camera.Value='Vista superior';o.Controls.Camera.ValueChangedFcn([],[]);[~,el]=view(o.OrbitAxes);assert(el==90);
o.selectDay(90.5);[~,el]=view(o.OrbitAxes);assert(el==90);
o.Controls.Repeat.Value=false;o.selectDay(365);o.advance(2);assert(o.TimeDays==364&&~g.Playing);
o.Controls.Repeat.Value=true;o.advance(2);assert(o.TimeDays==2);
o.reset();g.toggle();pause(.7);g.stop();assert(o.TimeDays>78&&strlength(g.LastError)==0);
t=o.TimeDays;g.selectLab(2,'Geometría');assert(~g.Playing);g.setParameter('lat',-32);basic=g.State;
g.selectLab(1,'Órbita');assert(o.TimeDays==t);o.reset();g.selectLab(2,'Geometría');assert(isequal(g.State,basic));g.selectLab(1,'Órbita');
o.selectDay(171.25);o.saveScenario(fullfile(out,'orbita_escenario.json'));o.reset();o.loadScenario(fullfile(out,'orbita_escenario.json'));assert(o.TimeDays==170.25);
o.exportCsv(fullfile(out,'orbita_anual.csv'));table=readtable(fullfile(out,'orbita_anual.csv'),'Delimiter',';','NumHeaderLines',3);assert(height(table)==365);
assert(max(abs(table.ET_min-geosolarorbit.equationOfTime(0:364)'))<1e-10);
o.reset();drawnow;pause(1);exportapp(g.Figure,fullfile(out,'orbita_suite.png'));
exportgraphics(o.OrbitAxes,fullfile(out,'orbita_escena.png'),'Resolution',160);
exportgraphics(o.CurveAxes,fullfile(out,'orbita_declinacion.png'),'Resolution',160);
exportgraphics(o.TimeAxes,fullfile(out,'orbita_ET.png'),'Resolution',160);
g.Figure.WindowState='normal';g.Figure.Position=[30 30 1050 720];drawnow;pause(.5);exportapp(g.Figure,fullfile(out,'orbita_1050.png'));
delete(c);assert(numel(timerfindall)==numel(before));disp('PASS: órbita, eventos, cámara, animación, navegación, estados independientes, JSON, CSV, PNG y limpieza.');
end
