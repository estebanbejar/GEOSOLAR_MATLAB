function verificarHemisferioYMapa
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'hemisferio_mapa_verificacion.txt'));d=onCleanup(@()diary('off'));
p=GeosolarFixedLab.defaults();north=geosolarfixed.pv_filas_modelo(p,datetime(2026,12,21),[10.5 12 13.5]);
p.lat=-40;south=geosolarfixed.pv_filas_modelo(p,datetime(2026,6,21),[10.5 12 13.5]);
assert(south.frontAzimuth==180&&abs(south.P-north.P)<1e-12&&south.d>2);
assert(all(south.incidencia>0)&&~any(south.posterior));assert(max(south.fraccion,[],'all')<1e-4);
for phi=[-10 -25 -40 -60]
    for alpha=[-60 -30 0 30 60]
        p.lat=phi;p.alpha=alpha;s=geosolarfixed.pv_filas_modelo(p,datetime(2026,6,21),12);
        assert(s.P>=s.b&&s.d>=0&&all(s.fraccion(:)>=0&s.fraccion(:)<=1));
        for k=2:p.n,assert(min(s.vertices{k}(:,1))-max(s.vertices{k-1}(:,1))>=-1e-10);end
        p.lat=-phi;p.alpha=-alpha;n=geosolarfixed.pv_filas_modelo(p,datetime(2026,12,21),12);assert(abs(s.P-n.P)<1e-10);
    end
end
g=iniciarGeosolar('PersistLocation',false);c=onCleanup(@()delete(g));g.selectLab(3,'Filas');f=g.Fixed;f.setParameter('lat',-40);f.setParameter('date','2026-06-21');f.setParameter('time',12);assert(f.Valid);
% La normal frontal local [-sin(beta),0,cos(beta)] apunta al Norte al transformar al mundo.
[e,n]=f.world(-sind(f.State.beta),0);assert(n>0&&abs(e)<1e-12);
f.setParameter('alpha',30);assert(f.Current.frontAzimuth==210);f.setParameter('alpha',0);
drawnow;pause(1);exportapp(g.Figure,fullfile(out,'filas_hemisferio_sur.png'));exportgraphics(f.Axes(1),fullfile(out,'filas_sur_3d.png'),'Resolution',160);exportgraphics(f.Axes(2),fullfile(out,'filas_sur_planta.png'),'Resolution',160);
delete(c);disp('PASS: hemisferio sur, orientación, paso, ausencia de solapes y simetrías.');
% Recursos idénticos al selector funcional; no basta con copiar picker.html.
reference=fullfile(geosolar.referenceSourceRoot(),'geometria_solar','assets','location_picker');files={'picker.html','picker.js','picker.css','vendor/leaflet.js','vendor/leaflet.css','vendor/LICENSE'};
for k=1:numel(files),assert(isequal(fileread(fullfile(reference,files{k})),fileread(fullfile(root,'assets','location_picker',files{k}))));end
results=geosolarfixed.buscar_localidades('Salamanca');assert(~isempty(results));disp('PASS: búsqueda real de localidades.');
% Verifica descarga y formato de una tesela realmente visible en el mapa inicial.
z=7;x=floor(((-5+180)/360)*2^z);y=floor((1-asinh(tand(40))/pi)/2*2^z);
tile=geosolarfixed.ubicacion_mapa_tile(z,x,y);assert(startsWith(tile,'data:image/png;base64,'));disp('PASS: tesela OpenStreetMap real.');
testTimer=timer('StartDelay',25,'TimerFcn',@captureAndAccept);timerGuard=onCleanup(@()deleteTimer(testTimer));start(testTimer);
[lat,lon,ok,name]=geosolarfixed.seleccionar_ubicacion(40,-5,Nombre="Prueba",LatitudeLimits=[-65 65]);
assert(ok&&lat==-40&&lon==-70&&strcmp(name,'Prueba sur'));disp('PASS: selector abierto, exportación y callback de aceptación.');
    function captureAndAccept(~,~)
        picker=findall(groot,'Tag','locationPicker');
        if isempty(picker),return;end
        html=findall(picker,'Tag','locationHTML');
        exportapp(picker,fullfile(out,'mapa_reutilizado.png'));
        html.Data=struct('type','accept','lat',-40,'lon',-70,'name','Prueba sur');html.DataChangedFcn(html,[]);
    end
end
function deleteTimer(t),if isvalid(t),stop(t);delete(t);end,end
