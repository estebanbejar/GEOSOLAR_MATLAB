function verificarGeosolar
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');if ~isfolder(out),mkdir(out);end
diary(fullfile(out,'verificacion.txt'));cleanupDiary=onCleanup(@()diary('off'));
before=timerfindall;
foreignClock=timer('Name','GEOSOLAR_test_foreign','ExecutionMode','fixedSpacing','Period',1,'TimerFcn',@(~,~)0);
foreignCleanup=onCleanup(@()delete(foreignClock));start(foreignClock);
app=iniciarGeosolar('Visible','off','PersistLocation',false);cleanup=onCleanup(@()delete(app));
assert(app.ActiveLab==1);app.selectLab(2,'Geometría');
assert(strcmp(app.Figure.WindowState,'maximized'));
assert(numel(app.Axes)==6&&strcmp(app.State.mode,'date'));
assert(strcmp(app.NavigationButtons(6).Enable,'on')&&strcmp(app.NavigationButtons(7).Enable,'on'));
assert(strcmp(app.NavigationButtons(1).Enable,'on'));
assert(strcmp(app.NavigationButtons(2).Enable,'on'));
assert(all(arrayfun(@(ax)strcmp(ax.Toolbar.Visible,'off'),app.Axes)));
beforeNavigation=app.State;
app.selectLab(9,'No implementado');
assert(isequal(app.State,beforeNavigation)&&isvalid(app.Figure));
assert(~isempty(app.Axes(2).ButtonDownFcn)&&~isempty(app.Figure.WindowButtonMotionFcn));
app.Axes(2).ButtonDownFcn([],[]);app.Figure.WindowButtonMotionFcn([],[]);app.Figure.WindowButtonUpFcn([],[]);
app.setParameter('camera',75);
assert(abs(app.State.camera-75)<1e-8);
app.setParameter('time',9);[az,el]=view(app.Axes(2));assert(abs(az-75)<1e-8&&abs(el-22)<1e-8);
assert(strcmp(app.Axes(4).Visible,'off'));
assert(numel(findobj(app.Axes(5),'Tag','polarRadial'))==24);
assert(isequal(app.DataTable.Data.Properties.VariableNames,{'hora_solar_h','altura_grados','angulo_horario_grados','acimut_desde_sur_grados'}));
cases=[0 0 12 90;40 -23.45 12 26.55;40 23.45 12 73.45;-40 23.45 12 26.55;40 0 9 32.797751331];
for k=1:size(cases,1)
    p=geosolar.position(cases(k,1),cases(k,2),cases(k,3));assert(abs(p.alpha-cases(k,4))<1e-8);
end
assert(abs(geosolar.daylight(40,-23.45).hours-9.154019086)<1e-8);
app.ideal(0);app.setParameter('lat',0);app.setParameter('time',12);app.setParameter('day',172);assert(app.State.delta==0&&strcmp(app.State.mode,'manual'));
assert(isnan(app.DataTable.Data.acimut_desde_sur_grados(49)));
for lat=[-90 -40 0 40 90]
    app.setParameter('lat',lat);app.setParameter('time',0);app.setParameter('time',24);
end
app.reset();app.saveScenario(fullfile(out,'escenario.json'));app.ideal(0);app.loadScenario(fullfile(out,'escenario.json'));assert(strcmp(app.State.mode,'date'));
app.exportCsv(fullfile(out,'geometria.csv'));t=readtable(fullfile(out,'geometria.csv'),'Delimiter',';','NumHeaderLines',3);assert(height(t)==97);assert(isequal(t.angulo_horario_grados,15*(t.hora_solar_h-12)));
assert(t.angulo_horario_grados(49)==0&&t.angulo_horario_grados(1)==-180&&t.angulo_horario_grados(end)==180);
assert(all(diff(app.Axes(6).XTick)==15));
assert(all(arrayfun(@(a)isempty(a.Title.String),app.Axes([1 2 3 6]))));
horizon=findobj(app.Axes(5),'Tag','polarHorizon');assert(horizon.LineWidth>=1.4);
app.setParameter('animation','annual');app.toggle();pause(.5);app.stop();assert(app.State.day~=355&&strlength(app.LastError)==0);
app.selectLab(1,'Órbita');app.selectLab(2,'Geometría');app.reset();
app.setParameter('lat',-40);app.ideal(23.45);app.setParameter('time',12);
assert(isequal(app.Axes(6).XLim,[0 360]));
points=findobj(app.Axes(6),'Type','line','Marker','o');assert(abs(points.XData-180)<1e-8);
assert(~contains(string(app.Axes(6).Title.String),'sin analema'));
for line=findobj(app.Axes(6),'Type','line')'
    x=line.XData;assert(all(abs(diff(x(isfinite(x))))<=360));
    dx=abs(diff(x));assert(all(dx(isfinite(dx))<=180));
end
exportgraphics(app.Axes(6),fullfile(out,'carta_sur.png'),'Resolution',160);
app.setParameter('lat',40);assert(isequal(app.Axes(6).XLim,[-180 180]));
other=iniciarGeosolar('Visible','off','PersistLocation',false);otherCleanup=onCleanup(@()delete(other));
app.toggle();pause(.3);app.stop();assert(isvalid(other.Figure)&&~other.Playing);
delete(otherCleanup);assert(isvalid(app.Figure)&&strcmp(foreignClock.Running,'on'));app.reset();
app.Figure.Visible='on';drawnow;pause(1);exportapp(app.Figure,fullfile(out,'piloto_1500.png'));
for k=1:6,exportgraphics(app.Axes(k),fullfile(out,sprintf('figura_%02d.png',k)),'Resolution',130);end
app.Figure.WindowState='normal';app.Figure.Position=[30 30 1050 720];drawnow;pause(.5);exportapp(app.Figure,fullfile(out,'piloto_1050.png'));
delete(cleanup);assert(strcmp(foreignClock.Running,'on'));stop(foreignClock);delete(foreignCleanup);assert(numel(timerfindall)==numel(before));
disp('PASS: modelos, controles, extremos, escenarios, CSV, animación, navegación, exportación, cierre.');
end
