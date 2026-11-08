classdef GeosolarOrbitLab < handle
    properties (SetAccess=private)
        Panel
        Side
        OrbitAxes
        CurveAxes
        TimeAxes
        Controls
        Metrics
        DataTable
        TimeDays=78
    end
    properties (Access=private)
        Owner
        Graphics
    end
    methods
        function app=GeosolarOrbitLab(sideHost,host,owner)
            app.Owner=owner;
            app.Side=uipanel(sideHost,'BorderType','none');app.Side.Layout.Row=1;app.Side.Layout.Column=1;
            side=uigridlayout(app.Side,[16 1]);side.Scrollable='on';side.RowHeight={32,30,38,30,30,30,150,32,32,32,32,32,32,70,80,'1x'};
            uilabel(side,'Text','01 · Órbita Tierra–Sol','FontSize',17,'FontWeight','bold');
            app.Controls.DayField=uieditfield(side,'numeric','Limits',[1 365],'Value',79,'ValueChangedFcn',@(s,~)app.selectDay(s.Value));
            app.Controls.Day=uislider(side,'Limits',[1 365],'Value',79,'MajorTicks',[1 91 182 274 365], ...
                'ValueChangingFcn',@(~,e)app.selectDay(e.Value),'ValueChangedFcn',@(s,~)app.selectDay(s.Value));
            uilabel(side,'Text','Velocidad anual (días/s)');
            app.Controls.Speed=uieditfield(side,'numeric','Limits',[5 60],'Value',15);
            app.Controls.Repeat=uicheckbox(side,'Text','Repetir al finalizar','Value',true);
            ev=geosolarorbit.events();events=uigridlayout(side,[3 2]);events.Padding=[0 0 0 0];
            for k=1:6,uibutton(events,'Text',ev.short{k},'ButtonPushedFcn',@(~,~)app.selectDay(ev.time(k)+1));end
            app.Controls.Camera=uidropdown(side,'Items',{'Vista oblicua','Vista superior'},'ValueChangedFcn',@(~,~)app.changeCamera());
            app.Controls.Play=uibutton(side,'Text','▶ Reproducir','ButtonPushedFcn',@(~,~)owner.toggle());
            uibutton(side,'Text','■ Restablecer','ButtonPushedFcn',@(~,~)app.reset());
            uibutton(side,'Text','Guardar escenario JSON','ButtonPushedFcn',@(~,~)app.fileDialog('save'));
            uibutton(side,'Text','Abrir escenario JSON','ButtonPushedFcn',@(~,~)app.fileDialog('load'));
            uibutton(side,'Text','Exportar CSV anual','ButtonPushedFcn',@(~,~)app.fileDialog('csv'));
            uilabel(side,'Text','Año didáctico de 365 días. Las fechas de los eventos proceden del modelo; no son efemérides reales de 2026.','WordWrap','on');
            uilabel(side,'Text','Predice: ¿está la Tierra más cerca del Sol en junio? ¿Por qué hay estaciones opuestas en ambos hemisferios?','WordWrap','on');
            app.Panel=uipanel(host,'BorderType','none');app.Panel.Layout.Row=1;app.Panel.Layout.Column=1;
            content=uigridlayout(app.Panel,[5 2]);content.Scrollable='on';content.ColumnWidth={'1.7x','1x'};content.RowHeight={90,270,320,110,240};
            frame=uipanel(content,'BorderType','line');frame.Layout.Column=[1 2];board=uigridlayout(frame,[1 7]);board.Padding=[4 4 4 4];
            app.Metrics=gobjects(1,7);
            for k=1:7
                cellFrame=uipanel(board,'BorderType','line');cellGrid=uigridlayout(cellFrame,[1 1]);cellGrid.Padding=[8 4 4 4];
                app.Metrics(k)=uilabel(cellGrid,'WordWrap','on','FontWeight','bold');
            end
            box=uigridlayout(content,[2 1]);box.Layout.Row=[2 3];box.Layout.Column=1;box.RowHeight={28,'1x'};
            uibutton(box,'Text','PNG · Órbita','ButtonPushedFcn',@(~,~)app.png(1));app.OrbitAxes=uiaxes(box);
            box=uigridlayout(content,[2 1]);box.Layout.Row=2;box.Layout.Column=2;box.RowHeight={28,'1x'};
            uibutton(box,'Text','PNG · Declinación','ButtonPushedFcn',@(~,~)app.png(2));app.CurveAxes=uiaxes(box);
            box=uigridlayout(content,[3 1]);box.Layout.Row=3;box.Layout.Column=2;box.RowHeight={28,'1x',65};
            uibutton(box,'Text','PNG · Ecuación del tiempo','ButtonPushedFcn',@(~,~)app.png(3));app.TimeAxes=uiaxes(box);
            uilabel(box,'Text',{'ET > 0: solar verdadero adelantado al solar medio.', 'ET < 0: retrasado. Frente al reloj civil también intervienen longitud, huso y horario de verano.'},'WordWrap','on');
            note=uilabel(content,'Text',{'TSV = TO − AO + ET/60 + (λlocal − λhuso)/15   ·   ω = 15°(TSV − 12)', ...
                'Longitudes positivas al Este. TO: hora civil; AO: adelanto de verano; ET: minutos.', ...
                'Órbita casi circular; cuerpos ampliados. Eje fijo, sin rotación diaria. ET NOAA independiente del modelo orbital.'},'WordWrap','on');note.Layout.Row=4;note.Layout.Column=[1 2];
            app.DataTable=uitable(content);app.DataTable.Layout.Row=5;app.DataTable.Layout.Column=[1 2];
            annual=geosolarorbit.state(0:364);
            app.DataTable.Data=table((1:365)',annual.declination',geosolarorbit.equationOfTime(0:364)',annual.distance',annual.speedRelative', ...
                'VariableNames',{'dia_2026','declinacion_grados','ET_min','distancia_UA','velocidad_relativa'});
            app.createScenes();app.refresh();
        end
        function selectDay(app,day)
            validateattributes(day,{'numeric'},{'scalar','real','finite','>=',1,'<=',365});
            app.Owner.stop();app.TimeDays=day-1;app.refresh();
        end
        function advance(app,elapsed)
            validateattributes(elapsed,{'numeric'},{'scalar','finite','nonnegative'});
            t=app.TimeDays+elapsed;
            if t>=364
                if app.Controls.Repeat.Value,t=mod(t,364);else,t=364;app.Owner.stop();end
            end
            app.TimeDays=t;app.refresh();
        end
        function reset(app)
            app.Owner.stop();app.TimeDays=78;app.Controls.Speed.Value=15;app.Controls.Repeat.Value=true;
            app.Controls.Camera.Value='Vista oblicua';app.changeCamera();app.refresh();
        end
        function s=scenario(app)
            camera='oblique';if strcmp(app.Controls.Camera.Value,'Vista superior'),camera='top';end
            repeat='no';if app.Controls.Repeat.Value,repeat='yes';end
            s=struct('day',app.TimeDays+1,'time',12,'speed',app.Controls.Speed.Value,'repeat',repeat,'camera',camera);
        end
        function saveScenario(app,file)
            s=struct('format','GEOSOLAR','version',1,'lab','orbit','model','matlab-compat-v1','parameters',app.scenario());
            fid=fopen(file,'w','n','UTF-8');assert(fid>=0,'No se puede abrir el archivo');c=onCleanup(@()fclose(fid));fprintf(fid,'%s',jsonencode(s,PrettyPrint=true));
        end
        function loadScenario(app,file)
            x=jsondecode(fileread(file));assert(strcmp(x.format,'GEOSOLAR')&&x.version==1&&strcmp(x.lab,'orbit')&&strcmp(x.model,'matlab-compat-v1'),'Escenario incompatible');p=x.parameters;
            validateattributes(p.day,{'double'},{'scalar','real','finite','>=',1,'<=',365});validateattributes(p.speed,{'double'},{'scalar','real','finite','>=',5,'<=',60});
            assert(any(strcmp(p.repeat,{'yes','no'}))&&any(strcmp(p.camera,{'oblique','top'})),'Opciones inválidas');
            app.Owner.stop();app.TimeDays=p.day-1;app.Controls.Speed.Value=p.speed;app.Controls.Repeat.Value=strcmp(p.repeat,'yes');
            if strcmp(p.camera,'top'),app.Controls.Camera.Value='Vista superior';else,app.Controls.Camera.Value='Vista oblicua';end
            app.changeCamera();app.refresh();
        end
        function exportCsv(app,file)
            fid=fopen(file,'w','n','UTF-8');assert(fid>=0,'No se puede abrir el archivo');
            fprintf(fid,'# GEOSOLAR; orbit; matlab-compat-v1\n# parameters: %s\n# Año didáctico 2026; ET NOAA independiente\n',jsonencode(app.scenario()));fclose(fid);
            writetable(app.DataTable.Data,file,'Delimiter',';','WriteMode','append','WriteVariableNames',true,'Encoding','UTF-8');
        end
        function refresh(app)
            p=geosolarorbit.state(app.TimeDays);c=p.position;[mesh,rgb]=geosolarorbit.earthMesh(p.axis,p.sunDirection);
            set(app.Graphics.Earth,'XData',c(1)+.07*squeeze(mesh(1,:,:)),'YData',c(2)+.07*squeeze(mesh(2,:,:)),'ZData',.07*squeeze(mesh(3,:,:)),'CData',rgb);
            set(app.Graphics.Axis,'XData',c(1)+[-.13 .13]*p.axis(1),'YData',c(2)+[-.13 .13]*p.axis(2),'ZData',[-.13 .13]*p.axis(3));
            set(app.Graphics.Point,'Position',c'+[.09 .02 .09]);set(app.Graphics.Ray,'XData',[0 c(1)],'YData',[0 c(2)],'ZData',[0 0]);
            set(app.Graphics.CurveMarker,'XData',app.TimeDays+1,'YData',p.declination);
            et=geosolarorbit.equationOfTime(app.TimeDays);set(app.Graphics.TimeMarker,'XData',app.TimeDays+1,'YData',et);
            app.Controls.Day.Value=app.TimeDays+1;app.Controls.DayField.Value=app.TimeDays+1;
            date=datetime(2026,1,1)+days(app.TimeDays);date.Format='dd/MM/yyyy';clock=date;clock.Format='HH:mm';
            values={sprintf('Fecha\n%s',string(date)),sprintf('Hora\n%s',string(clock)),'Año didáctico',sprintf('Declinación\n%+.2f°',p.declination), ...
                sprintf('Distancia\n%.4f UA',p.distance),sprintf('Velocidad\n%.4f ×',p.speedRelative),sprintf('ET\n%+.2f min',et)};
            for k=1:7,app.Metrics(k).Text=values{k};end
            drawnow limitrate nocallbacks;
        end
    end
    methods (Access=private)
        function changeCamera(app)
            if strcmp(app.Controls.Camera.Value,'Vista superior'),view(app.OrbitAxes,[0 90]);else,view(app.OrbitAxes,[0 32]);end
        end
        function fileDialog(app,action)
            if strcmp(action,'load'),[f,p]=uigetfile('*.json');elseif strcmp(action,'csv'),[f,p]=uiputfile('*.csv');else,[f,p]=uiputfile('*.json');end
            if isequal(f,0),return;end
            try
                switch action
                    case 'load',app.loadScenario(fullfile(p,f));
                    case 'save',app.saveScenario(fullfile(p,f));
                    case 'csv',app.exportCsv(fullfile(p,f));
                end
            catch err,uialert(app.Owner.Figure,err.message,'Archivo no válido');end
        end
        function png(app,k)
            [f,p]=uiputfile('*.png');if isequal(f,0),return;end
            axes=[app.OrbitAxes app.CurveAxes app.TimeAxes];exportgraphics(axes(k),fullfile(p,f),'Resolution',160);
        end
        function createScenes(app)
            ax=app.OrbitAxes; hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');
            xlim(ax,[-1.38 1.38]); ylim(ax,[-1.22 1.22]); zlim(ax,[-.20 .28]);
            title(ax,'Órbita e iluminación terrestre','FontSize',16);
            subtitle(ax,'Plano de la eclíptica · Sol en un foco · órbita de excentricidad real');
            path=geosolarorbit.state(linspace(2,367,500));
            plot3(ax,path.position(1,:),path.position(2,:),path.position(3,:),'-','Color',[.43 .49 .55],'LineWidth',1.3);
            patch(ax,path.position(1,:),path.position(2,:),path.position(3,:),...
                [.84 .89 .94],'FaceAlpha',.13,'EdgeColor','none');
            [x,y,z]=sphere(32);
            surf(ax,.10*x,.10*y,.10*z,'FaceColor',[1 .67 .12],'EdgeColor','none');
            text(ax,0,-.19,0,'Sol','HorizontalAlignment','center','FontSize',15);
            for t=[35 125 220 310]
                a=geosolarorbit.state(t); b=geosolarorbit.state(t+5); v=b.position-a.position;
                quiver3(ax,a.position(1),a.position(2),0,v(1),v(2),0,1.4,...
                    'Color',[.4 .45 .5],'MaxHeadSize',2,'LineWidth',1.1);
            end
            ev=geosolarorbit.events;
            cols=[.13 .50 .29;.85 .42 .04;.13 .50 .29;.09 .41 .71];
            for k=1:4
                p=geosolarorbit.state(ev.time(k)); c=p.position;
                plot3(ax,c(1),c(2),0,'o','MarkerSize',9,'Color',cols(k,:),'MarkerFaceColor','white');
                line(ax,c(1)+[-.11 .11]*p.axis(1),c(2)+[-.11 .11]*p.axis(2),...
                    [-.11 .11]*p.axis(3),'Color',cols(k,:),'LineWidth',1.3);
                label=1.24*c;
                eventDate=datetime(2026,1,1)+days(ev.time(k)); eventDate.Format='dd/MM';
                text(ax,label(1),label(2),.03,{ev.names{k},...
                    sprintf('≈ %s · δ = %+.2f°',string(eventDate),p.declination)},...
                    'HorizontalAlignment','center','FontSize',11,'Color',cols(k,:));
            end
            plot3(ax,[0 .9833],[0 0],[0 0],':','Color',[.65 .65 .65]);
            plot3(ax,[0 -1.0167],[0 0],[0 0],':','Color',[.65 .65 .65]);
            text(ax,.55,-.14,0,'Perihelio ≈ 0,983 UA','HorizontalAlignment','center','FontSize',10);
            text(ax,-.58,.15,0,'Afelio ≈ 1,017 UA','HorizontalAlignment','center','FontSize',10);
            app.Graphics.Ray=plot3(ax,[0 0],[0 0],[0 0],'--','Color',[.8 .5 .12]);
            app.Graphics.Earth=surf(ax,x*.07,y*.07,z*.07,'EdgeColor','none','FaceColor','texturemap');
            app.Graphics.Axis=plot3(ax,[0 0],[0 0],[0 0],'-','Color',[.12 .22 .3],'LineWidth',2);
            app.Graphics.Point=text(ax,0,0,0,'Tierra','FontSize',12,'Color',[.07 .2 .31]);
            app.changeCamera(); disableDefaultInteractivity(ax); toolbar=axtoolbar(ax,{});toolbar.Visible='off';
            ax=app.CurveAxes; hold(ax,'on');
            annualDays=0:364; annual=geosolarorbit.state(annualDays);
            plot(ax,annualDays+1,annual.declination,'ButtonDownFcn',@(~,e)app.selectDay(max(1,min(365,e.IntersectionPoint(1)))),'Color',[.19 .43 .65],'LineWidth',1.6);
            yline(ax,0,':'); xlim(ax,[1 365]); ylim(ax,[-27 27]);
            ax.XTick=[1 91 182 274 365]; ax.XTickLabel={'Ene','Abr','Jul','Oct','Dic'};
            ylabel(ax,'Declinación solar (°)'); grid(ax,'on');
            title(ax,'Declinación','FontSize',14);
            app.Graphics.CurveMarker=plot(ax,79,0,'o','Color',[.65 .1 .5],'MarkerFaceColor',[.65 .1 .5],'MarkerSize',7);
            disableDefaultInteractivity(ax); toolbar=axtoolbar(ax,{});toolbar.Visible='off';
            ax=app.TimeAxes; hold(ax,'on');
            plot(ax,annualDays+1,geosolarorbit.equationOfTime(annualDays),'ButtonDownFcn',@(~,e)app.selectDay(max(1,min(365,e.IntersectionPoint(1)))),'Color',[.55 .23 .65],'LineWidth',1.6);
            yline(ax,0,':'); xlim(ax,[1 365]); ylim(ax,[-18 18]);
            ax.XTick=[1 91 182 274 365]; ax.XTickLabel={'Ene','Abr','Jul','Oct','Dic'};
            ylabel(ax,'ET (minutos)'); grid(ax,'on');
            title(ax,'Ecuación del tiempo · aproximación NOAA','FontSize',14);
            app.Graphics.TimeMarker=plot(ax,79,0,'o','Color',[.65 .1 .5],...
                'MarkerFaceColor',[.65 .1 .5],'MarkerSize',7);
            disableDefaultInteractivity(ax); toolbar=axtoolbar(ax,{});toolbar.Visible='off';
        end

    end
end
