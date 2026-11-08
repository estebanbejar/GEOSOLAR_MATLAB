classdef GeosolarApp < handle
    properties (SetAccess=private)
        Figure
        Axes
        State
        Controls
        Metrics
        Orbit
        Fixed
        EO
        Tracking
        Productivity
        Hourly
        Credits
        Location
        ActiveLab=2
        NavigationButtons
        DataTable
        Clock
        Playing=false
        LastError=""
    end
    properties (Access=private)
        PersistLocation=true
        LocationFile
        Panel
        BasicSide
        Placeholder
        LastTick
        Lines
        Marker
        CacheKey=""
        Status
        Dragging=false
        DragStartX
        DragStartAzimuth
    end
    methods
        function app=GeosolarApp(options)
            arguments
                options.Visible (1,1) string="on"
                options.PersistLocation (1,1) logical=true
                options.LocationFile (1,1) string=""
            end
            app.State=app.defaults();
            app.PersistLocation=options.PersistLocation;
            app.Location=struct('lat',40.459133,'lon',-5.814857,'name','Béjar', ...
                'zone','Europe/Madrid','zoneResolved',true,'zoneNote','Huso IANA de Béjar. Incluye horario de verano según la fecha.');
            file=fullfile(fileparts(mfilename('fullpath')),'data','shared_location.json');
            if strlength(options.LocationFile)>0,file=char(options.LocationFile);end
            app.LocationFile=file;
            if app.PersistLocation && isfile(file)
                try
                    location=jsondecode(fileread(file));app.validateLocation(location);app.Location=location;
                catch
                    % Preferencia dañada: iniciar con coordenadas válidas sin impedir apertura.
                end
            end
            app.State.lat=app.Location.lat;
            app.Location=app.resolveLocationZone(app.Location);
            app.Figure=uifigure('Name','GEOSOLAR MATLAB · Piloto 0.7', ...
                'Position',[30 30 1500 960],'Visible',options.Visible,'Color',[.965 .961 .945]);
            app.Figure.CloseRequestFcn=@(~,~)delete(app);
            app.Figure.WindowState='maximized';
            shell=uigridlayout(app.Figure,[3 1]);shell.RowHeight={64,42,'1x'};
            head=uigridlayout(shell,[1 2]);head.ColumnWidth={195,'1x'};
            uiimage(head,'ImageSource',fullfile(fileparts(mfilename('fullpath')),'assets','usal.png'),'ScaleMethod','fit');
            uilabel(head,'Text',{'Universidad de Salamanca · GEOSOLAR MATLAB', ...
                'Escuela Técnica Superior de Ingeniería Industrial · Área de Tecnología Electrónica'},'FontSize',16,'FontWeight','bold');
            nav=uigridlayout(shell,[1 8]);nav.ColumnWidth=[repmat({'1x'},1,7),{85}];
            names={'01 Órbita','02 Geometría solar','03 Filas fijas','04 Este–Oeste','05 Seguimiento 1 eje','06 Productividad','07 Series horarias','Créditos'};
            app.NavigationButtons=gobjects(1,8);
            for k=1:8
                app.NavigationButtons(k)=uibutton(nav,'Text',names{k},'FontSize',11,'ButtonPushedFcn',@(~,~)app.selectLab(k,names{k}));
            end
            body=uigridlayout(shell,[1 2]);body.ColumnWidth={270,'1x'};
            sideHost=uigridlayout(body,[1 1]);sideHost.Padding=[0 0 0 0];
            app.BasicSide=uipanel(sideHost,'BorderType','none');app.BasicSide.Layout.Row=1;app.BasicSide.Layout.Column=1;
            side=uigridlayout(app.BasicSide,[17 1]);side.Scrollable='on';
            side.RowHeight={32,54,54,32,54,32,32,54,54,32,32,32,32,32,32,60,70};
            uilabel(side,'Text','02 · Geometría solar','FontWeight','bold','FontSize',17);
            app.addRange(side,'lat','Latitud (°)',[-90 90],40);
            app.addRange(side,'day','Día del año · 2026',[1 365],355);
            app.Controls.mode=uidropdown(side,'Items',{'Según fecha','Manual'},'ItemsData',{'date','manual'},'Value','date','ValueChangedFcn',@(s,~)app.setParameter('mode',s.Value));
            app.addRange(side,'delta','Declinación manual (°)',[-23.45 23.45],-23.45);
            presets=uigridlayout(side,[1 3]);presets.Padding=[0 0 0 0];
            ds=[23.45 0 -23.45];labels={'Junio','Equinoccio','Diciembre'};
            for k=1:3,uibutton(presets,'Text',labels{k},'ButtonPushedFcn',@(~,~)app.ideal(ds(k)));end
            app.Controls.animation=uidropdown(side,'Items',{'Animación diaria','Animación anual'},'ItemsData',{'daily','annual'},'ValueChangedFcn',@(s,~)app.setParameter('animation',s.Value));
            app.addRange(side,'speed','Velocidad (diaria: h/s)',[.5 10],1.5);
            app.addRange(side,'camera','Giro horizontal de 02 (°)',[-180 180],-35);
            app.Controls.play=uibutton(side,'Text','▶ Reproducir','ButtonPushedFcn',@(~,~)app.toggle());
            uibutton(side,'Text','■ Restablecer','ButtonPushedFcn',@(~,~)app.reset());
            uibutton(side,'Text','Guardar escenario JSON','ButtonPushedFcn',@(~,~)app.saveDialog());
            uibutton(side,'Text','Abrir escenario JSON','ButtonPushedFcn',@(~,~)app.loadDialog());
            uibutton(side,'Text','Exportar tabla CSV','ButtonPushedFcn',@(~,~)app.csvDialog());
            uibutton(side,'Text','Captura completa PNG','ButtonPushedFcn',@(~,~)app.pngDialog(0));
            app.Status=uilabel(side,'Text','Disponibles: laboratorios 01–07.','WordWrap','on');
            uilabel(side,'Text','Predice: ¿dónde culmina el Sol en el Ecuador durante un equinoccio? ¿Qué cambia entre +40° y −40°?','WordWrap','on');
            host=uigridlayout(body,[1 1]);host.Padding=[0 0 0 0];
            app.Panel=uipanel(host,'BorderType','none');
            app.Panel.Layout.Row=1;app.Panel.Layout.Column=1;
            content=uigridlayout(app.Panel,[7 2]);content.Scrollable='on';
            content.ColumnWidth={'1x','1x'};content.RowHeight={90,430,340,340,60,260,100};
            frame=uipanel(content,'BorderType','line','HighlightColor',[.6 .63 .62]);frame.Layout.Column=[1 2];
            board=uigridlayout(frame,[1 7]);board.Padding=[4 4 4 4];
            app.Metrics=gobjects(1,7);
            for k=1:7
                cellFrame=uipanel(board,'BorderType','line','HighlightColor',[.75 .77 .76]);
                cellGrid=uigridlayout(cellFrame,[1 1]);cellGrid.Padding=[8 4 4 4];
                app.Metrics(k)=uilabel(cellGrid,'WordWrap','on','FontWeight','bold');
            end
            titles={'01 Latitud y altura al mediodía','02 Recorridos solares','03 Ángulo horario', ...
                '04 Altura y acimut','05 Carta polar de trayectorias solares','06 Carta de trayectorias solares'};
            app.Axes=gobjects(1,6);
            for k=1:6
                box=uigridlayout(content,[2 1]);box.Layout.Row=1+ceil(k/2);box.Layout.Column=1+mod(k-1,2);box.RowHeight={28,'1x'};box.Padding=[2 2 2 2];
                row=uigridlayout(box,[1 2]);row.ColumnWidth={'1x',60};row.Padding=[0 0 0 0];
                uilabel(row,'Text',titles{k},'FontWeight','bold');uibutton(row,'Text','PNG','ButtonPushedFcn',@(~,~)app.pngDialog(k));
                app.Axes(k)=uiaxes(box);app.Axes(k).FontSize=10;
                toolbar=axtoolbar(app.Axes(k),{});toolbar.Visible='off';
            end
            time=uigridlayout(content,[1 3]);time.Layout.Row=5;time.Layout.Column=[1 2];time.ColumnWidth={100,'1x',85};
            uilabel(time,'Text','Hora solar (h)');
            app.Controls.timeSlider=uislider(time,'Limits',[0 24],'Value',12,'MajorTicks',0:6:24, ...
                'ValueChangingFcn',@(~,e)app.setParameter('time',e.Value),'ValueChangedFcn',@(s,~)app.setParameter('time',s.Value));
            app.Controls.time=uieditfield(time,'numeric','Limits',[0 24],'Value',12,'ValueChangedFcn',@(s,~)app.setParameter('time',s.Value));
            app.DataTable=uitable(content);app.DataTable.Layout.Row=6;app.DataTable.Layout.Column=[1 2];
            note=uilabel(content,'Text',{'ω = 15°(tₛ − 12) · sin α = sin φ sin δ + cos φ cos δ cos ω', ...
                'Acimut desde el Sur: Este negativo. Cartas: solo Sol sobre el horizonte; líneas horarias sin analema.', ...
                'Año didáctico 2026. En cenit/nadir el acimut es indeterminado; en los polos el marco es convencional.'},'WordWrap','on');note.Layout.Row=7;note.Layout.Column=[1 2];
            app.Placeholder=uilabel(host,'Text','','FontSize',20,'WordWrap','on','Visible','off');
            app.Placeholder.Layout.Row=1;app.Placeholder.Layout.Column=1;
            app.Clock=timer('Name','GEOSOLAR_Pilot','ExecutionMode','fixedSpacing','Period',.12,'TimerFcn',@(~,~)app.tick(),'ErrorFcn',@(~,~)app.stop());
            app.refresh();
            disableDefaultInteractivity(app.Axes(2));app.Axes(2).Interactions=[];
            targets=findall(app.Axes(2),'-property','ButtonDownFcn');
            set(targets,'ButtonDownFcn',@(~,~)app.beginRotation());
            app.Figure.WindowButtonMotionFcn=@(~,~)app.dragRotation();
            app.Figure.WindowButtonUpFcn=@(~,~)app.endRotation();
            app.Orbit=GeosolarOrbitLab(sideHost,host,app);
            app.Fixed=GeosolarFixedLab(sideHost,host,app);
            app.EO=GeosolarEOLab(sideHost,host,app);
            app.Tracking=GeosolarTrackingLab(sideHost,host,app);
            app.Productivity=geosolarproductivity.build(sideHost,host,app);
            app.Productivity.adoptLocation(app.Location);
            app.Hourly=GeosolarHourlyLab(sideHost,host,app);
            app.Credits=GeosolarCredits(sideHost,host);
            app.Fixed.adoptLocation(app.Location);app.EO.adoptLocation(app.Location);app.Tracking.adoptLocation(app.Location);
            carta=fullfile(fileparts(mfilename('fullpath')),'data','productividad','PVGIS_Béjar_40.459_-5.815.csv');
            try
                app.Productivity.loadData(carta,false);
            catch err
                app.Productivity.Status.Text=['No se pudo precargar la carta de Béjar: ' err.message];
            end
            app.selectLab(1,'Órbita');
        end
        function setParameter(app,key,value)
            s=app.State;s.(key)=value;
            if strcmp(key,'day'),s.day=round(s.day);end
            app.validate(s);app.State=s;
            if strcmp(key,'lat'),app.setLocation(s.lat,app.Location.lon,'Punto personalizado');else,app.refresh();end
        end
        function previewLatitude(app,value)
            validateattributes(value,{'double'},{'scalar','real','finite','>=',-90,'<=',90});
            app.State.lat=value;app.refresh();
        end
        function ideal(app,d)
            app.State.mode='manual';app.State.delta=d;app.refresh();
        end
        function reset(app)
            app.stop();app.State=app.defaults();app.State.lat=app.Location.lat;app.CacheKey="";app.refresh();
        end
        function toggle(app)
            if ismember(app.ActiveLab,[6 7 8]),return;end
            if app.Playing,app.stop();return;end
            if app.ActiveLab==3 && ~app.Fixed.Valid,return;end
            if app.ActiveLab==4 && ~app.EO.Valid,return;end
            if app.ActiveLab==5 && (~app.Tracking.Valid||app.Tracking.Busy),return;end
            if app.ActiveLab==2 && strcmp(app.State.animation,'annual'),app.State.mode='date';end
            app.Playing=true;app.LastTick=tic;app.Controls.play.Text='⏸ Pausar';
            if ~isempty(app.Orbit),app.Orbit.Controls.Play.Text='⏸ Pausar';end
            if ~isempty(app.Fixed),app.Fixed.Controls.Play.Text='⏸ Pausar';end
            if ~isempty(app.EO),app.EO.Controls.Play.Text='⏸ Pausar';end
            if ~isempty(app.Tracking),app.Tracking.Controls.Play.Text='⏸ Pausar';end
            start(app.Clock);
        end
        function stop(app)
            app.Playing=false;
            if ~isempty(app.Clock)&&isvalid(app.Clock),stop(app.Clock);end
            if ~isempty(app.Figure)&&isvalid(app.Figure),app.Controls.play.Text='▶ Reproducir';end
            if ~isempty(app.Orbit)&&isvalid(app.Orbit.Controls.Play),app.Orbit.Controls.Play.Text='▶ Reproducir';end
            if ~isempty(app.Fixed)&&isvalid(app.Fixed.Controls.Play),app.Fixed.Controls.Play.Text='▶ Reproducir';end
            if ~isempty(app.EO)&&isvalid(app.EO.Controls.Play),app.EO.Controls.Play.Text='▶ Reproducir';end
            if ~isempty(app.Tracking)&&isvalid(app.Tracking.Controls.Play),app.Tracking.Controls.Play.Text='▶ Reproducir';end
        end
        function tick(app)
            try
                dt=toc(app.LastTick);app.LastTick=tic;
                if app.ActiveLab==5
                    app.Tracking.advance(dt);return;
                end
                if app.ActiveLab==4
                    app.EO.advance(dt);return;
                end
                if app.ActiveLab==3
                    app.Fixed.advance(dt);return;
                end
                if app.ActiveLab==1
                    app.Orbit.advance(dt*app.Orbit.Controls.Speed.Value);return;
                end
                if strcmp(app.State.animation,'annual')
                    app.State.day=1+mod(app.State.day-1+dt*6*app.State.speed,364);
                else,app.State.time=mod(app.State.time+dt*app.State.speed,24);end
                app.refresh();
            catch err,app.LastError=string(err.message);app.stop();app.Status.Text=err.message;end
        end
        function selectLab(app,k,name)
            if ~ismember(k,1:8),return;end
            app.stop();app.Dragging=false;app.ActiveLab=k;
            app.Panel.Visible=matlab.lang.OnOffSwitchState(k==2);app.BasicSide.Visible=matlab.lang.OnOffSwitchState(k==2);
            app.Orbit.Panel.Visible=matlab.lang.OnOffSwitchState(k==1);app.Orbit.Side.Visible=matlab.lang.OnOffSwitchState(k==1);
            app.Fixed.Panel.Visible=matlab.lang.OnOffSwitchState(k==3);app.Fixed.Side.Visible=matlab.lang.OnOffSwitchState(k==3);
            app.EO.Panel.Visible=matlab.lang.OnOffSwitchState(k==4);app.EO.Side.Visible=matlab.lang.OnOffSwitchState(k==4);
            app.Tracking.Panel.Visible=matlab.lang.OnOffSwitchState(k==5);app.Tracking.Side.Visible=matlab.lang.OnOffSwitchState(k==5);
            app.Productivity.Panel.Visible=matlab.lang.OnOffSwitchState(k==6);app.Productivity.Side.Visible=matlab.lang.OnOffSwitchState(k==6);
            app.Hourly.Panel.Visible=matlab.lang.OnOffSwitchState(k==7);app.Hourly.Side.Visible=matlab.lang.OnOffSwitchState(k==7);
            app.Credits.Panel.Visible=matlab.lang.OnOffSwitchState(k==8);app.Credits.Side.Visible=matlab.lang.OnOffSwitchState(k==8);
            if k==7,app.Hourly.activate();end
            if k==2,app.refresh();end
            if ismember(k,[3 4 5])
                % Resolver primero el tamaño visible, después la cámara y el encuadre.
                drawnow nocallbacks;
                if k==3,app.Fixed.rebuild();elseif k==4,app.EO.rebuild();else,app.Tracking.rebuild();end
                drawnow nocallbacks;
            end
        end
        function setLocation(app,lat,lon,name)
            location=struct('lat',lat,'lon',lon,'name',char(name));app.validateLocation(location);
            if lat==app.Location.lat&&lon==app.Location.lon&&isfield(app.Location,'zone')&&isfield(app.Location,'zoneResolved')&&app.Location.zoneResolved
                location.zone=app.Location.zone;location.zoneResolved=true;location.zoneNote='Huso IANA detectado según la ubicación.';
            else
                location=app.resolveLocationZone(location);
            end
            app.stop();app.Location=location;app.State.lat=lat;
            if ~isempty(app.Fixed),app.Fixed.adoptLocation(location);end
            if ~isempty(app.EO),app.EO.adoptLocation(location);end
            if ~isempty(app.Tracking),app.Tracking.adoptLocation(location);end
            if ~isempty(app.Productivity),app.Productivity.adoptLocation(location);end
            if ~isempty(app.Hourly),app.Hourly.adoptLocation(location);end
            app.CacheKey="";
            if app.ActiveLab==2,app.refresh();elseif app.ActiveLab==3,app.Fixed.rebuild();elseif app.ActiveLab==4,app.EO.rebuild();elseif app.ActiveLab==5,app.Tracking.rebuild();end
            if app.PersistLocation
                folder=fileparts(app.LocationFile);if ~isfolder(folder),mkdir(folder);end
                temporary=[tempname(folder) '.json'];fid=fopen(temporary,'w','n','UTF-8');
                if fid>=0,fprintf(fid,'%s',jsonencode(location));fclose(fid);movefile(temporary,app.LocationFile,'f');end
            end
        end
        function refresh(app)
            s=app.State;n=round(s.day);d=s.delta;if strcmp(s.mode,'date'),d=geosolar.declination(n);end
            keys={'lat','day','delta','speed','camera'};
            for k=1:numel(keys),key=keys{k};app.Controls.(key).Field.Value=s.(key);app.Controls.(key).Slider.Value=s.(key);end
            app.Controls.mode.Value=s.mode;app.Controls.animation.Value=s.animation;
            en=strcmp(s.mode,'manual');app.Controls.delta.Field.Enable=en;app.Controls.delta.Slider.Enable=en;
            app.Controls.time.Value=s.time;app.Controls.timeSlider.Value=s.time;
            p=geosolar.position(s.lat,d,s.time);day=geosolar.daylight(s.lat,d);
            date=datetime(2026,1,1)+days(n-1);date.Format='dd/MM/yyyy';
            values={sprintf('Fecha\n%s',char(date)),sprintf('Hora\n%02d:%02d',floor(s.time),min(59,floor(mod(s.time,1)*60))), 'Hora solar',sprintf('Altura\n%.2f°',p.alpha),sprintf('Acimut\n%s°',app.number(p.gamma)),sprintf('Declinación\n%.2f°',d),sprintf('Día\n%s h',app.number(day.hours))};
            for k=1:7,app.Metrics(k).Text=values{k};end
            state=struct('phi',s.lat,'delta',d,'time',s.time);
            ids=[4 5 3];for k=1:3
                geosolar.drawView(app.Axes(k),ids(k),state);title(app.Axes(k),'');app.Axes(k).Subtitle.FontSize=10;
                if k<=2 && ~isappdata(app.Axes(k),'suiteZoom')
                    camzoom(app.Axes(k),1.4);setappdata(app.Axes(k),'suiteZoom',true);
                end
            end
            view(app.Axes(2),[s.camera 22]);app.localView(p);
            key=string(sprintf('%.12g_%.12g',s.lat,d));
            if app.CacheKey~=key
                app.drawCards(d);ts=linspace(0,24,97)';q=geosolar.position(s.lat,d,ts);
                app.DataTable.Data=table(ts,q.alpha,q.omega,q.gamma,'VariableNames',{'hora_solar_h','altura_grados','angulo_horario_grados','acimut_desde_sur_grados'});
                app.CacheKey=key;
            end
            if p.U>=-1e-10&&isfinite(p.gamma)
                a=deg2rad(p.gamma+180);r=90-p.alpha;
                set(app.Marker(1),'XData',r*sin(a),'YData',r*cos(a));set(app.Marker(2),'XData',app.chartAzimuth(p.gamma),'YData',p.alpha);
            else,set(app.Marker,'XData',nan,'YData',nan);end
            for ax=app.Axes,ax.Toolbar.Visible='off';end
            drawnow limitrate;
        end
        function localView(app,p)
            ax=app.Axes(4);cla(ax);hold(ax,'on');q=linspace(0,2*pi,100);
            plot3(ax,cos(q),sin(q),zeros(size(q)),'Color',[.6 .65 .6]);
            c=[.55 .14 .24];if p.U<0,c=[.5 .5 .5];end
            quiver3(ax,0,0,0,p.E,p.N,p.U,0,'Color',c,'LineWidth',2);
            plot3(ax,[0 p.E p.E],[0 p.N p.N],[0 0 p.U],'--','Color',c);
            plot3(ax,p.E,p.N,p.U,'o','MarkerFaceColor',c,'Color',c);
            if p.horizontalNorm>1e-10
                a=linspace(0,p.alpha,60);plot3(ax,.5*p.E/p.horizontalNorm*cosd(a),.5*p.N/p.horizontalNorm*cosd(a),.5*sind(a),'Color',c);
                a=linspace(0,p.gamma,60);plot3(ax,-.35*sind(a),-.35*cosd(a),zeros(size(a)),'Color',[.2 .4 .6]);
            end
            text(ax,1.1,0,0,'Este');text(ax,0,1.1,0,'Norte');text(ax,0,0,1.1,'Cenit');
            axis(ax,'equal');axis(ax,[-1.2 1.2 -1.2 1.2 -1.2 1.2]);view(ax,[-35 22]);grid(ax,'off');axis(ax,'off');hold(ax,'off');
        end
        function drawCards(app,d)
            for ax=app.Axes(5:6),cla(ax);hold(ax,'on');end
            ax=app.Axes(5);a=linspace(0,2*pi,181);
            for r=30:30:60,plot(ax,r*sin(a),r*cos(a),':','Color',[.8 .8 .8]);end
            plot(ax,90*sin(a),90*cos(a),'-','Color',[.3 .34 .32],'LineWidth',1.4,'Tag','polarHorizon');
            for az=0:15:345
                plot(ax,[0 90*sind(az)],[0 90*cosd(az)],':','Color',[.7 .73 .71],'LineWidth',.7,'Tag','polarRadial');
            end
            ds=[-20 -11.5 11.5 20 23.45 0 -23.45 d];colors=[repmat([.65 .68 .65],4,1);.71 .5 .16;.24 .5 .4;.22 .42 .58;.55 .14 .24];
            for k=1:numel(ds)
                hours=linspace(0,24,721);dl=geosolar.daylight(app.State.lat,ds(k));
                if isfinite(dl.sunrise),hours=unique([hours dl.sunrise dl.sunset]);end
                q=geosolar.position(app.State.lat,ds(k),hours);app.cardLine(q,colors(k,:),'-',1+(k==8));
            end
            for h=0:23
                q=geosolar.position(app.State.lat,linspace(-23.45,23.45,121),h);app.cardLine(q,[.7 .72 .7],':',.6);
                valid=find(q.U>=0 & isfinite(q.gamma),1);
                if ~isempty(valid)&&mod(h,2)==0,aa=deg2rad(q.gamma(valid)+180);rr=90-q.alpha(valid);text(ax,rr*sin(aa),rr*cos(aa),sprintf('%dh',h),'FontSize',8);end
            end
            % Acimut firmado desde Sur, coherente con los indicadores y la tabla.
            for bearing=0:30:330
                gamma=mod(bearing,360)-180;
                label=sprintf('%d°',gamma);
                switch bearing
                    case 0,label='N ±180°';
                    case 90,label='E −90°';
                    case 180,label='S 0°';
                    case 270,label='O +90°';
                end
                text(ax,104*sind(bearing),104*cosd(bearing),label,'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle','FontSize',9,'Color',[.2 .25 .23],'Tag','polarAzimuthLabel');
            end
            for altitude=[0 30 60]
                radius=90-altitude;
                text(ax,radius*sind(45),radius*cosd(45),sprintf('α %d°',altitude),'HorizontalAlignment','center', ...
                    'BackgroundColor','white','Margin',1,'FontSize',9,'Tag','polarAltitudeLabel');
            end
            text(ax,0,0,'Cenit 90°','HorizontalAlignment','center','BackgroundColor','white','Margin',1,'FontSize',9,'Tag','polarAltitudeLabel');
            axis(ax,'equal');axis(ax,[-122 122 -116 116]);ax.XTick=[];ax.YTick=[];
            ax=app.Axes(6);
            if app.State.lat<0
                xlim(ax,[0 360]);xticks(ax,0:15:360);xlabel(ax,'Acimut desde Sur (°) · Norte = 180°');
            else
                xlim(ax,[-180 180]);xticks(ax,-180:15:180);xlabel(ax,'Acimut desde Sur (°) · Este negativo');
            end
            ylim(ax,[0 90]);grid(ax,'on');ylabel(ax,'Altura (°)');
            app.Marker=gobjects(1,2);for k=1:2,app.Marker(k)=plot(app.Axes(k+4),nan,nan,'o','MarkerFaceColor',[.8 .6 .15],'MarkerEdgeColor','k');hold(app.Axes(k+4),'off');end
            title(app.Axes(5),'');subtitle(app.Axes(5),'Junio · equinoccio · diciembre · seleccionado');
            title(app.Axes(6),'');subtitle(app.Axes(6),'Trayectorias y horas solares');
        end
        function cardLine(app,q,color,style,width)
            bad=q.U< -1e-10|~isfinite(q.gamma);a=deg2rad(q.gamma+180);r=90-q.alpha;x=r.*sin(a);y=r.*cos(a);x(bad)=nan;y(bad)=nan;
            plot(app.Axes(5),x,y,'Color',color,'LineStyle',style,'LineWidth',width);
            az=app.chartAzimuth(q.gamma);alt=q.alpha;bad=bad|[false abs(diff(az))>180];az(bad)=nan;alt(bad)=nan;
            plot(app.Axes(6),az,alt,'Color',color,'LineStyle',style,'LineWidth',width);
        end
        function saveScenario(app,file)
            scenario=struct('format','GEOSOLAR','version',1,'model','matlab-compat-v1','lab','basic','parameters',app.State);
            fid=fopen(file,'w','n','UTF-8');assert(fid>=0,'No se puede abrir el archivo');c=onCleanup(@()fclose(fid));fprintf(fid,'%s',jsonencode(scenario,PrettyPrint=true));
        end
        function loadScenario(app,file)
            x=jsondecode(fileread(file));assert(strcmp(x.format,'GEOSOLAR')&&x.version==1&&strcmp(x.model,'matlab-compat-v1')&&strcmp(x.lab,'basic'),'Escenario incompatible');
            app.validate(x.parameters);app.stop();app.State=x.parameters;app.setLocation(app.State.lat,app.Location.lon,'Escenario de geometría solar');
        end
        function exportCsv(app,file)
            fid=fopen(file,'w','n','UTF-8');assert(fid>=0,'No se puede abrir el archivo');
            fprintf(fid,'# GEOSOLAR; basic; matlab-compat-v1\n# parameters: %s\n# Campos vacíos: resultado indeterminado\n',jsonencode(app.State));fclose(fid);
            writetable(app.DataTable.Data,file,'Delimiter',';','Encoding','UTF-8','WriteMode','append','WriteVariableNames',true);
        end
        function saveDialog(app)
            [f,p]=uiputfile('*.json');if ~isequal(f,0),app.saveScenario(fullfile(p,f));end
        end
        function loadDialog(app)
            [f,p]=uigetfile('*.json');if isequal(f,0),return;end
            try,app.loadScenario(fullfile(p,f));catch err,uialert(app.Figure,err.message,'Escenario no válido');end
        end
        function csvDialog(app)
            [f,p]=uiputfile('*.csv');if ~isequal(f,0),app.exportCsv(fullfile(p,f));end
        end
        function pngDialog(app,k)
            [f,p]=uiputfile('*.png');if isequal(f,0),return;end
            if k==0,exportapp(app.Figure,fullfile(p,f));else,exportgraphics(app.Axes(k),fullfile(p,f),'Resolution',160);end
        end
        function delete(app)
            app.stop();if ~isempty(app.Clock)&&isvalid(app.Clock),delete(app.Clock);end
            if ~isempty(app.Figure)&&isvalid(app.Figure),app.Figure.CloseRequestFcn=[];delete(app.Figure);end
        end
    end
    methods (Access=private)
        function beginRotation(app)
            app.stop();app.Dragging=true;point=app.Figure.CurrentPoint;
            app.DragStartX=point(1);app.DragStartAzimuth=app.State.camera;
        end
        function dragRotation(app)
            if ~app.Dragging,return;end
            point=app.Figure.CurrentPoint;
            az=mod(app.DragStartAzimuth+.4*(point(1)-app.DragStartX)+180,360)-180;
            app.State.camera=az;view(app.Axes(2),[az 22]);
            app.Controls.camera.Field.Value=az;app.Controls.camera.Slider.Value=az;
            drawnow limitrate;
        end
        function endRotation(app)
            app.Dragging=false;
        end
        function az=chartAzimuth(app,az)
            % Solo cambia la representación; modelo y exportación conservan gamma.
            if app.State.lat<0,az=mod(az,360);end
        end
        function addRange(app,parent,key,label,bounds,value)
            row=uigridlayout(parent,[2 2]);row.Padding=[0 0 0 0];row.RowHeight={24,22};row.ColumnWidth={'1x',85};
            uilabel(row,'Text',label);f=uieditfield(row,'numeric','Limits',bounds,'Value',value,'ValueChangedFcn',@(s,~)app.setParameter(key,s.Value));
            slider=uislider(row,'Limits',bounds,'Value',value,'MajorTicks',[],'MinorTicks',[],'ValueChangingFcn',@(~,e)app.setParameter(key,e.Value),'ValueChangedFcn',@(s,~)app.setParameter(key,s.Value));slider.Layout.Column=[1 2];
            if strcmp(key,'lat'),slider.ValueChangingFcn=@(~,e)app.previewLatitude(e.Value);end
            app.Controls.(key)=struct('Field',f,'Slider',slider);
        end
    end
    methods (Static)
        function location=resolveLocationZone(location)
            if isfield(location,'zone')&&isfield(location,'zoneResolved')&&location.zoneResolved
                try,check=datetime(2026,1,1,'TimeZone',location.zone);if ~isfield(location,'zoneNote'),location.zoneNote='Huso IANA detectado según la ubicación.';end;return;catch,end
            end
            try
                location.zone=geosolar.timeZoneAt(location.lat,location.lon);location.zoneResolved=true;
                location.zoneNote='Huso IANA detectado según la ubicación. Incluye horario de verano según la fecha.';
            catch
                if ~isfield(location,'zone'),location.zone='UTC';end
                location.zoneResolved=false;location.zoneNote=['No se pudo detectar el huso. Se usa ' location.zone '; puede editarlo manualmente.'];
                warning('geosolar:timeZoneLookup','%s',location.zoneNote);
            end
        end
        function validateLocation(location)
            validateattributes(location.lat,{'double'},{'scalar','real','finite','>=',-90,'<=',90});
            validateattributes(location.lon,{'double'},{'scalar','real','finite','>=',-180,'<=',180});
            assert(ischar(location.name)&&isrow(location.name)&&~isempty(strtrim(location.name)),'Nombre de ubicación inválido');
        end
        function s=defaults()
            s=struct('lat',40,'day',355,'time',12,'mode','date','delta',-23.45,'camera',-35,'speed',1.5,'animation','daily');
        end
        function validate(s)
            keys={'lat','day','time','delta','camera','speed'};lo=[-90 1 0 -23.45 -180 .5];hi=[90 365 24 23.45 180 10];
            for k=1:numel(keys),validateattributes(s.(keys{k}),{'double'},{'scalar','real','finite','>=',lo(k),'<=',hi(k)});end
            assert(any(strcmp(s.mode,{'date','manual'}))&&any(strcmp(s.animation,{'daily','annual'})),'Modo no válido');
        end
        function s=number(x)
            if isfinite(x),s=sprintf('%.2f',x);else,s='—';end
        end
    end
end
