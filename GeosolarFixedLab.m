classdef GeosolarFixedLab < handle
    properties (SetAccess=protected)
        Kind
        Panel
        Side
        State
        Axes
        Metrics
        Controls
        DataTable
        Valid=false
        LastError=""
        Current
        Daily
    end
    properties (Access=protected)
        Owner
        CacheKey=""
        Status
        Exports
        HourMarker
    end
    methods
        function lab=GeosolarFixedLab(sideHost,host,owner,kind)
            if nargin<4,kind='fixed';end
            lab.Kind=kind;lab.Owner=owner;lab.State=lab.initialDefaults();s=lab.State;
            lab.Side=uipanel(sideHost,'BorderType','none','Visible','off');lab.Side.Layout.Row=1;lab.Side.Layout.Column=1;
            side=uigridlayout(lab.Side,[25 1]);side.Scrollable='on';side.RowHeight=[{32,54,32,32,32,32,32,32,32,32},repmat({54},1,10),{32,32,32,90,80}];
            heading='03 · Filas fijas y sombras';if strcmp(kind,'eo'),heading='04 · Conjuntos Este–Oeste';elseif strcmp(kind,'tracking'),heading='05 Seguimiento 1 eje';end
            uilabel(side,'Text',heading,'FontSize',16,'FontWeight','bold');
            lab.range(side,'time','Hora seleccionada (h)',[0 24]);
            lab.Controls.Play=uibutton(side,'Text','▶ Reproducir','ButtonPushedFcn',@(~,~)owner.toggle());
            uibutton(side,'Text','■ Restablecer','ButtonPushedFcn',@(~,~)lab.reset());
            lab.Controls.reference=uidropdown(side,'Items',{'Hora solar','Hora civil'},'ItemsData',{'solar','civil'},'Value',s.reference,'ValueChangedFcn',@(v,~)lab.setParameter('reference',v.Value));
            lab.Controls.zone=uieditfield(side,'text','Value',s.zone,'Tooltip','Huso IANA','ValueChangedFcn',@(v,~)lab.setParameter('zone',v.Value));
            lab.Controls.date=uidatepicker(side,'Value',datetime(s.date),'DisplayFormat','dd/MM/yyyy','ValueChangedFcn',@(v,~)lab.setParameter('date',char(string(v.Value,'yyyy-MM-dd'))));
            lab.Controls.DatePresets=geosolar.datePresets(side,@()lab.State.date,@(value)lab.setParameter('date',value));
            lab.Controls.location=uieditfield(side,'text','Value','Punto seleccionado','Tooltip','Nombre del emplazamiento','ValueChangedFcn',@(~,~)lab.publishLocation());
            uibutton(side,'Text','Seleccionar en mapa…','ButtonPushedFcn',@(~,~)lab.map());
            keys={'lat','lon','alpha','beta','L','W','n','h','camera','speed'};
            labels={'Latitud (° N)','Longitud (° E)','Desvío de orientación (°)','Inclinación (°)','Anchura inclinada (m)','Longitud de fila (m)','Número de filas','Altura inferior (m)','Giro de cámara (°)','Velocidad (h/s)'};
            bounds={[-90 90],[-180 180],[-90 90],[0 45],[.1 100],[.1 1000],[1 30],[0 20],[-180 180],[.5 10]};
            if strcmp(kind,'eo')
                labels{3}='Acimut (°)';labels{7}='Conjuntos de dos caras';bounds{4}=[0 90];
                keys{end+1}='d';labels{end+1}='Hueco inferior (m)';bounds{end+1}=[0 100];
                side.RowHeight=[{32,54,32,32,32,32,32,32,32,32},repmat({54},1,11),{32,32,32,90,80}];
            end
            if strcmp(kind,'tracking')
                keys={'lat','lon','L','W','n','h','limit','ns','eo','gcr','camera','speed'};
                labels={'Latitud (° N)','Longitud (° E)','Anchura de mesa (m)','Longitud de fila (m)','Número de filas','Altura del soporte (m)','Giro máximo ± (°)','Pendiente N–S','Pendiente E–O','GCR manual (%)','Giro de cámara (°)','Velocidad (h/s)'};
                bounds={[-90 90],[-180 180],[.1 100],[.1 1000],[1 30],[.01 30],[0 90],[-45 45],[-45 45],[.1 100],[-180 180],[.5 10]};
                lab.Controls.slopeUnits=uidropdown(side,'Items',{'Pendientes en grados','Pendientes en porcentaje'},'ItemsData',{'degrees','percent'},'ValueChangedFcn',@(v,~)lab.setParameter('slopeUnits',v.Value));
                lab.Controls.bt=uidropdown(side,'Items',{'Sin backtracking','Con backtracking'},'ItemsData',{'no','yes'},'ValueChangedFcn',@(v,~)lab.setParameter('bt',v.Value));
                lab.Controls.spacing=uidropdown(side,'Items',{'Diseño invernal · 3 horas','GCR manual'},'ItemsData',{'winter','manual'},'ValueChangedFcn',@(v,~)lab.setParameter('spacing',v.Value));
                side.RowHeight=[{32,54},repmat({32},1,11),repmat({54},1,12),{32,32,32,100,80}];
            end
            for k=1:numel(keys),lab.range(side,keys{k},labels{k},bounds{k});end
            if strcmp(kind,'fixed')
                lab.Controls.alpha.Field.Tooltip='0°: hacia el ecuador (Sur para latitud ≥0; Norte para latitud <0).';
            elseif strcmp(kind,'eo')
                lab.Controls.alpha.Field.Tooltip='Giro de la cumbrera respecto a N–S. Caras E/O identificadas antes del giro; sin inversión de hemisferio.';
            end
            lab.Exports=gobjects(1,2);
            lab.Exports(1)=uibutton(side,'Text','Guardar escenario JSON','ButtonPushedFcn',@(~,~)lab.fileDialog('save'));
            uibutton(side,'Text','Abrir escenario JSON','ButtonPushedFcn',@(~,~)lab.fileDialog('load'));
            lab.Exports(2)=uibutton(side,'Text','Exportar tabla CSV','ButtonPushedFcn',@(~,~)lab.fileDialog('csv'));
            lab.Status=uilabel(side,'Text','','WordWrap','on');
            uilabel(side,'Text','Predice: ¿cómo cambian las sombras y la incidencia al cambiar la inclinación, la orientación o la fecha?','WordWrap','on');
            lab.Panel=uipanel(host,'BorderType','none','Visible','off');lab.Panel.Layout.Row=1;lab.Panel.Layout.Column=1;
            content=uigridlayout(lab.Panel,[6 2]);content.Scrollable='on';content.RowHeight={90,430,300,80,250,130};
            frame=uipanel(content,'BorderType','line');frame.Layout.Column=[1 2];board=uigridlayout(frame,[1 7]);board.Padding=[4 4 4 4];
            lab.Metrics=gobjects(1,7);
            for k=1:7
                cellFrame=uipanel(board,'BorderType','line');cellGrid=uigridlayout(cellFrame,[1 1]);cellGrid.Padding=[8 4 4 4];
                lab.Metrics(k)=uilabel(cellGrid,'WordWrap','on','FontWeight','bold');
            end
            lab.Axes=gobjects(1,3);titles={'01 Instalación · vista 3D','02 Planta · Norte arriba','Evolución diaria · superficie sin Sol directo e incidencia'};
            for k=1:3
                box=uigridlayout(content,[2 1]);box.RowHeight={28,'1x'};
                if k<3,box.Layout.Row=2;box.Layout.Column=k;else,box.Layout.Row=3;box.Layout.Column=[1 2];end
                row=uigridlayout(box,[1 2]);row.ColumnWidth={'1x',60};row.Padding=[0 0 0 0];uilabel(row,'Text',titles{k},'FontWeight','bold');
                button=uibutton(row,'Text','PNG','ButtonPushedFcn',@(~,~)lab.png(k));lab.Exports(end+1)=button;
                lab.Axes(k)=uiaxes(box);toolbar=axtoolbar(lab.Axes(k),{});toolbar.Visible='off';
            end
            legend=uilabel(content,'Text',{'Rojo: sombra frontal · azul oscuro: posterior/rasante · gris: noche y sombras sobre terreno.', ...
                'θ con la normal: 0° perpendicular, 90° rasante, >90° posterior. η con el plano: 90° perpendicular, negativo posterior. θ + η = 90°.'},'WordWrap','on');legend.Layout.Row=4;legend.Layout.Column=[1 2];
            lab.DataTable=uitable(content);lab.DataTable.Layout.Row=5;lab.DataTable.Layout.Column=[1 2];
            if strcmp(kind,'eo')
                explanations={'Dos caras por conjunto · cumbrera abierta 0,05 m · hueco inferior manual.', ...
                    'b = L cos β · anchura = 2b + 0,05 · paso P = anchura + d · LCR = 2b/P', ...
                    'Giro respecto a N–S; caras E/O identificadas antes del giro, también en hemisferio sur.', ...
                    'Modelo geométrico, sin pérdidas eléctricas ni irradiación. Hora civil incluye longitud, ET y huso IANA.'};
            else
                explanations={'b = L cos β · H = L sin β · d = H·K · P = b + d · LCR = b/P', ...
                    'Diseño invernal: 10:30–13:30 solares (1801 muestras), independiente de la fecha.', ...
                    'Frente hacia el ecuador: Sur en HN y Norte en HS; el desvío se aplica a esa base.', ...
                    'Terreno horizontal; sin pérdidas eléctricas ni energía. Hora civil incluye longitud, ET y huso IANA.'};
            end
            if strcmp(kind,'tracking'),explanations={'Eje N–S que sigue la pendiente. Giro Este negativo/Oeste positivo.', 'Paso horizontal: P = L/GCR. Diseño invernal o GCR manual; BT no cambia el paso.', 'θ con normal y η con plano: θ + η = 90°. Noche y ocultación por terreno en gris.', 'PVGIS: irradiación frontal, no producción FV. Difusa isotrópica y albedo 0,20; sin bifacialidad ni pérdidas eléctricas.'};end
            note=uilabel(content,'Text',explanations,'WordWrap','on');note.Layout.Row=6;note.Layout.Column=[1 2];
            if strcmp(kind,'tracking')
                content.RowHeight={90,430,300,320,80,250,95,300,240,120};
                legend.Layout.Row=5;lab.DataTable.Layout.Row=6;note.Layout.Row=10;
            end
            lab.extraViews(content);
            lab.rebuild();
        end
        function setParameter(lab,key,value)
            lab.Owner.stop();s=lab.State;
            try
                if strcmp(key,'reference')&&~strcmp(value,s.reference)
                    solar=lab.toSolar(s,s.time);
                    if strcmp(value,'civil'),s.time=mod(geosolarfixed.pv_hora_solar(datetime(s.date),s.lon,solar,'solarToCivil',s.zone),24);else,s.time=mod(solar,24);end
                end
                s.(key)=value;if strcmp(key,'n'),s.n=round(s.n);end
                lab.validateState(s);lab.State=s;
                if strcmp(key,'zone'),lab.Controls.zone.FontColor=[.15 .2 .2];lab.Controls.zone.Tooltip='Huso IANA establecido manualmente.';end
                if ismember(key,{'lat','lon'}),lab.Controls.location.Value='Punto personalizado';lab.publishLocation();return;end
                if ismember(key,{'time','camera','speed'}),lab.sync();if lab.Valid,lab.render();end;else,lab.rebuild();end
            catch err,lab.fail(err);end
        end
        function reset(lab)
            lab.Owner.stop();lab.State=lab.initialDefaults();location=lab.Owner.Location;lab.State.lat=location.lat;lab.State.lon=location.lon;
            if isfield(location,'zone'),lab.State.zone=location.zone;end
            lab.Controls.location.Value=location.name;lab.CacheKey="";lab.rebuild();
        end
        function advance(lab,seconds)
            if ~lab.Valid,lab.Owner.stop();return;end
            lab.State.time=mod(lab.State.time+seconds*lab.State.speed,24);lab.sync();lab.render();
        end
        function rebuild(lab)
            try
                s=lab.State;lab.sync();key=string(jsonencode(rmfield(s,{'time','camera','speed'})));
                if lab.CacheKey~=key||~lab.Valid
                    lab.Status.Text='Calculando evolución diaria…';drawnow;
                    ts=linspace(0,24,97)';lab.Daily=lab.calculate(s,lab.toSolar(s,ts));
                    m=lab.Daily;faces=size(m.fraccion,2);names=cellstr(compose('sin_sol_directo_%d_porcentaje',1:faces));
                    angleNames={'angulo_normal_grados','angulo_plano_grados'};
                    if strcmp(lab.Kind,'eo'),angleNames={'angulo_normal_1_grados','angulo_normal_2_grados','angulo_plano_1_grados','angulo_plano_2_grados'};end
                    timeName='hora_solar_h';if strcmp(s.reference,'civil'),timeName='hora_civil_h';end
                    lab.DataTable.Data=array2table([ts,100*m.fraccion,90-m.incidencia,m.incidencia], ...
                        'VariableNames',[{timeName},names,angleNames]);
                    lab.drawDaily(ts);lab.CacheKey=key;
                end
                lab.Valid=true;lab.LastError="";set(lab.Exports(isgraphics(lab.Exports)),'Enable','on');lab.render();
            catch err,lab.fail(err);end
        end
        function sync(lab)
            s=lab.State;keys={'time','lat','lon','alpha','beta','L','W','n','h','camera','speed'};if strcmp(lab.Kind,'eo'),keys{end+1}='d';end
            for k=1:numel(keys),c=lab.Controls.(keys{k});c.Field.Value=s.(keys{k});c.Slider.Value=s.(keys{k});end
            lab.Controls.date.Value=datetime(s.date);lab.Controls.reference.Value=s.reference;lab.Controls.zone.Value=s.zone;
        end
        function render(lab)
            s=lab.State;m=lab.calculate(s,lab.toSolar(s,s.time));lab.Current=m;
            date=datetime(s.date);date.Format='dd/MM/yyyy';reference='Hora solar';if strcmp(s.reference,'civil'),reference=['Hora civil · ' s.zone];end
            values={sprintf('Fecha\n%s',string(date)),sprintf('Hora\n%02d:%02d',floor(s.time),floor(mod(s.time,1)*60)),reference, ...
                sprintf('Hueco\n%.3f m',m.d),sprintf('Paso\n%.3f m',m.P),sprintf('LCR\n%.1f %%',100*m.LCR),sprintf('Altura solar\n%.2f°',m.alt)};
            for k=1:7,lab.Metrics(k).Text=values{k};end
            lab.scene(m);
            yyaxis(lab.Axes(3),'left');delete(findall(lab.Axes(3),'Tag','selectedHour'));xline(lab.Axes(3),s.time,'r--','Tag','selectedHour','HandleVisibility','off');
            if strcmp(lab.Kind,'eo')
                lab.Status.Text=sprintf('Cara E: θ %s° · η %s°\nCara O: θ %s° · η %s°\nCumbrera abierta: 0,05 m',lab.Owner.number(90-m.incidencia(1)),lab.Owner.number(m.incidencia(1)),lab.Owner.number(90-m.incidencia(2)),lab.Owner.number(m.incidencia(2)));
            else
                base='Sur';if s.lat<0,base='Norte';end
                lab.Status.Text=sprintf('Base: %s · desvío: %+.1f°\nθ normal: %s° · η plano: %s°',base,s.alpha,lab.Owner.number(90-m.incidencia),lab.Owner.number(m.incidencia));
            end
            drawnow limitrate nocallbacks;
        end
        function drawDaily(lab,t)
            ax=lab.Axes(3);cla(ax);yyaxis(ax,'left');curves=plot(ax,t,100*lab.Daily.fraccion,'LineWidth',1.2);
            colors=lines(lab.State.n);names=cell(1,numel(curves));
            for k=1:numel(curves)
                index=k;style='-';names{k}=sprintf('Fila %d',k);
                if strcmp(lab.Kind,'eo')
                    index=ceil(k/2);face='E';if mod(k,2)==0,face='O';style='--';end
                    names{k}=sprintf('%d %s',index,face);
                end
                curves(k).Color=colors(index,:);curves(k).LineStyle=style;curves(k).Marker='none';
            end
            ylim(ax,[0 100]);ylabel(ax,'Cara sin Sol directo (%)');
            yyaxis(ax,'right');angles=plot(ax,t,[90-lab.Daily.incidencia,lab.Daily.incidencia],'LineWidth',1.5);
            count=size(lab.Daily.incidencia,2);angleNames=cell(1,2*count);
            for k=1:2*count
                plane=k>count;face='';if count==2,faces={' E',' O'};face=faces{mod(k-1,count)+1};end
                if plane,angles(k).Color=[.15 .25 .41];angles(k).LineStyle='-';angleNames{k}=['Plano η' face];
                else,angles(k).Color=[.69 .36 .14];angles(k).LineStyle='--';angleNames{k}=['Normal θ' face];end
                if count==2&&mod(k,2)==0,angles(k).Color=angles(k).Color*.65+.2;end
            end
            ylim(ax,[-90 180]);ylabel(ax,'Ángulos (°)');ax.YAxis(1).Color=[.25 .25 .25];ax.YAxis(2).Color=[.35 .25 .4];
            reference='Hora solar';if strcmp(lab.State.reference,'civil'),reference='Hora civil';end
            xlim(ax,[0 24]);xticks(ax,0:3:24);xlabel(ax,reference);grid(ax,'on');
            legend(ax,[names angleNames],'Location','northoutside','NumColumns',min(6,numel(names)+numel(angleNames)));
            curves=findobj(ax,'Type','line');set(curves,'ButtonDownFcn',@(~,e)lab.setParameter('time',max(0,min(24,e.IntersectionPoint(1)))));
        end
        function scene(lab,m)
            s=lab.State;width=m.b;if strcmp(lab.Kind,'eo'),width=m.width;end
            extent=(s.n-1)*m.P+width;margin=max(3,s.L);
            rect=polyshape([-margin extent+margin extent+margin -margin],[-s.W/2-margin -s.W/2-margin s.W/2+margin s.W/2+margin]);
            [gx,gy]=boundary(rect);[ge,gn]=lab.world(gx,gy);
            boundsE=ge;boundsN=gn;
            for ax=lab.Axes(1:2),cla(ax);hold(ax,'on');end
            patch(lab.Axes(1),ge,gn,zeros(size(ge)),[.92 .91 .84],'EdgeColor','none');patch(lab.Axes(2),ge,gn,[.92 .91 .84],'EdgeColor','none');
            for j=1:numel(m.vertices)
                if m.alt>0
                    ground=intersect(m.suelo{1,j},rect);[x,y]=boundary(ground);[e,n]=lab.world(x,y);
                    patch(lab.Axes(1),e,n,.001+zeros(size(e)),[.3 .3 .3],'FaceAlpha',.25,'EdgeColor','none');patch(lab.Axes(2),e,n,[.3 .3 .3],'FaceAlpha',.25,'EdgeColor','none');
                end
            end
            for j=1:numel(m.vertices)
                v=m.vertices{j};[e,n]=lab.world(v(:,1),v(:,2));color=[.2 .55 .85];if m.alt<=0,color=[.55 .57 .58];elseif m.posterior(1,1+strcmp(lab.Kind,'eo')*mod(j-1,2)),color=[.06 .16 .34];end
                edgeWidth=.5;if strcmp(lab.Kind,'eo'),edgeWidth=.3;end
                patch(lab.Axes(1),e,n,v(:,3),color,'LineWidth',edgeWidth,'Tag','fixedTable');patch(lab.Axes(2),e,n,color,'LineWidth',edgeWidth,'Tag','fixedTable');
                if m.alt>0&&~m.posterior(1,1+strcmp(lab.Kind,'eo')*mod(j-1,2))&&~isempty(m.sombras{1,j}.Vertices)
                    [u,y]=boundary(m.sombras{1,j});
                    if strcmp(lab.Kind,'eo'),local=m.origins(j,:)+u*m.tangents(j,:)+[zeros(size(y)) y zeros(size(y))];[e,n]=lab.world(local(:,1),local(:,2));z=local(:,3);
                    else,[e,n]=lab.world((j-1)*m.P+u*cosd(s.beta),y);z=s.h+u*sind(s.beta);end
                    patch(lab.Axes(1),e,n,z+.002,[.85 .15 .1],'EdgeColor','none');patch(lab.Axes(2),e,n,[.85 .15 .1],'EdgeColor','none');
                end
                [e,n]=lab.world(mean(v(:,1)),0);label=sprintf('%d',j);if strcmp(lab.Kind,'eo'),faces={'E','O'};label=sprintf('%d %s',ceil(j/2),faces{1+mod(j-1,2)});end
                text(lab.Axes(2),e,n,label,'HorizontalAlignment','center');
            end
            if m.alt>0
                [e,n]=lab.world(extent/2,0);[se,sn]=lab.world(m.sun(1),m.sun(2));len=max(3*s.L,min(s.W,6));z=s.h+m.H;
                quiver3(lab.Axes(1),e,n,z,se*len,sn*len,m.sun(3)*len,0,'Color',[1 .7 0],'LineWidth',2.5);
                plot3(lab.Axes(1),e+se*len,n+sn*len,z+m.sun(3)*len,'o','MarkerFaceColor',[1 .8 0],'MarkerEdgeColor',[1 .65 0],'MarkerSize',12);
                boundsE=[boundsE(:);e+se*len];boundsN=[boundsN(:);n+sn*len];
            end
            % Flecha independiente del Sol: dirección del frente de las mesas.
            [frontE,frontN]=lab.world(-1,0);[centerE,centerN]=lab.world(extent/2,s.W/2+margin*.5);
            lengthFront=margin*.65;purple=[.45 .15 .6];
            if strcmp(lab.Kind,'eo')
                frontLabel='Cara E';
            elseif abs(s.alpha)<1e-10
                frontLabel='Frente: Sur';if s.lat<0,frontLabel='Frente: Norte';end
            else
                gamma=mod(m.frontAzimuth+180,360)-180;frontLabel=sprintf('Frente: acimut %+.0f°',gamma);
            end
            quiver3(lab.Axes(1),centerE,centerN,.15,frontE*lengthFront,frontN*lengthFront,0,0,'Color',purple,'LineWidth',2,'MaxHeadSize',.7,'Tag','frontDirection');
            text(lab.Axes(1),centerE,centerN,.6,frontLabel,'Color',purple,'FontWeight','bold','HorizontalAlignment','center');
            quiver(lab.Axes(2),centerE,centerN,frontE*lengthFront,frontN*lengthFront,0,'Color',purple,'LineWidth',2,'MaxHeadSize',.7,'Tag','frontDirection');
            labelRotation=90;if strcmp(lab.Kind,'eo'),labelRotation=0;end
            text(lab.Axes(2),centerE,centerN,frontLabel,'Color',purple,'FontWeight','bold','Rotation',labelRotation,'VerticalAlignment','bottom','HorizontalAlignment','center');
            if strcmp(lab.Kind,'eo')
                [oe,on]=lab.world(extent/2,-s.W/2-margin*.5);
                quiver3(lab.Axes(1),oe,on,.15,-frontE*lengthFront,-frontN*lengthFront,0,0,'Color',purple,'LineWidth',2,'MaxHeadSize',.7);
                text(lab.Axes(1),oe,on,.6,'Cara O','Color',purple,'FontWeight','bold');
                quiver(lab.Axes(2),oe,on,-frontE*lengthFront,-frontN*lengthFront,0,'Color',purple,'LineWidth',2,'MaxHeadSize',.7);
                text(lab.Axes(2),oe,on,'Cara O','Color',purple,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','bottom');
            end
            % Rosa en coordenadas geográficas (no en coordenadas locales de filas).
            compassE=min(ge)+margin*.6;compassN=max(gn)-margin*.6;r=margin*.32;
            directions=[0 1;1 0;0 -1;-1 0];labels={'N','E','S','O'};
            for k=1:4
                de=directions(k,1)*r;dn=directions(k,2)*r;
                quiver3(lab.Axes(1),compassE,compassN,.05,de,dn,0,0,'Color',[.2 .25 .23],'LineWidth',1.2,'MaxHeadSize',.6);
                text(lab.Axes(1),compassE+1.3*de,compassN+1.3*dn,.08,labels{k},'FontWeight','bold','HorizontalAlignment','center');
                quiver(lab.Axes(2),compassE,compassN,de,dn,0,'Color',[.2 .25 .23],'LineWidth',1.2,'MaxHeadSize',.6);
                text(lab.Axes(2),compassE+1.3*de,compassN+1.3*dn,labels{k},'FontWeight','bold','HorizontalAlignment','center');
            end
            for ax=lab.Axes(1:2)
                daspect(ax,[1 1 1]);grid(ax,'on');xlabel(ax,'');ylabel(ax,'');
                subtitle(ax,'Distancias en metros');hold(ax,'off');ax.Toolbar.Visible='off';
            end
            camera=s.camera;if strcmp(lab.Kind,'fixed')&&s.lat<0,camera=camera+180;end
            view(lab.Axes(1),[camera 25]);zlabel(lab.Axes(1),'Altura (m)');
            % Límites explícitos: el dibujo inicial se construye con el panel oculto.
            % No heredar límites que axis equal haya calculado antes del layout final.
            xlim(lab.Axes(1),[min(boundsE) max(boundsE)]);ylim(lab.Axes(1),[min(boundsN) max(boundsN)]);
            zlim(lab.Axes(1),[0 max(1,s.h+m.H+max(3*s.L,min(s.W,6)))]);view(lab.Axes(2),2);
            grid(lab.Axes(1),'off');box(lab.Axes(1),'off');axis(lab.Axes(1),'off');
            lab.Axes(2).CameraUpVector=[0 1 0];
            % Norte arriba en coordenadas geográficas; el acimut rota las filas.
            xlim(lab.Axes(2),[min(ge) max(ge)]);ylim(lab.Axes(2),[min(gn) max(gn)]);
        end
        function [e,n]=world(lab,x,y)
            alpha=geosolarfixed.frontAzimuth(lab.State);if strcmp(lab.Kind,'eo'),alpha=lab.State.alpha-90;end
            e=x*sind(alpha)-y*cosd(alpha);n=x*cosd(alpha)+y*sind(alpha);
        end
        function map(lab)
            lab.Owner.stop();[lat,lon,ok,name]=geosolarfixed.seleccionar_ubicacion(lab.State.lat,lab.State.lon,Nombre=string(lab.Controls.location.Value),LatitudeLimits=[-90 90]);
            if ok,lab.Owner.setLocation(lat,lon,name);end
        end
        function saveScenario(lab,file)
            assert(lab.Valid,'Configuración no válida');x=struct('format','GEOSOLAR','version',1,'lab',lab.Kind,'model','matlab-compat-v1','parameters',lab.State);
            fid=fopen(file,'w','n','UTF-8');assert(fid>=0);c=onCleanup(@()fclose(fid));fprintf(fid,'%s',jsonencode(x,PrettyPrint=true));
        end
        function loadScenario(lab,file)
            x=jsondecode(fileread(file));assert(strcmp(x.format,'GEOSOLAR')&&x.version==1&&strcmp(x.lab,lab.Kind)&&strcmp(x.model,'matlab-compat-v1'),'Escenario incompatible');
            lab.validateState(x.parameters);s=x.parameters;lab.calculate(s,lab.toSolar(s,s.time));
            lab.Owner.stop();lab.State=s;lab.Owner.setLocation(s.lat,s.lon,lab.Controls.location.Value);
        end
        function exportCsv(lab,file)
            assert(lab.Valid,'Configuración no válida');fid=fopen(file,'w','n','UTF-8');assert(fid>=0);
            fprintf(fid,'# GEOSOLAR; %s; matlab-compat-v1\n# parameters: %s\n# Campos vacíos: noche o resultado indeterminado\n',lab.Kind,jsonencode(lab.State));fclose(fid);
            writetable(lab.DataTable.Data,file,'Delimiter',';','Encoding','UTF-8','WriteMode','append','WriteVariableNames',true);
        end
        function fileDialog(lab,action)
            if strcmp(action,'load'),[f,p]=uigetfile('*.json');elseif strcmp(action,'csv'),[f,p]=uiputfile('*.csv');else,[f,p]=uiputfile('*.json');end
            if isequal(f,0),return;end
            try
                switch action
                    case 'save',lab.saveScenario(fullfile(p,f));
                    case 'load',lab.loadScenario(fullfile(p,f));
                    case 'csv',lab.exportCsv(fullfile(p,f));
                end
            catch err,uialert(lab.Owner.Figure,err.message,'Archivo no válido');end
        end
        function png(lab,k)
            if ~lab.Valid,return;end
            [f,p]=uiputfile('*.png');if ~isequal(f,0),exportgraphics(lab.Axes(k),fullfile(p,f),'Resolution',160);end
        end
        function fail(lab,err)
            lab.Owner.stop();lab.Valid=false;lab.LastError=string(err.message);lab.Status.Text=err.message;
            for ax=lab.Axes,delete(findall(ax,'Tag','selectedHour'));cla(ax);end
            for k=1:7,lab.Metrics(k).Text='—';end
            lab.DataTable.Data=table();set(lab.Exports(isgraphics(lab.Exports)),'Enable','off');
        end
        function extraViews(~,~)
        end
        function adoptLocation(lab,location)
            changed=lab.State.lat~=location.lat||lab.State.lon~=location.lon;
            lab.State.lat=location.lat;lab.State.lon=location.lon;lab.Controls.location.Value=location.name;
            if isfield(location,'zone')
                lab.State.zone=location.zone;
                lab.Controls.zone.Tooltip=location.zoneNote;
                if location.zoneResolved,lab.Controls.zone.FontColor=[.15 .2 .2];else,lab.Controls.zone.FontColor=[.75 .15 .15];end
            end
            lab.CacheKey="";
            if changed
                lab.Valid=false;lab.DataTable.Data=table();
                set(lab.Exports(isgraphics(lab.Exports)),'Enable','off');
            end
            % Recalcular solo al entrar; el estado oculto queda actualizado.
            lab.sync();
        end
        function publishLocation(lab)
            lab.Owner.setLocation(lab.State.lat,lab.State.lon,lab.Controls.location.Value);
        end
        function m=calculate(lab,s,t)
            if strcmp(lab.Kind,'eo'),m=geosolarfixed.pv_este_oeste_modelo(s,datetime(s.date),t);
            else,m=geosolarfixed.pv_filas_modelo(s,datetime(s.date),t);end
        end
        function s=initialDefaults(lab)
            s=GeosolarFixedLab.defaults();
            if strcmp(lab.Kind,'eo'),s.beta=15;s.n=4;s.d=.5;end
        end
        function validateState(lab,s)
            copy=s;copy.beta=min(copy.beta,45);GeosolarFixedLab.validate(copy);
            maxBeta=45;if strcmp(lab.Kind,'eo'),maxBeta=90;validateattributes(s.d,{'double'},{'scalar','real','finite','>=',0,'<=',100});end
            validateattributes(s.beta,{'double'},{'scalar','real','finite','>=',0,'<=',maxBeta});
        end
    end
    methods (Access=private)
        function range(lab,parent,key,label,bounds)
            row=uigridlayout(parent,[2 2]);row.Padding=[0 0 0 0];row.RowHeight={24,22};row.ColumnWidth={'1x',80};
            uilabel(row,'Text',label);f=uieditfield(row,'numeric','Limits',bounds,'Value',lab.State.(key),'ValueChangedFcn',@(v,~)lab.setParameter(key,v.Value));
            slider=uislider(row,'Limits',bounds,'Value',lab.State.(key),'MajorTicks',[],'MinorTicks',[], ...
                'ValueChangedFcn',@(v,~)lab.setParameter(key,v.Value));slider.Layout.Column=[1 2];
            if ismember(key,{'time','camera'}),slider.ValueChangingFcn=@(~,e)lab.setParameter(key,e.Value);end
            lab.Controls.(key)=struct('Field',f,'Slider',slider);
        end
    end
    methods (Static)
        function s=defaults()
            s=struct('lat',40,'lon',-5,'date','2026-12-21','time',12,'reference','solar','zone','Europe/Madrid','alpha',0,'beta',30,'L',2,'W',10,'n',5,'h',.3,'camera',-30,'speed',1.5);
        end
        function validate(s)
            keys={'lat','lon','time','alpha','beta','L','W','n','h','camera','speed'};lo=[-90 -180 0 -90 0 .1 .1 1 0 -180 .5];hi=[90 180 24 90 45 100 1000 30 20 180 10];
            for k=1:numel(keys),validateattributes(s.(keys{k}),{'double'},{'scalar','real','finite','>=',lo(k),'<=',hi(k)});end
            assert(s.n==round(s.n)&&any(strcmp(s.reference,{'solar','civil'})),'Parámetros inválidos');
            date=datetime(s.date,'InputFormat','yyyy-MM-dd');assert(isscalar(date)&&~isnat(date),'Fecha inválida');date.TimeZone=s.zone;
        end
        function solar=toSolar(s,time)
            solar=time;if strcmp(s.reference,'civil'),solar=geosolarfixed.pv_hora_solar(datetime(s.date),s.lon,time,'civilToSolar',s.zone);end
        end
    end
end
