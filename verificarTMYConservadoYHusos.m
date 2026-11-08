function verificarTMYConservadoYHusos
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'tmy_husos_verificacion.txt'));d=onCleanup(@()diary('off'));
g=iniciarGeosolar('PersistLocation',false);c=onCleanup(@()delete(g));g.selectLab(5,'Seguimiento');t=g.Tracking;
assert(strcmp(t.State.spacing,'manual')&&t.State.gcr==50&&t.Design.GCR==.5&&t.Design.P==4);
met=geosolartracking.pv_seguidor_tmy(40,-5);t.calculateAnnual(met);r=t.AnnualResult;
t.setParameter('bt','yes');assert(isequal(t.AnnualResult,r)&&isequaln(t.TMYData,met));
t.setParameter('date','2026-06-21');t.setParameter('camera',20);t.setParameter('time',10);t.setParameter('h',1.6);assert(isequal(t.AnnualResult,r));
t.setParameter('gcr',35);assert(~isempty(t.AnnualResult)&&isequaln(t.TMYData,met));assert(abs(t.Design.GCR-.35)<1e-10);
[~,index]=min(abs(t.AnnualResult.inverseGCR-1/.35));expected=geosolartracking.pv_seguidor_anual(t.physical(),met,t.AnnualResult.inverseGCR(index));assert(max(abs(expected.H-t.AnnualResult.H(index,:)))<1e-9);
t.setParameter('L',2.1);assert(~isempty(t.AnnualResult)&&isequaln(t.TMYData,met));
g.selectLab(3,'Filas');g.selectLab(5,'Seguimiento');assert(~isempty(t.AnnualResult)&&isequaln(t.TMYData,met));
t.setParameter('ns',3);assert(isempty(t.TMYData)&&isempty(t.AnnualResult));t.reset();assert(strcmp(t.State.spacing,'manual')&&t.State.gcr==50);
locations={40,-5,'Europe/Madrid';28.1,-15.4,'Atlantic/Canary';-33.45,-70.66,'America/Santiago'};
for k=1:size(locations,1)
    g.setLocation(locations{k,1},locations{k,2},'Prueba de huso');zone=locations{k,3};assert(strcmp(g.Location.zone,zone));
    labs={g.Fixed,g.EO,g.Tracking};
    for j=1:3
        g.selectLab(j+2,'Instalación');lab=labs{j};assert(strcmp(lab.State.zone,zone)&&strcmp(lab.Controls.zone.Value,zone));
        lab.setParameter('reference','solar');lab.setParameter('date','2026-06-21');lab.setParameter('time',12);
        expected=geosolarfixed.pv_hora_solar(datetime(2026,6,21),g.Location.lon,12,'solarToCivil',zone);
        lab.setParameter('reference','civil');assert(abs(lab.State.time-mod(expected,24))<1e-8);
    end
    fprintf('PASS: huso %s propagado a 03/04/05 y conversión civil correcta.\n',zone);
end
assert(hours(tzoffset(datetime(2026,1,15,'TimeZone','Europe/Madrid')))==1);
assert(hours(tzoffset(datetime(2026,7,15,'TimeZone','Europe/Madrid')))==2);
% La caché devuelve el mismo identificador sin necesidad de datos meteorológicos.
assert(strcmp(geosolar.timeZoneAt(-33.45,-70.66),'America/Santiago'));
disp('PASS: GCR manual 50 %, TMY conservado, recálculo físico sin descarga, invalidación por pendiente y husos IANA con DST.');
end
