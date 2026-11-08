function verificarProductividadSuite()
% Datos reales guardados del original; sin descargar la malla completa.
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');
diary(fullfile(out,'productividad_verificacion.txt'));d=onCleanup(@()diary('off'));
before=timerfindall;g=iniciarGeosolar('PersistLocation',false);guard=onCleanup(@()delete(g));
g.selectLab(6,'Productividad');p=g.Productivity;
assert(strcmp(g.NavigationButtons(6).Enable,'on')&&strcmp(g.NavigationButtons(7).Enable,'on'));
assert(strcmp(g.NavigationButtons(5).Text,'05 Seguimiento 1 eje'));
assert(strcmp(p.Panel.Visible,'on')&&strcmp(g.Tracking.Panel.Visible,'off'));
assert(p.Controls.lat.Value==g.Location.lat&&p.Controls.lon.Value==g.Location.lon);
preloaded=p.getResult();assert(~isempty(preloaded)&&preloaded.latitud==40.459133&&preloaded.longitud==-5.814857);
assert(nnz(isfinite(preloaded.productividad)&isfinite(preloaded.irradiacion))==684&&contains(p.Status.Text,'precargada'));
files=dir(fullfile(root,'data','productividad','PVGIS_*.mat'));assert(~isempty(files));file=fullfile(files(1).folder,files(1).name);
original=load(file);p.loadData(file);r=p.getResult();
assert(isequaln(r.productividad,original.productividad)&&isequaln(r.irradiacion,original.irradiacion));
assert(isequal(size(r.productividad),[19 36])&&g.Location.lat==r.latitud&&g.Location.lon==r.longitud);
assert(g.Fixed.State.lat==r.latitud&&g.EO.State.lon==r.longitud&&g.Tracking.State.lat==r.latitud);
for magnitude={'Producción anual','Irradiación anual'}
    p.Controls.metric.Value=magnitude{1};
    for mode={'Valor absoluto','Porcentaje del máximo'}
        p.Controls.scale.Value=mode{1};p.redraw();drawnow;
        if strcmp(magnitude{1},'Producción anual'),z=r.productividad;else,z=r.irradiacion;end
        if strcmp(mode{1},'Porcentaje del máximo'),z=100*z/max(z,[],'all','omitnan');end
        c=findobj(p.Axes(1),'Type','contour');assert(numel(c)==1&&isequaln(c.ZData,[z(:,end) z]));
        c=findobj(p.Axes(2),'Type','contour');assert(numel(c)==1&&isequaln(c.ZData,[z z(:,1)]));
        for ax=p.Axes,assert(strcmp(ax.Toolbar.Visible,'off'));end
    end
end
mat=fullfile(out,'productividad_datos.mat');csv=fullfile(out,'productividad_datos.csv');
p.exportData(mat);p.exportData(csv);p.loadData(mat);a=p.getResult();p.loadData(csv);b=p.getResult();
for f={'productividad','irradiacion','perd_aoi','perd_esp','perd_temp'},assert(isequaln(a.(f{1}),b.(f{1})));end
g.selectLab(5,'Seguimiento');g.selectLab(6,'Productividad');assert(isequaln(b,p.getResult()));
g.setLocation(-33.45,-70.66,'Santiago de Chile');assert(p.Controls.lat.Value==-33.45&&g.Fixed.State.lat==-33.45);
assert(isequaln(b,p.getResult())&&contains(p.Status.Text,'Carta conservada de'));
assert(strcmp(p.Controls.retry.Enable,'off'));
p.loadData(mat);r=p.getResult();r.productividad(7,18)=NaN;r.irradiacion(7,18)=NaN;
partial=fullfile(out,'productividad_parcial_prueba.mat');save(partial,'-struct','r');p.loadData(partial);
assert(strcmp(p.Controls.retry.Enable,'on'));p.exportData(csv);p.loadData(csv);r=p.getResult();assert(isnan(r.productividad(7,18)));
bad=fullfile(out,'productividad_invalida_prueba.csv');t=readtable(csv,'FileType','text','Delimiter','\t');t=[t(1,:);t(1,:)];writetable(t,bad,'FileType','text','Delimiter','\t');
failed=false;try,p.loadData(bad);catch,failed=true;end;assert(failed&&isequaln(r,p.getResult()));
r.productividad(:)=NaN;r.irradiacion(:)=NaN;emptyFile=fullfile(out,'productividad_vacia_prueba.mat');save(emptyFile,'-struct','r');p.loadData(emptyFile);
assert(isempty(findobj(p.Axes(1),'Type','contour'))&&isempty(findobj(p.Axes(2),'Type','contour'))&&strcmp(p.Controls.retry.Enable,'on'));
p.loadData(mat);p.Controls.metric.Value='Producción anual';p.Controls.scale.Value='Porcentaje del máximo';p.redraw();
drawnow;pause(.5);exportapp(g.Figure,fullfile(out,'productividad_suite.png'));
for k=1:2,exportgraphics(p.Axes(k),fullfile(out,sprintf('productividad_%02d.png',k)),'Resolution',150);end
g.Figure.WindowState='normal';g.Figure.Position=[30 30 1050 720];drawnow;pause(.5);assert(p.Axes(2).Parent.Layout.Row==3);exportapp(g.Figure,fullfile(out,'productividad_1050.png'));
% La rutina se conserva sin cambios: comprobar también su camino sin consultas.
r=p.getResult();seed=r;seed.productividad(~isfinite(seed.productividad))=0;seed.irradiacion(~isfinite(seed.irradiacion))=0;
same=geosolarproductivity.pv_productividad_calcular(seed.localidad,seed.latitud,seed.longitud,[],seed,3);
assert(isequaln(seed.productividad,same.productividad)&&isequaln(seed.irradiacion,same.irradiacion));
delete(guard);assert(numel(timerfindall)==numel(before));
disp('PASS: 06 nativo, cartas originales, datos reales, cuatro modos, continuidad en Norte, MAT/CSV, datos parciales, rechazo de duplicados, ubicación compartida, conservación al navegar, dos tamaños y cierre.');
end
