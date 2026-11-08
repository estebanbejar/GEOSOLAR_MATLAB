function lab=build(sideHost,host,owner)
% Cartas nativas integradas; adaptación del visualizador original IRRADIANCE.
fig=owner.Figure;point=owner.Location;
nombreInicial=point.name;latInicial=point.lat;lonInicial=point.lon;
sidePanel=uipanel(sideHost,'BorderType','none','Visible','off');sidePanel.Layout.Row=1;sidePanel.Layout.Column=1;
ctrl=uigridlayout(sidePanel,[18 2]);ctrl.ColumnWidth={80,'1x'};ctrl.Scrollable='on';
ctrl.RowHeight={32,32,32,32,32,42,52,32,32,32,32,110,105,120,32,1,1,'1x'};ctrl.RowSpacing=6;ctrl.Padding=[6 6 6 6];
heading=uilabel(ctrl,'Text','06 Productividad','FontSize',17,'FontWeight','bold');heading.Layout.Column=[1 2];
uilabel(ctrl,'Text','Localidad');location=uieditfield(ctrl,'text','Value',nombreInicial,'Tag','locationName');
uilabel(ctrl,'Text','Latitud (°)');lat=uieditfield(ctrl,'numeric','Value',latInicial,'Limits',[-90 90],'Tag','latitude');
uilabel(ctrl,'Text','Longitud (°)');lon=uieditfield(ctrl,'numeric','Value',lonInicial,'Limits',[-180 180],'Tag','longitude');
mapButton=uibutton(ctrl,'Text','Seleccionar en mapa…','Tag','selectLocation','ButtonPushedFcn',@selectLocation);mapButton.Layout.Column=[1 2];
calcButton=uibutton(ctrl,'Text','Calcular carta PVGIS','FontWeight','bold','ButtonPushedFcn',@calculate);calcButton.Layout.Column=[1 2];
retryButton=uibutton(ctrl,'Text','Completar datos pendientes (3 pasadas)','Enable','off', ...
    'Tooltip','Vuelve a consultar solo las orientaciones sin datos y conserva los resultados válidos.', ...
    'Tag','retryPVGIS','ButtonPushedFcn',@retryPending);retryButton.Layout.Column=[1 2];
openButton=uibutton(ctrl,'Text','Abrir datos','Tag','openData','ButtonPushedFcn',@openData);openButton.Layout.Column=[1 2];
saveButton=uibutton(ctrl,'Text','Guardar datos','Tag','saveData','Enable','off','ButtonPushedFcn',@saveData);saveButton.Layout.Column=[1 2];
uilabel(ctrl,'Text','Magnitud');metric=uidropdown(ctrl,'Items',{'Irradiación anual','Producción anual'}, ...
    'Value','Producción anual','Tag','metric');
uilabel(ctrl,'Text','Escala');scale=uidropdown(ctrl,'Items',{'Valor absoluto','Porcentaje del máximo'}, ...
    'Value','Porcentaje del máximo','Tag','scale');
summary=uilabel(ctrl,'Text','Elija una localidad, introduzca coordenadas y calcule la carta.','WordWrap','on','Tag','summary');summary.Layout.Column=[1 2];
note=uilabel(ctrl,'Text',sprintf(['Producción: kWh/kWp/año. Irradiación: kWh/m²/año.\n' ...
    'La escala tiene 20 bandas de 5% del máximo. El porcentaje en producción equivale a productividad.']), ...
    'WordWrap','on','FontColor',[.30 .36 .40]);note.Layout.Column=[1 2];
panel=uipanel(host,'BorderType','none','Visible','off');panel.Layout.Row=1;panel.Layout.Column=1;
content=uigridlayout(panel,[3 2]);content.Scrollable='on';content.RowHeight={90,610,90};content.ColumnWidth={'1x','1x'};
frame=uipanel(content,'BorderType','line','HighlightColor',[.6 .63 .62]);frame.Layout.Column=[1 2];
board=uigridlayout(frame,[1 4]);metrics=gobjects(1,4);
for k=1:4
    cellFrame=uipanel(board,'BorderType','line','HighlightColor',[.75 .77 .76]);cellGrid=uigridlayout(cellFrame,[1 1]);cellGrid.Padding=[8 4 4 4];
    metrics(k)=uilabel(cellGrid,'WordWrap','on','FontWeight','bold');
end
axesHandles=gobjects(1,2);boxes=gobjects(1,2);titles={'01 Carta cartesiana','02 Carta polar'};
for k=1:2
    box=uigridlayout(content,[2 1]);boxes(k)=box;box.Layout.Row=2;box.Layout.Column=k;box.RowHeight={28,'1x'};
    row=uigridlayout(box,[1 2]);row.ColumnWidth={'1x',55};row.Padding=[0 0 0 0];
    uilabel(row,'Text',titles{k},'FontWeight','bold');uibutton(row,'Text','PNG','ButtonPushedFcn',@(~,~)exportPlot(k));
    axesHandles(k)=uiaxes(box);toolbar=axtoolbar(axesHandles(k),{});toolbar.Visible='off';
end
cartAx=axesHandles(1);polarAx=axesHandles(2);
explanation=uilabel(content,'Text',{'Acimut PVGIS: 0° Sur · −90° Este · +90° Oeste · ±180° Norte. En el hemisferio sur el óptimo puede quedar junto a ±180°.', ...
    'Radio de la carta polar: inclinación de 0° (centro) a 90° (borde). Cada banda representa un 5 % del máximo.', ...
    'Producción específica: instalación fija de 1 kWp, pérdidas del sistema 14 %, horizonte PVGIS. La consulta contiene hasta 684 orientaciones; puede tardar varios minutos.'},'WordWrap','on');explanation.Layout.Column=[1 2];
status=uilabel(ctrl,'Text','','WordWrap','on');status.Layout.Column=[1 2];
result=[];cbCart=[];cbPolar=[];busy=false;dlg=[];
metric.ValueChangedFcn=@redraw;scale.ValueChangedFcn=@redraw;
lat.ValueChangedFcn=@commitLocation;lon.ValueChangedFcn=@commitLocation;location.ValueChangedFcn=@commitLocation;
capture=uibutton(ctrl,'Text','Captura completa PNG','ButtonPushedFcn',@(~,~)captureApp());capture.Layout.Column=[1 2];
lab=struct('Panel',panel,'Side',sidePanel,'Axes',axesHandles,'Metrics',metrics, ...
    'Controls',struct('location',location,'lat',lat,'lon',lon,'metric',metric,'scale',scale, ...
        'calculate',calcButton,'retry',retryButton,'open',openButton,'save',saveButton,'map',mapButton), ...
    'Status',status,'Summary',summary,'adoptLocation',@adoptLocation,'loadData',@loadData, ...
    'exportData',@exportData,'getResult',@getResult,'redraw',@redraw,'calculate',@calculate,'retry',@retryPending);
emptyMetrics();
panel.AutoResizeChildren='off';panel.SizeChangedFcn=@(~,~)fitCharts();fitCharts();

    function fitCharts()
        if panel.Position(3)<900
            frame.Layout.Column=1;boxes(1).Layout.Column=1;boxes(2).Layout.Column=1;explanation.Layout.Column=1;
            content.ColumnWidth={'1x'};content.RowHeight={90,560,560,115};
            boxes(1).Layout.Row=2;boxes(2).Layout.Row=3;explanation.Layout.Row=4;
        else
            content.ColumnWidth={'1x','1x'};content.RowHeight={90,610,90};
            frame.Layout.Column=[1 2];boxes(1).Layout.Row=2;boxes(1).Layout.Column=1;
            boxes(2).Layout.Row=2;boxes(2).Layout.Column=2;explanation.Layout.Row=3;explanation.Layout.Column=[1 2];
        end
    end
    function data=getResult()
        data=result;
    end
    function adoptLocation(point)
        location.Value=point.name;lat.Value=point.lat;lon.Value=point.lon;locationEdited();
    end
    function emptyMetrics()
        labels={'Ubicación compartida','Máximo de producción','Máximo de irradiación','Orientaciones válidas'};
        for kk=1:4,metrics(kk).Text=labels{kk};end
    end
    function exportPlot(k)
        [f,p]=uiputfile('*.png','Exportar carta');if isequal(f,0),return;end
        exportgraphics(axesHandles(k),fullfile(p,f),'Resolution',160);
    end
    function captureApp()
        [f,p]=uiputfile('*.png','Captura completa');if ~isequal(f,0),exportapp(fig,fullfile(p,f));end
    end
    function exportData(file)
        assert(~isempty(result),'Calcule o abra una carta primero.');
        [~,~,ext]=fileparts(file);
        if strcmpi(ext,'.mat'),data=result;save(file,'-struct','data');
        elseif strcmpi(ext,'.csv'),escribirCSV(file);
        else,error('pv:fileType','Guarde la carta como MAT o CSV tabulado.');end
    end

    function selectLocation(varargin)
        if busy,return;end
        [newLat,newLon,ok,newName]=geosolarfixed.seleccionar_ubicacion(lat.Value,lon.Value, ...
            Nombre=string(location.Value));
        if ok&&isvalid(fig)
            owner.setLocation(newLat,newLon,newName);
            status.Text='Ubicación seleccionada. Pulse Calcular carta PVGIS.';
        end
    end
    function commitLocation(varargin)
        if busy,adoptLocation(owner.Location);return;end
        owner.setLocation(lat.Value,lon.Value,location.Value);
    end
    function locationEdited(varargin)
        metrics(1).Text=sprintf('%s\n%+.4f° / %+.4f°',location.Value,lat.Value,lon.Value);
        if ~isempty(result)&&~sameLocation()
            status.Text=sprintf('Carta conservada de %s (%+.4f°, %+.4f°). Pulse Calcular para la ubicación actual.',result.localidad,result.latitud,result.longitud);
        elseif ~isempty(result),updateResultStatus('Carta conservada');
        else,status.Text='Seleccione una ubicación y pulse Calcular, o abra una carta MAT/CSV.';end
        updateRetryButton();
    end
    function calculate(varargin)
        if busy,return;end
        owner.stop();busy=true;setButtons('off');status.Text='Consultando PVGIS. La malla requiere hasta 684 consultas…';drawnow;
        dlg=uiprogressdlg(fig,'Title','Consulta PVGIS','Message','Preparando consulta…','Indeterminate','off', ...
            'Value',0,'Cancelable','on');
        try
            fresh=geosolarproductivity.pv_productividad_calcular(location.Value,lat.Value,lon.Value,@updateProgress);
            if ~isvalid(owner)||~isvalid(fig),return;end
            result=fresh;
            if validCount()>0
                saveButton.Enable='on';redraw();
            else
                saveButton.Enable='off';clearCharts('PVGIS todavía no ha devuelto puntos válidos para esta ubicación.');
                summary.Text='PVGIS todavía no ha devuelto puntos válidos para esta ubicación.';
            end
            updateResultStatus('Consulta');
        catch err
            if ~isvalid(owner)||~isvalid(fig),return;end
            if strcmp(err.identifier,'pv:cancelled')
                status.Text='Consulta cancelada. Los resultados anteriores se conservan.';
            else
                status.Text=['No se pudo completar la consulta: ' err.message];
            end
            if ~strcmp(err.identifier,'pv:cancelled')&&isvalid(fig),uialert(fig,err.message,'Consulta PVGIS');end
        end
        finishCalculate();
    end
    function retryPending(varargin)
        if busy||isempty(result)||~sameLocation()||validCount()==numel(result.productividad),return;end
        owner.stop();busy=true;setButtons('off');status.Text='Reintentando únicamente las orientaciones pendientes…';drawnow;
        dlg=uiprogressdlg(fig,'Title','Completar carta PVGIS','Message','Preparando reintentos…', ...
            'Indeterminate','off','Value',0,'Cancelable','on');
        try
            fresh=geosolarproductivity.pv_productividad_calcular(location.Value,lat.Value,lon.Value,@updateProgress,result,3);
            if isvalid(dlg),dlg.Value=1;dlg.Message='Pasadas completadas';drawnow;end
            if ~isvalid(owner)||~isvalid(fig),return;end
            result=fresh;
            if validCount()>0
                saveButton.Enable='on';redraw();
            else
                saveButton.Enable='off';clearCharts('PVGIS todavía no ha devuelto puntos válidos para esta ubicación.');
                summary.Text='PVGIS todavía no ha devuelto puntos válidos para esta ubicación.';
            end
            updateResultStatus('Reintento');
        catch err
            if ~isvalid(owner)||~isvalid(fig),return;end
            if strcmp(err.identifier,'pv:cancelled')
                status.Text='Reintentos cancelados. Se conservan los datos anteriores.';
            else
                status.Text=['No se pudieron completar los reintentos: ' err.message];
            end
            if ~strcmp(err.identifier,'pv:cancelled')&&isvalid(fig),uialert(fig,err.message,'Consulta PVGIS');end
        end
        finishCalculate();
    end
    function keepGoing=updateProgress(done,total,failures)
        if ~isvalid(owner)||~isvalid(fig)||isempty(dlg)||~isvalid(dlg),keepGoing=false;return;end
        if total>0,dlg.Value=min(1,done/total);else,dlg.Value=1;end
        dlg.Message=sprintf('Solicitud %d de hasta %d · fallos acumulados: %d',done,total,failures);
        drawnow limitrate;keepGoing=~dlg.CancelRequested;
    end
    function finishCalculate()
        busy=false;if isvalid(fig),setButtons('on');end
        if exist('dlg','var')&&isvalid(dlg),delete(dlg);end
    end
    function setButtons(state)
        calcButton.Enable=state;openButton.Enable=state;mapButton.Enable=state;lat.Enable=state;lon.Enable=state;location.Enable=state;
        if strcmp(state,'off')
            saveButton.Enable='off';retryButton.Enable='off';
        else
            saveButton.Enable=onOff(validCount()>0);
            updateRetryButton();
        end
    end
    function updateRetryButton()
        retryButton.Enable='off';
        if ~busy&&~isempty(result)&&sameLocation()&&validCount()<numel(result.productividad)
            retryButton.Enable='on';
        end
    end
    function tf=sameLocation()
        tf=~isempty(result)&&isfield(result,'latitud')&&isfield(result,'longitud')&& ...
            isequal(result.latitud,lat.Value)&&isequal(result.longitud,lon.Value)&& ...
            isfield(result,'localidad')&&strcmp(strtrim(result.localidad),strtrim(location.Value));
    end
    function n=validCount()
        if isempty(result),n=0;else,n=nnz(isfinite(result.productividad)&isfinite(result.irradiacion));end
    end
    function updateResultStatus(action)
        missing=numel(result.productividad)-validCount();
        if missing==0
            status.Text=sprintf('%s completado: %d de %d puntos válidos. Puede guardar los datos en formato .mat o CSV tabulado.', ...
                action,validCount(),numel(result.productividad));
        else
            status.Text=sprintf('%s: %d de %d puntos válidos; quedan %d pendientes. Pulse «Completar datos pendientes» para hacer hasta 3 pasadas más.', ...
                action,validCount(),numel(result.productividad),missing);
        end
    end
    function value=onOff(tf)
        if tf,value='on';else,value='off';end
    end
    function openData(varargin)
        [file,folder]=uigetfile({'*.mat;*.csv','Archivos MAT o CSV (*.mat, *.csv)'}, ...
            'Abrir carta guardada',fullfile(fileparts(fileparts(mfilename('fullpath'))),'data','productividad',filesep));
        if isequal(file,0),return;end
        try,loadData(fullfile(folder,file));catch err,uialert(fig,err.message,'Archivo no válido');end
    end
    function loadData(file,adopt)
        if nargin<2,adopt=true;end
        try
            [~,~,ext]=fileparts(file);
            switch lower(ext)
                case '.mat'
                    s=load(file);fresh=validarDatos(s,file);
                case '.csv'
                    fresh=leerCSV(file);
                otherwise
                    error('pv:fileType','Seleccione un archivo .mat o .csv separado por tabuladores.');
            end
            if ~isvalid(owner)||~isvalid(fig),return;end
            if adopt,owner.setLocation(fresh.latitud,fresh.longitud,fresh.localidad);end
            result=fresh;
            saveButton.Enable=onOff(validCount()>0);status.Text=['Datos cargados: ' file];redraw();updateRetryButton();
            if ~adopt
                if sameLocation(),status.Text='Carta de Béjar precargada desde CSV local. No se ha consultado PVGIS.';
                else,locationEdited();end
            end
        catch err
            if ~isvalid(owner)||~isvalid(fig),return;end
            rethrow(err);
        end
    end
    function saveData(varargin)
        if isempty(result),return;end
        safe=regexprep(result.localidad,'[^\w-]','_');
        suggestion=sprintf('PVGIS_%s_%.3f_%.3f',safe,result.latitud,result.longitud);
        filters={'*.mat','Archivo MATLAB (*.mat)';'*.csv','CSV separado por tabuladores (*.csv)'};
        [file,folder,filterIndex]=uiputfile(filters,'Guardar datos de la carta',suggestion);
        if isequal(file,0),return;end
        try
            [~,~,ext]=fileparts(file);
            if isempty(ext)
                if filterIndex==2,ext='.csv';else,ext='.mat';end
                file=[file ext];
            end
            target=fullfile(folder,file);
            switch lower(ext)
                case '.mat'
                    data=result;save(target,'-struct','data');
                case '.csv'
                    escribirCSV(target);
                otherwise
                    error('pv:fileType','Guarde la carta como archivo .mat o .csv separado por tabuladores.');
            end
            status.Text=['Datos guardados: ' target];
        catch err
            if ~isvalid(owner)||~isvalid(fig),return;end
            uialert(fig,err.message,'No se pudieron guardar los datos');
        end
    end
    function escribirCSV(file)
        [tilt,azimuth]=ndgrid(result.inclinaciones,result.acimuts);
        count=numel(tilt);
        t=table(repmat(string(result.localidad),count,1), ...
            repmat(result.latitud,count,1),repmat(result.longitud,count,1), ...
            tilt(:),azimuth(:),result.irradiacion(:),result.productividad(:), ...
            result.perd_aoi(:),result.perd_esp(:),result.perd_temp(:), ...
            'VariableNames',{'localidad','latitud_deg','longitud_deg','inclinacion_deg', ...
            'acimut_pvgis_deg','irradiacion_kWh_m2_anio','produccion_kWh_kWp_anio', ...
            'perdida_aoi','perdida_espectral','perdida_temperatura'});
        writetable(t,file,'FileType','text','Delimiter','\t','Encoding','UTF-8');
    end
    function fresh=leerCSV(file)
        t=readtable(file,'FileType','text','Delimiter','\t','TextType','string', ...
            'VariableNamingRule','preserve');
        required={'localidad','latitud_deg','longitud_deg','inclinacion_deg','acimut_pvgis_deg', ...
            'irradiacion_kWh_m2_anio','produccion_kWh_kWp_anio'};
        missing=setdiff(required,t.Properties.VariableNames);
        if ~isempty(missing)
            error('pv:csvColumns','Faltan columnas requeridas en el CSV: %s. Use el CSV tabulado exportado por esta aplicación.', ...
                strjoin(missing,', '));
        end
        if height(t)==0,error('pv:csvEmpty','El CSV no contiene filas de datos.');end
        names=strtrim(t.localidad);
        if any(ismissing(names))||numel(unique(names))~=1||strlength(names(1))==0
            error('pv:csvLocation','La columna localidad debe contener un único nombre no vacío.');
        end
        latitudes=t.latitud_deg;longitudes=t.longitud_deg;
        if ~isnumeric(latitudes)||~isnumeric(longitudes)||any(~isfinite(latitudes))|| ...
                any(~isfinite(longitudes))||any(abs(latitudes-latitudes(1))>1e-8)|| ...
                any(abs(longitudes-longitudes(1))>1e-8)||abs(latitudes(1))>90||abs(longitudes(1))>180
            error('pv:csvCoordinates','Las coordenadas deben ser numéricas y constantes en todo el CSV.');
        end
        numericNames=required(4:end);
        for n=1:numel(numericNames)
            column=t.(numericNames{n});
            if ~isnumeric(column)||any(isinf(column))
                error('pv:csvNumeric','La columna %s debe contener valores numéricos finitos o vacíos.',numericNames{n});
            end
        end
        optionalNames={'perdida_aoi','perdida_espectral','perdida_temperatura'};
        for n=1:numel(optionalNames)
            if ismember(optionalNames{n},t.Properties.VariableNames)
                column=t.(optionalNames{n});
                if ~isnumeric(column)||any(isinf(column))
                    error('pv:csvNumeric','La columna %s debe contener valores numéricos finitos o vacíos.',optionalNames{n});
                end
            end
        end
        inclinaciones=0:5:90;acimuts=-170:10:180;expected=[numel(inclinaciones),numel(acimuts)];
        productividad=nan(expected);irradiacion=nan(expected);
        perd_aoi=nan(expected);perd_esp=nan(expected);perd_temp=nan(expected);seen=false(expected);
        for row=1:height(t)
            tilt=t.inclinacion_deg(row);azimuth=t.acimut_pvgis_deg(row);
            i=find(abs(inclinaciones-tilt)<1e-8,1);j=find(abs(acimuts-azimuth)<1e-8,1);
            if isempty(i)||isempty(j)
                error('pv:csvOrientation','La fila %d contiene una orientación fuera de la malla esperada.',row+1);
            end
            if seen(i,j),error('pv:csvDuplicate','La orientación de la fila %d aparece duplicada.',row+1);end
            seen(i,j)=true;
            productividad(i,j)=t.produccion_kWh_kWp_anio(row);
            irradiacion(i,j)=t.irradiacion_kWh_m2_anio(row);
            perd_aoi(i,j)=valorCSV(t,'perdida_aoi',row);
            perd_esp(i,j)=valorCSV(t,'perdida_espectral',row);
            perd_temp(i,j)=valorCSV(t,'perdida_temperatura',row);
        end
        fresh=struct('localidad',char(names(1)),'latitud',latitudes(1),'longitud',longitudes(1), ...
            'lat',latitudes(1),'lon',longitudes(1),'productividad',productividad, ...
            'irradiacion',irradiacion,'perd_aoi',perd_aoi,'perd_esp',perd_esp,'perd_temp',perd_temp, ...
            'max_pro',max(productividad,[],'all','omitnan'), ...
            'max_irr',max(irradiacion,[],'all','omitnan'), ...
            'inclinaciones',inclinaciones,'acimuts',acimuts, ...
            'fecha_consulta',char(datetime('now','Format','yyyy-MM-dd HH:mm:ss')));
    end
    function value=valorCSV(t,name,row)
        if ismember(name,t.Properties.VariableNames)
            column=t.(name);value=column(row);
        else
            value=NaN;
        end
    end
    function clearCharts(message)
        if isgraphics(cbCart),delete(cbCart);end
        if isgraphics(cbPolar),delete(cbPolar);end
        for ax=axesHandles,cla(ax);title(ax,'');subtitle(ax,'');end
        emptyMetrics();metrics(1).Text=sprintf('%s\n%+.4f° / %+.4f°',result.localidad,result.latitud,result.longitud);
        metrics(4).Text=sprintf('Datos válidos\n%d / %d',validCount(),numel(result.productividad));
        status.Text=message;summary.Text=message;
    end
    function redraw(varargin)
        if isempty(result),return;end
        if strcmp(metric.Value,'Irradiación anual')
            z=result.irradiacion;unit='kWh/m²/año';name='Irradiación anual';
        else
            z=result.productividad;unit='kWh/kWp/año';name='Producción anual';
        end
        zmax=max(z,[],'all','omitnan');if ~isfinite(zmax)||zmax<=0,clearCharts('No hay valores positivos válidos para representar esta magnitud.');return;end
        if strcmp(scale.Value,'Porcentaje del máximo')
            if zmax<=0,status.Text='Los datos no contienen valores positivos para normalizar.';return;end
            z=100*z/zmax;unit='% del máximo';levels=0:5:100;limits=[0 100];
        else
            if zmax<=0,status.Text='Los datos no contienen valores positivos para representar.';return;end
            levels=linspace(0,zmax,21);limits=[0 zmax];
        end
        plotCartesian(z,name,unit,levels,limits);plotPolar(z,name,unit,levels,limits);
        if strcmp(metric.Value,'Irradiación anual'),raw=result.irradiacion;else,raw=result.productividad;end
        [bestRaw,k]=max(raw(:),[],'omitnan');[ii,jj]=ind2sub(size(raw),k);
        [mp,kp]=max(result.productividad(:),[],'omitnan');[ip,jp]=ind2sub(size(result.productividad),kp);
        [mh,kh]=max(result.irradiacion(:),[],'omitnan');[ih,jh]=ind2sub(size(result.irradiacion),kh);
        metrics(2).Text=sprintf('Producción máxima\n%.1f kWh/kWp/año\nβ %.0f° · A %.0f°',mp,result.inclinaciones(ip),result.acimuts(jp));
        metrics(3).Text=sprintf('Irradiación máxima\n%.1f kWh/m²/año\nβ %.0f° · A %.0f°',mh,result.inclinaciones(ih),result.acimuts(jh));
        metrics(4).Text=sprintf('Datos válidos\n%d / %d',validCount(),numel(result.productividad));
        for ax=axesHandles,ax.Toolbar.Visible='off';end
        summary.Text=sprintf('%s, %.3f° N / %.3f° E\nMáximo de %s: %.1f %s · inclinación %.0f° · acimut %.0f°', ...
            result.localidad,result.latitud,result.longitud,name,bestRaw,rawUnit(),result.inclinaciones(ii),result.acimuts(jj));
    end
    function u=rawUnit()
        if strcmp(metric.Value,'Irradiación anual'),u='kWh/m²/año';else,u='kWh/kWp/año';end
    end
    function plotCartesian(z,name,unit,levels,limits)
        if isgraphics(cbCart),delete(cbCart);end
        cla(cartAx);hold(cartAx,'off');
        contourf(cartAx,[result.acimuts(end)-360 result.acimuts],result.inclinaciones,[z(:,end) z],levels,'LineStyle','none');
        clim(cartAx,limits);
        colormap(cartAx,parula(20));cbCart=colorbar(cartAx);cbCart.Label.String=unit;
        xlabel(cartAx,'Acimut PVGIS (°)');ylabel(cartAx,'Inclinación (°)');
        title(cartAx,'');subtitle(cartAx,sprintf('%s · %s · %s',result.localidad,name,unit));cartAx.XTick=-180:30:180;
        xlim(cartAx,[-180 180]);ylim(cartAx,[0 90]);grid(cartAx,'on');cartAx.Layer='top';
    end
    function plotPolar(z,name,unit,levels,limits)
        if isgraphics(cbPolar),delete(cbPolar);end
        cla(polarAx);hold(polarAx,'off');
        az=[result.acimuts result.acimuts(1)+360];el=result.inclinaciones;zclosed=[z z(:,1)];
        theta=deg2rad(az-90);[TH,R]=meshgrid(theta,el);[X,Y]=pol2cart(TH,R);
        contourf(polarAx,X,Y,zclosed,levels,'LineStyle','none');clim(polarAx,limits);hold(polarAx,'on');
        colormap(polarAx,parula(20));
        th=linspace(0,2*pi,361);
        for radius=10:10:90
            plot(polarAx,radius*cos(th),radius*sin(th),'k:','LineWidth',.55,'HandleVisibility','off');
        end
        for a=-150:30:180
            q=deg2rad(a-90);plot(polarAx,[0 90*cos(q)],[0 90*sin(q)],'k:','LineWidth',.55,'HandleVisibility','off');
            text(polarAx,99*cos(q),99*sin(q),sprintf('%d°',a), ...
                'HorizontalAlignment','center','FontSize',8,'Color',[.15 .15 .15]);
        end
        for radius=0:10:90
            text(polarAx,radius*cos(pi/4),radius*sin(pi/4),sprintf('%d°',radius), ...
                'HorizontalAlignment','center','FontSize',8,'Color',[.15 .15 .15]);
        end
        plot(polarAx,90*cos(th),90*sin(th),'Color',[.25 .28 .27],'LineWidth',1.2,'HandleVisibility','off');
        hold(polarAx,'off');axis(polarAx,'equal');xlim(polarAx,[-108 108]);ylim(polarAx,[-108 108]);
        polarAx.XTick=[];polarAx.YTick=[];polarAx.Box='off';polarAx.XColor='none';polarAx.YColor='none';
        cbPolar=colorbar(polarAx);cbPolar.Label.String=unit;
        title(polarAx,'');subtitle(polarAx,sprintf('%s · %s · %s',result.localidad,name,unit));
    end
end

function r=validarDatos(s,file)
required={'productividad','irradiacion'};
for k=1:numel(required)
    if ~isfield(s,required{k}),error('Falta la variable %s.',required{k});end
end
expected=[19 36];
if ~isequal(size(s.productividad),expected)||~isequal(size(s.irradiacion),expected)
    error('Las matrices deben tener tamaño 19 × 36 (inclinación 0:5:90 y acimut -170:10:180).');
end
if isfield(s,'localidad'),name=char(string(s.localidad));else,name='Localidad';end
lat=fieldOr(s,'latitud',fieldOr(s,'lat',NaN));lon=fieldOr(s,'longitud',fieldOr(s,'lon',NaN));
if (~isfinite(lat)||~isfinite(lon))
    [~,base]=fileparts(file);parts=strsplit(base,'_');
    if numel(parts)>=4,lat=str2double(parts{end-1});lon=str2double(parts{end});end
end
if ~isfinite(lat),lat=40;end;if ~isfinite(lon),lon=-5;end
validateattributes(lat,{'numeric'},{'scalar','finite','>=',-90,'<=',90});validateattributes(lon,{'numeric'},{'scalar','finite','>=',-180,'<=',180});
for f={'productividad','irradiacion','perd_aoi','perd_esp','perd_temp'}
    if isfield(s,f{1}),assert(isnumeric(s.(f{1}))&&isreal(s.(f{1}))&&isequal(size(s.(f{1})),expected)&&~any(isinf(s.(f{1})),'all'),'Matriz de datos no válida: %s',f{1});end
end
incl=0:5:90;azi=-170:10:180;
if isfield(s,'inclinaciones'),incl=s.inclinaciones;end
if isfield(s,'acimuts'),azi=s.acimuts;end
assert(isequal(incl,0:5:90)&&isequal(azi,-170:10:180),'La malla angular no es compatible.');
maxp=fieldOr(s,'max_pro',max(s.productividad,[],'all','omitnan'));
maxh=fieldOr(s,'max_irr',max(s.irradiacion,[],'all','omitnan'));
r=struct('localidad',name,'latitud',lat,'longitud',lon,'lat',lat,'lon',lon, ...
    'productividad',s.productividad,'irradiacion',s.irradiacion,'max_pro',maxp,'max_irr',maxh, ...
    'inclinaciones',incl,'acimuts',azi);
for f={'perd_aoi','perd_esp','perd_temp'}
    if isfield(s,f{1}),r.(f{1})=s.(f{1});else,r.(f{1})=nan(expected);end
end
end

function value=fieldOr(s,name,default)
if isfield(s,name)&&isnumeric(s.(name))&&isscalar(s.(name))&&isfinite(s.(name)),value=s.(name);else,value=default;end
end
