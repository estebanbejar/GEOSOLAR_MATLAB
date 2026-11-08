function verificarSeriesHorariasSuite()
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');
diary(fullfile(out,'series_horarias_verificacion.txt'));d=onCleanup(@()diary('off'));
reference=jsondecode(fileread(fullfile(root,'data','series_horarias','referencia_python.json')));
for f=1:numel(reference)
    ref=reference(f);data=geosolarhourly.readSeries(fullfile(root,'data','series_horarias',ref.file));assert(height(data.Rows)==ref.records);
    for j=1:numel(ref.cases)
        c=ref.cases(j);
        if ~ismember(c.mode,geosolarhourly.resolutionModes(datetime(c.start),datetime(c.end)))
            failed=false;try,geosolarhourly.aggregate(data,datetime(c.start),datetime(c.end),c.mode);catch,failed=true;end;assert(failed);continue;
        end
        a=geosolarhourly.aggregate(data,datetime(c.start),datetime(c.end),c.mode);
        actual=[a.Points.Direct a.Points.Diffuse a.Points.Reflected a.Points.Global a.Points.Records];
        assert(isequal(size(actual),size(c.values))&&max(abs(actual-c.values),[],'all')<1e-7);
        if strcmp(c.mode,'hourly'),format="yyyy-MM-dd'T'HH:mm'Z'";elseif strcmp(c.mode,'daily'),format='yyyy-MM-dd';else,format='yyyy-MM';end
        expected=datetime(c.timestamps,'InputFormat',format,'TimeZone','UTC');assert(isequal(a.Points.Time,expected));
        for field={'hours','irradiation','peak','temperature','wind','components'}
            assert(max(abs(a.Summary.(field{1})(:)-c.summary.(field{1})(:)))<1e-7);
        end
    end
end
disp('PASS: 6 casos equivalentes al Python original y 2 intervalos cortos rechazados para resolución mensual; bisiesto, cambio de mes y 19 años completos.');
before=timerfindall;g=iniciarGeosolar('PersistLocation',false);guard=onCleanup(@()delete(g));
assert(all(strcmp({g.NavigationButtons.Enable},'on'))&&isempty(g.Hourly.Current));g.selectLab(7,'Series horarias');h=g.Hourly;
assert(~isempty(h.Current)&&h.Current.Summary.hours==8760&&year(h.Controls.start.Value)==2023);
assert(strcmp(h.Panel.Visible,'on')&&strcmp(g.Productivity.Panel.Visible,'off'));
h.Controls.compare.Value=h.Files{2};h.update();assert(~isempty(h.Comparison)&&numel(findobj(h.Axes,'Type','line'))==6);
h.Controls.start.Value=datetime(2020,2,29);h.Controls.finish.Value=datetime(2020,2,29);h.update();h.Controls.mode.Value='hourly';h.update();
assert(h.Current.Summary.hours==24&&h.Comparison.Summary.hours==24);
assert(all(minute(h.Current.Points.Time)==30)&&all(minute(h.Comparison.Points.Time)==10));
[v,stamp]=geosolarhourly.matchComparison(h.Current.Points.Time,h.Comparison.Points,'hourly');
assert(isequal(v,h.Comparison.Points.Global)&&all(minute(stamp)==10));
h.exportData(fullfile(out,'series_horarias_principal.csv'));h.exportData(fullfile(out,'series_horarias_comparacion.csv'),true);
t=readtable(fullfile(out,'series_horarias_principal.csv'),'Delimiter',';','NumHeaderLines',3,'VariableNamingRule','preserve');assert(height(t)==24);
failed=false;try,h.exportData(h.Primary.File);catch,failed=true;end;assert(failed);
saved=h.Current;g.selectLab(5,'Seguimiento');g.selectLab(7,'Series horarias');assert(isequal(h.Current,saved));
h.Controls.finish.Value=datetime(2020,4,1);h.update();assert(~isempty(h.Current)&&strcmp(h.Current.Mode,'daily')&&~ismember('hourly',h.Controls.mode.ItemsData));
h.fullPeriod();assert(strcmp(h.Current.Mode,'monthly')&&height(h.Current.Points)==228&&h.Current.Summary.hours==166536);
drawnow;exportapp(g.Figure,fullfile(out,'series_horarias_mensual.png'));
h.setPeriod('custom');h.Controls.start.Value=datetime(2023,6,21);h.Controls.finish.Value=datetime(2023,6,21);h.update();h.Controls.mode.Value='hourly';h.update();
exportgraphics(h.Axes,fullfile(out,'series_horarias_horaria.png'),'Resolution',150);exportapp(g.Figure,fullfile(out,'series_horarias_suite.png'));
g.Figure.WindowState='normal';g.Figure.Position=[30 30 1050 720];drawnow;pause(.5);exportapp(g.Figure,fullfile(out,'series_horarias_1050.png'));
folder=fullfile(out,'series_horarias_pruebas');if ~isfolder(folder),mkdir(folder);end
file=fullfile(folder,'mini.csv');header=sprintf('Radiation database:\tTEST\nSlope: 30 deg.\ntime,Gb(i),Gd(i),Gr(i)\n');
write(file,[header sprintf('20200131:2310,100,20,5\n20200201:0010,200,30,10\n\nGb(i): descripción\n')]);
sample=geosolarhourly.readSeries(file);a=geosolarhourly.aggregate(sample,datetime(2020,1,31),datetime(2020,2,1),'daily');assert(abs(a.Summary.irradiation-.365)<1e-12&&a.Summary.peak==240&&isnan(a.Summary.temperature));
for text={sprintf('20200131:2310,100,20,5\n20200201:0110,200,30,10\n'),sprintf('20200131:2310,NaN,20,5\n'),sprintf('20200131:2310,100,20,5\n20200131:2310,100,20,5\n')}
    write(file,[header text{1}]);failed=false;try,geosolarhourly.readSeries(file);catch,failed=true;end;assert(failed);
end
h.setFolder(folder);assert(isempty(h.Current));emptyFolder=fullfile(folder,'vacia');if ~isfolder(emptyFolder),mkdir(emptyFolder);end;h.setFolder(emptyFolder);assert(isempty(h.Current)&&isempty(h.Files));
delete(guard);assert(numel(timerfindall)==numel(before));
disp('PASS: 07, UTC/minutos, comparación sin interpolar, selector/carpeta, resumen, exportaciones, protección de originales, errores/huecos/NaN/duplicados, dos tamaños, navegación y cierre.');
end
function write(file,text)
fid=fopen(file,'w','n','UTF-8');assert(fid>=0);c=onCleanup(@()fclose(fid));fprintf(fid,'%s',text);
end
