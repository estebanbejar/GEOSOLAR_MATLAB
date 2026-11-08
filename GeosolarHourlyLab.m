classdef GeosolarHourlyLab < handle
    properties (SetAccess=private)
        Panel
        Side
        Axes
        Controls
        Metrics
        DataTable
        ComparisonTable
        Status
        Current=[]
        Comparison=[]
        Primary=[]
        Folder
        Files={}
    end
    properties (Access=private)
        Owner
        Cache
        Metadata
        FileInfo
        ComparisonInfo
        LocationInfo
        Ready=false
        SeriesVisible=true(1,6)
        PlotLines=gobjects(1,6)
        NavigationBase=[]
        NavigationOffset=0
        NavigationWindow=[]
    end
    methods
        function lab=GeosolarHourlyLab(sideHost,host,owner)
            lab.Owner=owner;lab.Cache=containers.Map('KeyType','char','ValueType','any');
            lab.Folder=fullfile(fileparts(mfilename('fullpath')),'data','series_horarias');
            lab.Side=uipanel(sideHost,'BorderType','none','Visible','off');lab.Side.Layout.Row=1;lab.Side.Layout.Column=1;
            side=uigridlayout(lab.Side,[21 1]);side.Scrollable='on';side.RowHeight={32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,65,105,115,'1x'};
            uilabel(side,'Text','07 Series horarias','FontSize',17,'FontWeight','bold');
            lab.Controls.folder=uieditfield(side,'text','Value',lab.Folder,'Editable','off','Tooltip',lab.Folder);
            uibutton(side,'Text','Seleccionar carpeta…','ButtonPushedFcn',@(~,~)lab.folderDialog());
            uibutton(side,'Text','Buscar nuevos CSV','ButtonPushedFcn',@(~,~)lab.refreshFiles());
            uilabel(side,'Text','Localidad · configuración · base');
            lab.Controls.file=uidropdown(side,'Items',{'Sin archivos'},'ItemsData',{''},'ValueChangedFcn',@(~,~)lab.fileChanged());
            uilabel(side,'Text','Periodo');
            lab.Controls.period=uidropdown(side,'Items',{'Diario','Semanal','Mensual','Personalizado','Todo el periodo'}, ...
                'ItemsData',{'day','week','month','custom','all'},'Value','custom','ValueChangedFcn',@(s,~)lab.setPeriod(s.Value));
            uilabel(side,'Text','Resolución');
            lab.Controls.mode=uidropdown(side,'Items',{'Horaria · W/m²','Diaria · kWh/m²','Mensual · kWh/m²','Anual · kWh/m²'},'ItemsData',{'hourly','daily','monthly','yearly'},'Value','daily','ValueChangedFcn',@(~,~)lab.update());
            row=uigridlayout(side,[1 2]);row.ColumnWidth={75,'1x'};row.Padding=[0 0 0 0];uilabel(row,'Text','Desde UTC');
            lab.Controls.start=uidatepicker(row,'DisplayFormat','dd/MM/yyyy','Tooltip','Desde, UTC, incluido','ValueChangedFcn',@(~,~)lab.dateChanged('start'));
            row=uigridlayout(side,[1 2]);row.ColumnWidth={75,'1x'};row.Padding=[0 0 0 0];uilabel(row,'Text','Hasta UTC');
            lab.Controls.finish=uidatepicker(row,'DisplayFormat','dd/MM/yyyy','Tooltip','Hasta, UTC, incluido','ValueChangedFcn',@(~,~)lab.dateChanged('finish'));
            uilabel(side,'Text','Comparar global con otro CSV');
            lab.Controls.compare=uidropdown(side,'Items',{'Sin comparación'},'ItemsData',{''},'ValueChangedFcn',@(~,~)lab.update());
            uibutton(side,'Text','Actualizar gráficos','ButtonPushedFcn',@(~,~)lab.update());
            uibutton(side,'Text','Exportar tabla CSV','ButtonPushedFcn',@(~,~)lab.exportDialog(false));
            uibutton(side,'Text','CSV de comparación','ButtonPushedFcn',@(~,~)lab.exportDialog(true));
            lab.LocationInfo=uilabel(side,'WordWrap','on');
            lab.Status=uilabel(side,'Text','Abra el laboratorio para cargar los CSV locales.','WordWrap','on');
            uilabel(side,'Text','Hora UTC en todas las vistas. Los minutos originales se conservan. El descargador Python sigue siendo externo.','WordWrap','on');
            lab.Panel=uipanel(host,'BorderType','none','Visible','off');lab.Panel.Layout.Row=1;lab.Panel.Layout.Column=1;
            content=uigridlayout(lab.Panel,[7 1]);content.Scrollable='on';content.RowHeight={95,70,480,80,250,240,115};
            frame=uipanel(content,'BorderType','line','HighlightColor',[.6 .63 .62]);board=uigridlayout(frame,[1 4]);lab.Metrics=gobjects(1,4);
            labels={'Irradiación estimada','Máxima irradiancia','Registros horarios','Temperatura y viento'};
            for k=1:4
                cellFrame=uipanel(board,'BorderType','line','HighlightColor',[.75 .77 .76]);cellGrid=uigridlayout(cellFrame,[1 1]);cellGrid.Padding=[8 4 4 4];
                lab.Metrics(k)=uilabel(cellGrid,'Text',labels{k},'WordWrap','on','FontWeight','bold');
            end
            lab.FileInfo=uilabel(content,'WordWrap','on');
            box=uigridlayout(content,[4 1]);box.RowHeight={28,'1x',36,38};row=uigridlayout(box,[1 3]);row.ColumnWidth={'1x',55,110};row.Padding=[0 0 0 0];
            uilabel(row,'Text','Componentes de radiación sobre el plano','FontWeight','bold');
            uibutton(row,'Text','PNG','ButtonPushedFcn',@(~,~)lab.pngDialog(false));
            uibutton(row,'Text','Captura PNG','ButtonPushedFcn',@(~,~)lab.pngDialog(true));
            lab.Axes=uiaxes(box);toolbar=axtoolbar(lab.Axes,{});toolbar.Visible='off';
            row=uigridlayout(box,[1 3]);row.ColumnWidth={140,'1x',140};row.Padding=[0 0 0 0];
            lab.Controls.previous=uibutton(row,'Text','◀ Anterior','Enable','off','ButtonPushedFcn',@(~,~)lab.navigate(-1));
            uilabel(row,'Text','Desplazar el periodo visible','HorizontalAlignment','center');
            lab.Controls.next=uibutton(row,'Text','Siguiente ▶','Enable','off','ButtonPushedFcn',@(~,~)lab.navigate(1));
            row=uigridlayout(box,[1 6]);row.ColumnWidth=repmat({'1x'},1,6);row.Padding=[0 0 0 0];
            names={'Directa','Difusa','Reflejada','Global','Global comparada','Temperatura (°C)'};lab.Controls.series=gobjects(1,6);columns=[2 3 4 1 5 6];
            for k=1:6
                lab.Controls.series(k)=uibutton(row,'Text',names{k},'FontSize',10,'ButtonPushedFcn',@(~,~)lab.setSeriesVisible(k,~lab.SeriesVisible(k)));
                lab.Controls.series(k).Layout.Row=1;lab.Controls.series(k).Layout.Column=columns(k);
            end
            lab.refreshLegend();
            lab.ComparisonInfo=uilabel(content,'Text','Sin comparación.','WordWrap','on');
            tabs=uitabgroup(content);tab=uitab(tabs,'Title','Tabla del CSV principal · UTC');g=uigridlayout(tab,[1 1]);lab.DataTable=uitable(g);
            tab=uitab(tabs,'Title','Tabla del CSV comparado · UTC');g=uigridlayout(tab,[1 1]);lab.ComparisonTable=uitable(g);
            lab.Metadata=uitextarea(content,'Editable','off','Value',{'Metadatos originales del CSV'});
            uilabel(content,'Text',{'Global = directa + difusa + reflejada sobre el plano del CSV; no son automáticamente DNI/GHI/DHI.', ...
                'Irradiación estimada = suma de irradiancias × 1 hora / 1000. SARAH3: observaciones instantáneas aproximadas como horarias; ERA5: medias horarias.', ...
                'Temperatura del aire T2m del CSV principal: °C en el eje derecho; media de registros en diaria, mensual y anual.', ...
                'Meses y años parcialmente seleccionados contienen solo los registros del intervalo, sin extrapolar. No se interpola ni se calculan diferencias entre bases. Compruebe coordenadas, ángulos, horizonte y cobertura.'},'WordWrap','on');
            lab.adoptLocation(owner.Location);
        end
        function activate(lab)
            if ~lab.Ready,lab.refreshFiles();end
        end
        function adoptLocation(lab,point)
            lab.LocationInfo.Text=sprintf('Ubicación común: %s\n%+.4f°, %+.4f°\nCada CSV conserva su propio emplazamiento.',point.name,point.lat,point.lon);
        end
        function setFolder(lab,folder)
            assert(isfolder(folder),'No existe la carpeta seleccionada.');[~,info]=fileattrib(folder);lab.Folder=info.Name;lab.Primary=[];
            lab.Controls.folder.Value=lab.Folder;lab.Controls.folder.Tooltip=lab.Folder;lab.Ready=false;lab.refreshFiles();
        end
        function refreshFiles(lab)
            previous=lab.Controls.file.Value;comparison=lab.Controls.compare.Value;
            entries=dir(fullfile(lab.Folder,'*.csv'));entries=entries(~[entries.isdir]);lab.Files=sort({entries.name});lab.Ready=true;
            if isempty(lab.Files)
                lab.Controls.file.Items={'Sin archivos'};lab.Controls.file.ItemsData={''};lab.Controls.file.Value='';
                lab.Controls.compare.Items={'Sin comparación'};lab.Controls.compare.ItemsData={''};lab.Controls.compare.Value='';
                lab.clearView();lab.Status.Text='No hay CSV en esta carpeta. Use el descargador Python externo y busque nuevos CSV.';return;
            end
            lab.Controls.file.Items=cellfun(@lab.shortName,lab.Files,'UniformOutput',false);lab.Controls.file.ItemsData=lab.Files;
            lab.Controls.compare.Items=[{'Sin comparación'},lab.Controls.file.Items];lab.Controls.compare.ItemsData=[{''},lab.Files];
            if ismember(previous,lab.Files),lab.Controls.file.Value=previous;else,lab.Controls.file.Value=lab.Files{1};end
            if ismember(comparison,lab.Files),lab.Controls.compare.Value=comparison;else,lab.Controls.compare.Value='';end
            lab.fileChanged(~strcmp(previous,lab.Controls.file.Value)||isempty(lab.Primary));
        end
        function fileChanged(lab,resetDates)
            if nargin<2,resetDates=true;end
            if isempty(lab.Controls.file.Value),return;end
            try
                data=lab.readCached(lab.Controls.file.Value);
                if resetDates
                    lab.resetNavigation();
                    lab.Controls.period.Value='custom';lab.Controls.start.Enable='on';lab.Controls.finish.Enable='on';
                    last=data.Rows.Time(end);lab.Controls.start.Value=max(datetime(year(last),1,1),lab.dateOnly(data.Rows.Time(1)));lab.Controls.finish.Value=lab.dateOnly(last);
                    lab.adaptResolution(data,'daily');
                end
                lab.Primary=data;lab.update();
            catch err,lab.clearView();lab.Status.Text=err.message;end
        end
        function update(lab)
            if isempty(lab.Controls.file.Value),return;end
            if ~isempty(lab.NavigationBase)&&~isequal([lab.Controls.start.Value lab.Controls.finish.Value],lab.NavigationWindow),lab.resetNavigation();end
            try
                data=lab.readCached(lab.Controls.file.Value);
                lab.adaptResolution(data);
                result=geosolarhourly.aggregate(data,lab.Controls.start.Value,lab.Controls.finish.Value,lab.Controls.mode.Value);
            catch err,lab.clearView();lab.Status.Text=err.message;return;end
            lab.Primary=data;lab.Current=result;lab.Comparison=[];warning='';compData=[];
            if ~isempty(lab.Controls.compare.Value)&&~strcmp(lab.Controls.compare.Value,lab.Controls.file.Value)
                try
                    compData=lab.readCached(lab.Controls.compare.Value);
                    lab.Comparison=geosolarhourly.aggregate(compData,lab.Controls.start.Value,lab.Controls.finish.Value,lab.Controls.mode.Value);
                catch err,warning=[' Comparación no disponible: ' err.message];end
            end
            lab.render(compData);lab.Status.Text=['Datos locales cargados.' warning];
        end
        function fullPeriod(lab)
            lab.setPeriod('all');
        end
        function setPeriod(lab,period)
            if isempty(lab.Controls.file.Value),return;end
            lab.resetNavigation();
            try
                assert(ismember(period,{'day','week','month','custom','all'}),'Periodo no válido.');
                data=lab.readCached(lab.Controls.file.Value);first=lab.dateOnly(data.Rows.Time(1));last=lab.dateOnly(data.Rows.Time(end));
                start=max(first,min(last,lab.Controls.start.Value));preferred='';
                switch period
                    case 'day',finish=start;preferred='hourly';
                    case 'week',start=start-caldays(mod(weekday(start)+5,7));finish=min(last,start+caldays(6));start=max(first,start);preferred='hourly';
                    case 'month',start=max(first,dateshift(start,'start','month'));finish=min(last,dateshift(start,'end','month'));preferred='hourly';
                    case 'all',start=first;finish=last;preferred='monthly';
                    otherwise,finish=lab.Controls.finish.Value;
                end
                lab.Controls.period.Value=period;lab.Controls.start.Value=start;lab.Controls.finish.Value=finish;
                lab.Controls.start.Enable=~strcmp(period,'all');lab.Controls.finish.Enable=strcmp(period,'custom');
                lab.adaptResolution(data,preferred);lab.update();
            catch err,lab.clearView();lab.Status.Text=err.message;end
        end
        function exportData(lab,file,comparison)
            if nargin<3,comparison=false;end
            data=lab.Current;if comparison,data=lab.Comparison;end
            assert(~isempty(data),'No hay datos representados para exportar.');
            [exists,info]=fileattrib(file);
            if exists
                assert(~strcmpi(info.Name,lab.Primary.File)&&~strcmpi(info.Name,data.File),'No se puede sobrescribir un CSV de origen.');
                if ~isempty(lab.Comparison),assert(~strcmpi(info.Name,lab.Comparison.File),'No se puede sobrescribir un CSV de origen.');end
            end
            fid=fopen(file,'w','n','UTF-8');assert(fid>=0,'No se puede escribir el archivo.');
            fprintf(fid,'# GEOSOLAR; series horarias; UTC; %s\n# source: %s\n# units radiation: %s; temperatura_aire_C: grados C (media si se agrupa); global = directa + difusa + reflejada; sin interpolar\n',data.Mode,data.File,data.Units);fclose(fid);
            writetable(lab.displayTable(data),file,'Delimiter',';','WriteMode','append','WriteVariableNames',true,'Encoding','UTF-8');
        end
        function navigate(lab,direction)
            assert(ismember(direction,[-1 1]),'Dirección no válida.');
            [start,finish,ok]=lab.navigationTarget(direction);if ~ok,return;end
            if strcmp(lab.Controls.period.Value,'custom')
                if isempty(lab.NavigationBase),lab.NavigationBase=[lab.Controls.start.Value lab.Controls.finish.Value];end
                lab.NavigationOffset=lab.NavigationOffset+direction;lab.NavigationWindow=[start finish];
            end
            lab.Controls.start.Value=start;lab.Controls.finish.Value=finish;lab.update();
        end
        function setSeriesVisible(lab,index,visible)
            validateattributes(index,{'numeric'},{'scalar','integer','>=',1,'<=',6});
            lab.SeriesVisible(index)=logical(visible);lab.applyVisibility();
        end
        function exportPlot(lab,file)
            assert(~isempty(lab.Current),'No hay datos representados para exportar.');
            % Figura independiente: no altera el layout/leyenda de los UIAxes.
            fig=figure('Visible','off','Position',[50 50 1100 500],'Color','white');cleanup=onCleanup(@()delete(fig));ax=axes(fig);hold(ax,'on');
            if strcmp(lab.Current.Mode,'yearly')
                handles=geosolarhourly.annualBars(ax,lab.Current,lab.Comparison);shown=gobjects(1,0);maximum=0;
                for key=[4 1 2 3 5]
                    if isgraphics(handles(key))
                        handles(key).Visible=lab.SeriesVisible(key);
                        if lab.SeriesVisible(key),shown(end+1)=handles(key);maximum=max(maximum,max(handles(key).YData,[],'omitnan'));end
                    end
                end
                ylim(ax,[0 max(1,1.12*maximum)]);grid(ax,'on');ylabel(ax,lab.Current.Units);title(ax,'Anual · UTC');
                temperature=geosolarhourly.temperaturePlot(ax,lab.Current,lab.SeriesVisible(6));
                if isgraphics(temperature)&&lab.SeriesVisible(6),shown(end+1)=temperature;end
                if ~isempty(shown),legend(ax,shown,'Location','southoutside','NumColumns',3);end
                exportgraphics(fig,file,'Resolution',160);return;
            end
            p=lab.Current.Points;values=[p.Direct p.Diffuse p.Reflected p.Global];
            plot(ax,p.Time,nan(height(p),1),'HandleVisibility','off');
            colors=[.86 .55 .1;.14 .61 .6;.58 .41 .74;.08 .24 .32;.87 .35 .38];names={'Directa','Difusa','Reflejada','Global (suma)','Global del CSV comparado'};
            maximum=0;shown=gobjects(1,0);first=p.Time(1);last=p.Time(end);
            for k=1:5
                if ~lab.SeriesVisible(k),continue;end
                if k<=4,time=p.Time;value=values(:,k);style='-';
                elseif ~isempty(lab.Comparison),time=lab.Comparison.Points.Time;value=lab.Comparison.Points.Global;style='--';
                else,continue;end
                marker='none';if numel(time)==1,marker='o';end
                shown(end+1)=plot(ax,time,value,style,'Color',colors(k,:),'LineWidth',1.5,'Marker',marker,'DisplayName',names{k});
                maximum=max(maximum,max(value));first=min(first,time(1));last=max(last,time(end));
            end
            if first==last,first=first-hours(12);last=last+hours(12);end
            xlim(ax,[first last]);ylim(ax,[0 max(1,1.12*maximum)]);grid(ax,'on');xlabel(ax,'Fecha y hora UTC');ylabel(ax,lab.Current.Units);
            labels=struct('hourly','Horaria','daily','Diaria','monthly','Mensual','yearly','Anual');title(ax,[labels.(lab.Current.Mode) ' · UTC']);
            if strcmp(lab.Current.Mode,'hourly'),ax.XAxis.TickLabelFormat='dd/MM HH:mm';elseif strcmp(lab.Current.Mode,'daily'),ax.XAxis.TickLabelFormat='dd/MM/yyyy';elseif strcmp(lab.Current.Mode,'monthly'),ax.XAxis.TickLabelFormat='MM/yyyy';else,ax.XAxis.TickLabelFormat='yyyy';end
            temperature=geosolarhourly.temperaturePlot(ax,lab.Current,lab.SeriesVisible(6));
            if isgraphics(temperature)&&lab.SeriesVisible(6),shown(end+1)=temperature;end
            if ~isempty(shown),legend(ax,shown,'Location','southoutside','NumColumns',3);end
            exportgraphics(fig,file,'Resolution',160);
        end
        function capture(lab,file)
            % exportapp captura solo los hijos del lado activo de yyaxis.
            % Proyectar temporalmente T2m al lado izquierdo conserva los píxeles
            % y las escalas, sin modificar los datos ni la curva de temperatura.
            proxy=gobjects(1);yyaxis(lab.Axes,'left');
            if ~isempty(lab.Current)&&isgraphics(lab.PlotLines(6))&&lab.SeriesVisible(6)&&numel(lab.Axes.YAxis)>1
                left=lab.Axes.YAxis(1).Limits;right=lab.Axes.YAxis(2).Limits;p=lab.Current.Points;
                time=p.Time;if strcmp(lab.Current.Mode,'yearly'),time=year(time);end
                y=left(1)+(p.Temperature-right(1))/diff(right)*diff(left);hold(lab.Axes,'on');
                proxy=plot(lab.Axes,time,y,'-.','Color',[.38 .23 .12],'LineWidth',1.8,'Marker',lab.PlotLines(6).Marker,'MarkerSize',4);
                ylim(lab.Axes,left);
            end
            cleanup=onCleanup(@()lab.clearCaptureProxy(proxy));drawnow;pause(.2);exportapp(lab.Owner.Figure,file);
        end
    end
    methods (Access=private)
        function dateChanged(lab,which)
            lab.resetNavigation();
            period=lab.Controls.period.Value;
            if strcmp(which,'start')&&ismember(period,{'day','week','month'}),lab.setPeriod(period);
            else,lab.Controls.period.Value='custom';lab.Controls.start.Enable='on';lab.Controls.finish.Enable='on';lab.update();end
        end
        function adaptResolution(lab,data,preferred)
            if nargin<3,preferred='';end
            first=max(lab.Controls.start.Value,lab.dateOnly(data.Rows.Time(1)));last=min(lab.Controls.finish.Value,lab.dateOnly(data.Rows.Time(end)));
            allowed=geosolarhourly.resolutionModes(first,last);if isempty(allowed),return;end
            previous=lab.Controls.mode.Value;labels=struct('hourly','Horaria · W/m²','daily','Diaria · kWh/m²','monthly','Mensual · kWh/m²','yearly','Anual · kWh/m²');
            if ismember(preferred,allowed),chosen=preferred;
            elseif ismember(previous,allowed),chosen=previous;
            elseif ismember('hourly',allowed),chosen='hourly';
            elseif ismember('yearly',allowed),chosen='monthly';else,chosen='daily';end
            lab.Controls.mode.Items=cellfun(@(name)labels.(name),allowed,'UniformOutput',false);lab.Controls.mode.ItemsData=allowed;lab.Controls.mode.Value=chosen;
            lab.Controls.mode.Tooltip='Horaria: hasta 31 días. Diaria: cualquier intervalo. Mensual: al menos un mes. Anual: al menos un año de datos.';
        end
        function data=readCached(lab,name)
            file=fullfile(lab.Folder,name);info=dir(file);assert(~isempty(info),'No se encuentra el CSV seleccionado.');
            if isKey(lab.Cache,file)
                cached=lab.Cache(file);if cached.stamp==info.datenum&&cached.bytes==info.bytes,data=cached.data;return;end
            end
            data=geosolarhourly.readSeries(file);
            if lab.Cache.Count>=6,keys=lab.Cache.keys;remove(lab.Cache,keys{1});end
            lab.Cache(file)=struct('stamp',info.datenum,'bytes',info.bytes,'data',data);
        end
        function render(lab,compData)
            r=lab.Current;s=r.Summary;ax=lab.Axes;cla(ax,'reset');hold(ax,'off');colors=[.86 .55 .1;.14 .61 .6;.58 .41 .74;.08 .24 .32];
            lab.PlotLines=gobjects(1,6);
            p=r.Points;values=[p.Direct p.Diffuse p.Reflected p.Global];names={'Directa','Difusa','Reflejada','Global (suma)'};
            marker='none';if height(p)==1,marker='o';end
            if strcmp(r.Mode,'yearly')
                lab.PlotLines=geosolarhourly.annualBars(ax,r,lab.Comparison);
            else
            for k=1:4
                line=plot(ax,p.Time,values(:,k),'LineWidth',1.2+.7*(k==4),'Marker',marker,'Color',colors(k,:),'DisplayName',names{k});lab.dataTip(line,p,r.Units,k);
                hold(ax,'on');
                lab.PlotLines(k)=line;
                if ~isempty(lab.Comparison)
                    [other,stamp]=geosolarhourly.matchComparison(p.Time,lab.Comparison.Points,r.Mode);
                    line.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow(['Global comparada · ' r.Units],other);
                    line.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Marca comparada UTC',stamp);
                end
            end
            end
            if ~isempty(lab.Comparison)
                if ~strcmp(r.Mode,'yearly')
                c=lab.Comparison;compMarker='none';if height(c.Points)==1,compMarker='o';end
                line=plot(ax,c.Points.Time,c.Points.Global,'--','LineWidth',1.7,'Marker',compMarker,'Color',[.87 .35 .38],'DisplayName','Global del CSV comparado');lab.dataTip(line,c.Points,c.Units,4);
                lab.PlotLines(5)=line;
                end
                c=lab.Comparison;
                lab.ComparisonTable.Data=lab.displayTable(c);
                lab.ComparisonInfo.Text=sprintf('Comparación: %s\n%d registros · %.2f kWh/m² · se conservan las marcas originales UTC. Compruebe la equivalencia de configuraciones.',lab.shortName(lab.Controls.compare.Value),c.Summary.hours,c.Summary.irradiation);
            else,lab.ComparisonTable.Data=table();lab.ComparisonInfo.Text='Sin comparación.';end
            labels=struct('hourly','Horaria','daily','Diaria','monthly','Mensual','yearly','Anual');
            hold(ax,'off');grid(ax,'on');ylabel(ax,r.Units);xlabel(ax,'Fecha y hora UTC');title(ax,'');subtitle(ax,[labels.(r.Mode) ' · UTC']);
            legend(ax,'off');ax.Visible='on';ax.Toolbar.Visible='off';
            if strcmp(r.Mode,'hourly'),ax.XAxis.TickLabelFormat='dd/MM HH:mm';elseif strcmp(r.Mode,'daily'),ax.XAxis.TickLabelFormat='dd/MM/yyyy';elseif strcmp(r.Mode,'monthly'),ax.XAxis.TickLabelFormat='MM/yyyy';else,xlabel(ax,'Año UTC');end
            maximum=max(values,[],'all');if ~isempty(lab.Comparison),maximum=max(maximum,max(lab.Comparison.Points.Global));end;ylim(ax,[0 max(1,1.12*maximum)]);
            lab.Metrics(1).Text=sprintf('Irradiación estimada\n%.2f kWh/m²',s.irradiation);
            lab.Metrics(2).Text=sprintf('Máxima irradiancia\n%.2f W/m²',s.peak);
            lab.Metrics(3).Text=sprintf('Registros horarios\n%d',s.hours);
            lab.Metrics(4).Text=sprintf('Temperatura media\n%s °C\nViento: %s m/s',lab.number(s.temperature),lab.number(s.wind));
            lab.FileInfo.Text=sprintf('%s\nCobertura original: %s → %s UTC\nPeriodo seleccionado: %s → %s UTC (incluido)',lab.shortName(lab.Controls.file.Value),string(lab.Primary.Rows.Time(1),'dd/MM/yyyy HH:mm'),string(lab.Primary.Rows.Time(end),'dd/MM/yyyy HH:mm'),string(lab.Controls.start.Value,'dd/MM/yyyy'),string(lab.Controls.finish.Value,'dd/MM/yyyy'));
            lab.Controls.file.Tooltip=lab.Controls.file.Value;lab.Controls.compare.Tooltip=lab.Controls.compare.Value;
            lab.DataTable.Data=lab.displayTable(r);
            text=["CSV principal: "+string(lab.Primary.File);lab.Primary.Metadata;lab.Primary.Footer];
            if ~isempty(lab.Comparison),text=[text;"";"CSV comparado: "+string(compData.File);compData.Metadata;compData.Footer];end
            lab.Metadata.Value=cellstr(text);
            lab.PlotLines(6)=geosolarhourly.temperaturePlot(ax,r,lab.SeriesVisible(6));
            lab.applyVisibility();lab.refreshNavigation();
        end
        function clearView(lab)
            lab.Primary=[];lab.Current=[];lab.Comparison=[];cla(lab.Axes,'reset');legend(lab.Axes,'off');
            lab.PlotLines=gobjects(1,6);lab.refreshLegend();lab.refreshNavigation();
            lab.DataTable.Data=table();lab.ComparisonTable.Data=table();lab.Metadata.Value={''};lab.FileInfo.Text='';lab.ComparisonInfo.Text='';
            for k=1:4,lab.Metrics(k).Text='Sin datos en el periodo';end
        end
        function folderDialog(lab)
            folder=uigetdir(lab.Folder,'Carpeta con CSV horarios PVGIS');if ~isequal(folder,0),lab.setFolder(folder);end
        end
        function exportDialog(lab,comparison)
            [f,p]=uiputfile('*.csv','Exportar datos representados');if isequal(f,0),return;end
            try,lab.exportData(fullfile(p,f),comparison);catch err,uialert(lab.Owner.Figure,err.message,'Exportación');end
        end
        function pngDialog(lab,capture)
            [f,p]=uiputfile('*.png','Exportar gráfica');if isequal(f,0),return;end
            if capture,lab.capture(fullfile(p,f));else,lab.exportPlot(fullfile(p,f));end
        end
        function resetNavigation(lab)
            lab.NavigationBase=[];lab.NavigationOffset=0;lab.NavigationWindow=[];
        end
        function clearCaptureProxy(lab,proxy)
            if isgraphics(proxy),delete(proxy);end
            if isgraphics(lab.Axes),hold(lab.Axes,'off');yyaxis(lab.Axes,'left');end
        end
        function [start,finish,ok]=navigationTarget(lab,direction)
            start=lab.Controls.start.Value;finish=lab.Controls.finish.Value;ok=false;
            if isempty(lab.Current)||isempty(lab.Primary),return;end
            first=lab.dateOnly(lab.Primary.Rows.Time(1));last=lab.dateOnly(lab.Primary.Rows.Time(end));
            switch lab.Controls.period.Value
                case 'day',start=start+caldays(direction);finish=start;
                case 'week',start=start-caldays(mod(weekday(start)+5,7))+caldays(7*direction);finish=start+caldays(6);
                case 'month',start=dateshift(start,'start','month')+calmonths(direction);finish=dateshift(start,'end','month');
                case 'custom'
                    base=lab.NavigationBase;offset=lab.NavigationOffset;
                    if isempty(base),base=[start finish];offset=0;end
                    if base(1)==dateshift(base(1),'start','month')&&base(2)==dateshift(base(2),'end','month')
                        % Meses/años naturales completos: conservarlos al cruzar febrero.
                        span=12*(year(base(2))-year(base(1)))+month(base(2))-month(base(1))+1;
                        start=base(1)+calmonths((offset+direction)*span);finish=dateshift(start+calmonths(span-1),'end','month');
                    else
                        span=days(base(2)-base(1))+1;start=base(1)+caldays((offset+direction)*span);finish=base(2)+caldays((offset+direction)*span);
                    end
                otherwise,return;
            end
            if finish<first||start>last,return;end
            start=max(start,first);finish=min(finish,last);
            ok=~isequal([start finish],[lab.Controls.start.Value lab.Controls.finish.Value]);
        end
        function refreshNavigation(lab)
            [~,~,previous]=lab.navigationTarget(-1);[~,~,next]=lab.navigationTarget(1);
            lab.Controls.previous.Enable=previous;lab.Controls.next.Enable=next;
            lab.Controls.previous.Tooltip='Periodo anterior, limitado por la cobertura del CSV. En Todo el periodo no hay otro intervalo disponible.';
            lab.Controls.next.Tooltip='Periodo siguiente, limitado por la cobertura del CSV. En Todo el periodo no hay otro intervalo disponible.';
        end
        function applyVisibility(lab)
            if numel(lab.Axes.YAxis)>1,yyaxis(lab.Axes,'left');end
            maximum=0;
            for k=1:5
                if isgraphics(lab.PlotLines(k))
                    lab.PlotLines(k).Visible=lab.SeriesVisible(k);
                    if lab.SeriesVisible(k),maximum=max(maximum,max(lab.PlotLines(k).YData,[],'all','omitnan'));end
                end
            end
            ylim(lab.Axes,[0 max(1,1.12*maximum)]);
            if isgraphics(lab.PlotLines(6)),lab.PlotLines(6).Visible=lab.SeriesVisible(6);end
            if numel(lab.Axes.YAxis)>1,lab.Axes.YAxis(2).Visible=isgraphics(lab.PlotLines(6))&&lab.SeriesVisible(6);end
            lab.refreshLegend();
        end
        function refreshLegend(lab)
            colors=[.86 .55 .1;.14 .61 .6;.58 .41 .74;.08 .24 .32;.87 .35 .38;.38 .23 .12];
            for k=1:6
                button=lab.Controls.series(k);button.UserData=lab.SeriesVisible(k);button.Enable=isgraphics(lab.PlotLines(k));
                button.FontColor=colors(k,:);
                if lab.SeriesVisible(k),button.FontWeight='bold';button.BackgroundColor=[1 1 1];else,button.FontWeight='normal';button.BackgroundColor=[.85 .85 .85];end
                button.Tooltip='Mostrar u ocultar esta curva. No cambia los datos, los indicadores ni la tabla exportada.';
            end
        end
    end
    methods (Static,Access=private)
        function text=shortName(name)
            name=char(name);tokens=regexp(name,'_(ERA5|SARAH3)_(\d{4}-\d{4})_horario\.csv$','tokens','once');
            if ~isempty(tokens)
                base=regexprep(regexprep(name,'^PVGIS_',''),'_(ERA5|SARAH3)_\d{4}-\d{4}_horario\.csv$','');
                text=[tokens{1} ' · ' strrep(base,'_',' · ') ' · ' tokens{2}];
            else,text=strrep(regexprep(regexprep(name,'^PVGIS_',''),'_horario\.csv$',''),'_',' · ');end
        end
        function date=dateOnly(value)
            date=datetime(year(value),month(value),day(value));
        end
        function text=number(value)
            if isfinite(value),text=sprintf('%.2f',value);else,text='—';end
        end
        function data=displayTable(result)
            data=result.Points;t=data.Time;
            if strcmp(result.Mode,'hourly'),stamp=string(t,"yyyy-MM-dd'T'HH:mm'Z'");elseif strcmp(result.Mode,'daily'),stamp=string(t,'yyyy-MM-dd');elseif strcmp(result.Mode,'monthly'),stamp=string(t,'yyyy-MM');else,stamp=string(t,'yyyy');end
            data.Time=stamp;hasTemperature=ismember('Temperature',data.Properties.VariableNames);
            if hasTemperature,data.Temperature=[];end
            data.Properties.VariableNames={'fecha_UTC','directa','difusa','reflejada','global','registros'};
            if hasTemperature,data.temperatura_aire_C=result.Points.Temperature;end
        end
        function dataTip(line,points,unit,k)
            names={'Directa','Difusa','Reflejada','Global'};values=[points.Direct points.Diffuse points.Reflected points.Global];
            line.DataTipTemplate.DataTipRows=[dataTipTextRow('Fecha UTC',points.Time),dataTipTextRow([names{k} ' · ' unit],values(:,k)),dataTipTextRow('Registros',points.Records)];
        end
    end
end
