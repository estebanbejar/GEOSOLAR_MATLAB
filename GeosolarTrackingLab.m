classdef GeosolarTrackingLab < GeosolarFixedLab
    properties (SetAccess=private)
        Design
        FreeHours
        MonthlyAxes
        MonthlyData
        AnnualAxes
        AnnualTable
        AnnualResult=[]
        AnnualStatus
        AnnualButton
        AnnualExport
        Busy=false
        TMYData=[]
    end
    properties (Access=private)
        DerivedKey=""
        AnnualKey=""
        RejectedTmyLocation=""
        RejectedTmyMessage=""
        TMYContextKey=""
    end
    methods
        function lab=GeosolarTrackingLab(sideHost,host,owner)
            lab@GeosolarFixedLab(sideHost,host,owner,'tracking');
        end
        function s=initialDefaults(~)
            s=struct('lat',40,'lon',-5,'date','2026-12-21','time',12,'reference','solar','zone','Europe/Madrid', ...
                'L',2,'W',10,'n',5,'h',1.5,'ns',0,'eo',0,'slopeUnits','degrees','limit',60,'bt','no','spacing','manual','gcr',50,'camera',-30,'speed',1.5);
        end
        function p=physical(lab,s)
            if nargin<2,s=lab.State;end
            p=s;if strcmp(s.slopeUnits,'percent'),p.ns=atand(s.ns/100);p.eo=atand(s.eo/100);end
        end
        function validateState(lab,s)
            keys={'lat','lon','time','L','W','n','h','ns','eo','limit','gcr','camera','speed'};
            lo=[-90 -180 0 .1 .1 1 .01 -100 -100 0 .1 -180 .5];hi=[90 180 24 100 1000 30 30 100 100 90 100 180 10];
            for k=1:numel(keys),validateattributes(s.(keys{k}),{'double'},{'scalar','real','finite','>=',lo(k),'<=',hi(k)});end
            assert(s.n==round(s.n),'Número de filas entero requerido');
            assert(any(strcmp(s.slopeUnits,{'degrees','percent'}))&&any(strcmp(s.bt,{'yes','no'}))&&any(strcmp(s.spacing,{'winter','manual'}))&&any(strcmp(s.reference,{'solar','civil'})),'Modo no válido');
            p=lab.physical(s);assert(abs(p.ns)<=45&&abs(p.eo)<=45,'Pendientes fuera de rango');
            date=datetime(s.date,'InputFormat','yyyy-MM-dd');assert(~isnat(date)&&isscalar(date));date.TimeZone=s.zone;
        end
        function setParameter(lab,key,value)
            if lab.Busy,lab.sync();return;end
            if strcmp(key,'slopeUnits')&&~strcmp(value,lab.State.slopeUnits)
                slopes=[lab.State.ns lab.State.eo];
                if strcmp(value,'percent'),slopes=100*tand(slopes);else,slopes=atand(slopes/100);end
                lab.State.ns=slopes(1);lab.State.eo=slopes(2);
            end
            if strcmp(key,'gcr'),lab.State.spacing='manual';end
            setParameter@GeosolarFixedLab(lab,key,value);
        end
        function sync(lab)
            s=lab.State;
            keys={'time','lat','lon','L','W','n','h','limit','ns','eo','gcr','camera','speed'};
            for k=1:numel(keys)
                c=lab.Controls.(keys{k});
                if ismember(keys{k},{'ns','eo'}),c.Field.Limits=[-Inf Inf];c.Slider.Limits=[-100 100];end
                c.Field.Value=s.(keys{k});c.Slider.Value=s.(keys{k});
                if ismember(keys{k},{'ns','eo'})
                    bound=45;if strcmp(s.slopeUnits,'percent'),bound=100;end
                    c.Field.Limits=[-bound bound];c.Slider.Limits=[-bound bound];
                end
            end
            lab.Controls.reference.Value=s.reference;lab.Controls.zone.Value=s.zone;lab.Controls.date.Value=datetime(s.date);
            lab.Controls.slopeUnits.Value=s.slopeUnits;lab.Controls.bt.Value=s.bt;lab.Controls.spacing.Value=s.spacing;
            manual=strcmp(s.spacing,'manual');lab.Controls.gcr.Field.Enable=manual;lab.Controls.gcr.Slider.Enable=manual;
        end
        function extraViews(lab,content)
            lab.MonthlyAxes=gobjects(1,2);
            for k=1:2
                box=uigridlayout(content,[2 1]);box.Layout.Row=4;box.Layout.Column=k;box.RowHeight={28,'1x'};
                row=uigridlayout(box,[1 2]);row.ColumnWidth={'1x',55};row.Padding=[0 0 0 0];
                label='Giro mensual · sin BT';if k==2,label='Giro mensual · con BT';end
                uilabel(row,'Text',label,'FontWeight','bold');uibutton(row,'Text','PNG','ButtonPushedFcn',@(~,~)lab.exportPlotDialog(k+3));
                lab.MonthlyAxes(k)=uiaxes(box);toolbar=axtoolbar(lab.MonthlyAxes(k),{});toolbar.Visible='off';
            end
            actions=uigridlayout(content,[2 3]);actions.Layout.Row=7;actions.Layout.Column=[1 2];actions.RowHeight={32,'1x'};
            lab.AnnualButton=uibutton(actions,'Text','Calcular TMY PVGIS','ButtonPushedFcn',@(~,~)lab.annualDialog());
            lab.AnnualExport=uibutton(actions,'Text','CSV anual (tabuladores)','Enable','off','ButtonPushedFcn',@(~,~)lab.exportAnnualDialog());
            uibutton(actions,'Text','CSV comparación mensual','ButtonPushedFcn',@(~,~)lab.exportMonthlyDialog());
            lab.AnnualStatus=uilabel(actions,'Text','Irradiación anual frente a 1/GCR. Descarga o caché del TMY; pulse Calcular.','WordWrap','on');lab.AnnualStatus.Layout.Column=[1 3];
            box=uigridlayout(content,[2 1]);box.Layout.Row=8;box.Layout.Column=[1 2];box.RowHeight={28,'1x'};
            uibutton(box,'Text','PNG · Irradiación anual PVGIS','ButtonPushedFcn',@(~,~)lab.exportPlotDialog(6));lab.AnnualAxes=uiaxes(box);
            toolbar=axtoolbar(lab.AnnualAxes,{});toolbar.Visible='off';
            lab.AnnualTable=uitable(content);lab.AnnualTable.Layout.Row=9;lab.AnnualTable.Layout.Column=[1 2];
        end
        function m=calculate(lab,s,t)
            p=lab.physical(s);key=string(jsonencode(rmfield(s,{'time','camera','speed'})));
            if isempty(lab.Design)||lab.DerivedKey~=key
                if strcmp(s.spacing,'manual'),design=geosolartracking.pv_seguidor_diseno(p,s.gcr/100);else,design=geosolartracking.pv_seguidor_diseno(p);end
                lab.Design=design;lab.DerivedKey=key;
                lab.FreeHours=geosolartracking.pv_seguidor_horas_libres(p,datetime(s.date),design.P,strcmp(s.bt,'yes'));
                lab.monthly(p,design.P);
            end
            solar=geosolartracking.pv_seguidor_solar(p.lat,datetime(s.date),t);
            track=geosolartracking.pv_seguidor_estado(p,solar,lab.Design.P,strcmp(s.bt,'yes'));
            m=struct('track',track,'fraccion',track.fraction,'incidencia',track.incidence,'alt',asind(solar(:,3)),'P',lab.Design.P,'GCR',lab.Design.GCR);
        end
        function monthly(lab,p,P)
            hours=linspace(6,18,97)';data=zeros(97,24);colors=lines(12);names={'Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'};
            for bt=0:1
                ax=lab.MonthlyAxes(bt+1);cla(ax);hold(ax,'on');
                for month=1:12
                    solar=geosolartracking.pv_seguidor_solar(p.lat,datetime(2026,month,21),hours);
                    state=geosolartracking.pv_seguidor_estado(p,solar,P,logical(bt));data(:,12*bt+month)=state.theta;
                    plot(ax,hours-12,state.theta,'Color',colors(month,:),'LineWidth',1.1);
                end
                hold(ax,'off');grid(ax,'on');xlim(ax,[-6 6]);ylim(ax,[-90 90]);xlabel(ax,'Horas solares respecto al mediodía');ylabel(ax,'Giro (°)');
                mode='Sin BT';if bt,mode='Con BT';end
                legend(ax,names,'Location','southoutside','NumColumns',4);subtitle(ax,sprintf('%s · día 21 de cada mes · 2026 · paso %.3f m',mode,P));
            end
            no=cellstr(compose('giro_sin_BT_mes_%02d_grados',1:12));yes=cellstr(compose('giro_con_BT_mes_%02d_grados',1:12));
            lab.MonthlyData=array2table([hours,data],'VariableNames',[{'hora_solar_h'},no,yes]);
        end
        function rebuild(lab)
            if lab.TMYContextKey~=lab.tmyContextKey(),lab.TMYData=[];lab.TMYContextKey="";end
            if isempty(lab.AnnualResult)||lab.AnnualKey~=lab.annualConfigKey(),lab.invalidateAnnual();end
            rebuild@GeosolarFixedLab(lab);
            lab.refreshAnnualAvailability();
            if lab.Valid&&~lab.Busy&&~isempty(lab.TMYData)&&isempty(lab.AnnualResult)
                try,lab.calculateAnnual(lab.TMYData);catch err,lab.AnnualStatus.Text=err.message;end
            end
        end
        function render(lab)
            s=lab.State;m=lab.calculate(s,lab.toSolar(s,s.time));lab.Current=m;lab.scene(m);
            date=datetime(s.date);date.Format='dd/MM/yyyy';reference='Hora solar';if strcmp(s.reference,'civil'),reference=['Hora civil · ' s.zone];end
            values={sprintf('Fecha\n%s',string(date)),sprintf('Hora\n%02d:%02d',floor(s.time),floor(mod(s.time,1)*60)),reference, ...
                sprintf('Giro\n%s°',lab.Owner.number(m.track.theta)),sprintf('Paso\n%.3f m\nGCR %.1f %% · 1/GCR %.3f',m.P,100*m.GCR,1/m.GCR), ...
                sprintf('Sin sombras\n%.2f h',lab.FreeHours),sprintf('Altura libre\n%.3f m',lab.Design.clearance)};
            for k=1:7,lab.Metrics(k).Text=values{k};end
            yyaxis(lab.Axes(3),'left');delete(findall(lab.Axes(3),'Tag','selectedHour'));xline(lab.Axes(3),s.time,'r--','Tag','selectedHour','HandleVisibility','off');
            lab.Status.Text=sprintf('Altura solar: %.2f°\nθ normal: %s° · η plano: %s°\nPendientes: sube al Norte/Este con signo +.',m.alt,lab.Owner.number(90-m.incidencia),lab.Owner.number(m.incidencia));
            if m.alt<=0,lab.Status.Text='Noche: posición de reposo 0°. Giro/incidencia no definidos en la tabla.';
            elseif m.track.terrain<=0,lab.Status.Text='Sol oculto por el plano del terreno.';end
            drawnow limitrate nocallbacks;
        end
        function scene(lab,m)
            p=lab.physical();state=m.track;P=m.P;extent=(p.n-1)*P;margin=max(3,p.L);xl=[-margin extent+margin];yl=[-p.W/2-margin p.W/2+margin];
            rect=polyshape([xl(1) xl(2) xl(2) xl(1)],[yl(1) yl(1) yl(2) yl(2)]);[gx,gy]=boundary(rect);gz=lab.ground(gx,gy,p);
            for ax=lab.Axes(1:2),cla(ax);hold(ax,'on');end
            patch(lab.Axes(1),gx,gy,gz,[.92 .91 .84],'EdgeColor','none');patch(lab.Axes(2),gx,gy,[.92 .91 .84],'EdgeColor','none');
            if m.alt>0&&state.terrain>1e-8
                for j=1:p.n
                    v=lab.vertices(p,state,P,j);distance=(v(:,3)-lab.ground(v(:,1),v(:,2),p))/state.terrain;q=v-distance.*state.sun;
                    shade=intersect(polyshape(q(:,1),q(:,2)),rect);[x,y]=boundary(shade);
                    patch(lab.Axes(1),x,y,lab.ground(x,y,p)+.002,[.3 .3 .3],'FaceAlpha',.25,'EdgeColor','none');patch(lab.Axes(2),x,y,[.3 .3 .3],'FaceAlpha',.25,'EdgeColor','none');
                end
            end
            for j=1:p.n
                [v,origin]=lab.vertices(p,state,P,j);color=[.2 .55 .85];if m.alt<=0||state.terrain<=0,color=[.55 .57 .58];elseif ~state.front,color=[.06 .16 .34];end
                patch(lab.Axes(1),v(:,1),v(:,2),v(:,3),color,'LineWidth',.35,'Tag','trackingTable');patch(lab.Axes(2),v(:,1),v(:,2),color,'LineWidth',.35);
                ends=origin+[-1;1]*p.W/2*state.axis;plot3(lab.Axes(1),ends(:,1),ends(:,2),ends(:,3),'k-','LineWidth',.7);
                plot3(lab.Axes(1),[origin(1) origin(1)],[0 0],[lab.ground(origin(1),0,p) origin(3)],'k-','LineWidth',1);
                if state.front&&state.fraction(j)>1e-10
                    shift=sign(state.lambda)*state.shift;u=[max(-p.L/2,-p.L/2+shift(1)),min(p.L/2,p.L/2+shift(1))];vlim=[max(-p.W/2,-p.W/2+shift(2)),min(p.W/2,p.W/2+shift(2))];
                    q=origin+[u(1);u(2);u(2);u(1)]*state.t+[vlim(1);vlim(1);vlim(2);vlim(2)]*state.axis;
                    patch(lab.Axes(1),q(:,1),q(:,2),q(:,3)+.002,[.85 .15 .1],'EdgeColor','none');patch(lab.Axes(2),q(:,1),q(:,2),[.85 .15 .1],'EdgeColor','none');
                end
                text(lab.Axes(2),origin(1),0,sprintf('%d',j),'HorizontalAlignment','center');
            end
            bounds=[gx gy gz];
            if m.alt>0
                o=[extent/2 0 p.h+lab.ground(extent/2,0,p)+p.L];ray=state.sun*max(3*p.L,min(p.W,6));tip=o+ray;
                quiver3(lab.Axes(1),o(1),o(2),o(3),ray(1),ray(2),ray(3),0,'Color',[1 .7 0],'LineWidth',2.5);plot3(lab.Axes(1),tip(1),tip(2),tip(3),'o','MarkerFaceColor',[1 .8 0],'MarkerEdgeColor',[1 .65 0],'MarkerSize',12);bounds=[bounds;tip];
            end
            e=xl(1)+margin*.55;n=yl(2)-margin*.55;r=margin*.3;directions=[0 1;1 0;0 -1;-1 0];labels={'N','E','S','O'};
            for k=1:4
                de=directions(k,1)*r;dn=directions(k,2)*r;z=lab.ground(e,n,p)+.02;
                quiver3(lab.Axes(1),e,n,z,de,dn,lab.ground(de,dn,p),0,'Color',[.2 .25 .23]);text(lab.Axes(1),e+1.3*de,n+1.3*dn,z+.1,labels{k},'FontWeight','bold');
                quiver(lab.Axes(2),e,n,de,dn,0,'Color',[.2 .25 .23]);text(lab.Axes(2),e+1.3*de,n+1.3*dn,labels{k},'FontWeight','bold');
            end
            for ax=lab.Axes(1:2),daspect(ax,[1 1 1]);subtitle(ax,'Distancias en metros');xlabel(ax,'');ylabel(ax,'');hold(ax,'off');ax.Toolbar.Visible='off';end
            ax=lab.Axes(1);view(ax,[p.camera 25]);xlim(ax,[min(bounds(:,1)) max(bounds(:,1))]);ylim(ax,[min(bounds(:,2)) max(bounds(:,2))]);zlim(ax,[min(gz)-.1 max([max(gz)+p.h+p.L;bounds(:,3)])+.3]);grid(ax,'off');axis(ax,'off');
            view(lab.Axes(2),2);lab.Axes(2).CameraUpVector=[0 1 0];xlim(lab.Axes(2),xl);ylim(lab.Axes(2),yl);
        end
        function adoptLocation(lab,location)
            changed=lab.State.lat~=location.lat||lab.State.lon~=location.lon;
            if changed,lab.RejectedTmyLocation="";lab.RejectedTmyMessage="";lab.TMYData=[];lab.TMYContextKey="";end
            adoptLocation@GeosolarFixedLab(lab,location);lab.DerivedKey="";if changed,lab.invalidateAnnual();end
        end
        function fail(lab,err)
            fail@GeosolarFixedLab(lab,err);lab.DerivedKey="";lab.invalidateAnnual();
            for ax=lab.MonthlyAxes,cla(ax);end
            lab.MonthlyData=table();if isgraphics(lab.AnnualButton),lab.AnnualButton.Enable='off';end
        end
        function invalidateAnnual(lab)
            lab.AnnualResult=[];
            if isgraphics(lab.AnnualExport),lab.AnnualExport.Enable='off';lab.AnnualStatus.Text=sprintf('Ubicación compartida: latitud %+.6f°, longitud %+.6f°. Pulse Calcular para obtener el TMY.',lab.State.lat,lab.State.lon);delete(findall(lab.AnnualAxes,'Tag','annualSelectedPitch'));cla(lab.AnnualAxes);lab.AnnualTable.Data=table();end
            lab.refreshAnnualAvailability();
        end
        function calculateAnnual(lab,met)
            assert(lab.Valid,'Configuración no válida');lab.Owner.stop();lab.Busy=true;cleanup=onCleanup(@()lab.finishAnnual());
            lab.invalidateAnnual();lab.AnnualButton.Enable='off';s=lab.State;p=lab.physical();key=lab.annualConfigKey();
            action='Cargando TMY PVGIS';if nargin>=2||~isempty(lab.TMYData),action='Actualizando curvas con el TMY conservado';end
            lab.AnnualStatus.Text=sprintf('%s · latitud %+.6f°, longitud %+.6f°…',action,s.lat,s.lon);drawnow;
            if nargin<2
                try
                    if ~isempty(lab.TMYData)&&lab.TMYContextKey==lab.tmyContextKey(),met=lab.TMYData;
                    else,met=geosolartracking.pv_seguidor_tmy(s.lat,s.lon);end
                catch err
                    if strcmp(err.identifier,'geosolar:tmyLocation')&&lab.locationKey(s)==lab.locationKey(lab.State)
                        lab.RejectedTmyLocation=lab.locationKey(s);lab.RejectedTmyMessage=string(err.message);
                    end
                    rethrow(err);
                end
            end
            lab.TMYData=met;lab.TMYContextKey=lab.tmyContextKey();
            ratios=unique([linspace(1,max(10,1/lab.Design.GCR),65),1/lab.Design.GCR]);H=zeros(numel(ratios),2);
            dlg=uiprogressdlg(lab.Owner.Figure,'Title','Irradiación anual PVGIS','Cancelable','on','Message','Calculando con y sin backtracking…');guard=onCleanup(@()lab.closeProgress(dlg));
            for k=1:numel(ratios)
                if ~isvalid(lab.Owner)||~isgraphics(lab.Owner.Figure)||~isvalid(dlg)||dlg.CancelRequested,error('geosolar:cancelled','Cálculo cancelado');end
                result=geosolartracking.pv_seguidor_anual(p,met,ratios(k));H(k,:)=result.H;dlg.Value=k/numel(ratios);drawnow;
            end
            assert(lab.annualConfigKey()==key,'La configuración cambió durante el cálculo; repita la consulta');
            lab.AnnualResult=struct('inverseGCR',ratios(:),'H',H);lab.AnnualKey=key;
            plot(lab.AnnualAxes,ratios,H,'LineWidth',1.5);grid(lab.AnnualAxes,'on');xlabel(lab.AnnualAxes,'1/GCR = paso horizontal / anchura');ylabel(lab.AnnualAxes,'Irradiación frontal (kWh/m²/año)');
            low=min(H,[],'all');high=max(H,[],'all');padding=max(1,.06*(high-low));
            xlim(lab.AnnualAxes,[min(ratios) max(ratios)]);ylim(lab.AnnualAxes,[max(0,low-padding) high+padding]);
            xline(lab.AnnualAxes,1/lab.Design.GCR,'--','Paso seleccionado','HandleVisibility','off','Tag','annualSelectedPitch');legend(lab.AnnualAxes,{'Sin BT','Con BT'},'Location','southeast');title(lab.AnnualAxes,'TMY PVGIS · irradiación anual frente a 1/GCR');
            lab.AnnualTable.Data=table(100./ratios(:),ratios(:),H(:,1),H(:,2),'VariableNames',{'GCR_porcentaje','inverso_GCR','sin_BT_kWh_m2_anio','con_BT_kWh_m2_anio'});
            lab.AnnualStatus.Text=sprintf('%d horas · albedo 0,20 · difusa isotrópica · sin bifacialidad/pérdidas eléctricas.\nNo equivale a producción FV. PVGIS © Unión Europea.',size(met.sun,1));lab.AnnualExport.Enable='on';
            drawnow nocallbacks;
        end
        function exportAnnual(lab,file)
            assert(~isempty(lab.AnnualResult),'Calcule primero el año PVGIS');geosolartracking.pv_seguidor_exportar_csv(lab.AnnualResult,file);
        end
        function exportMonthly(lab,file)
            assert(lab.Valid,'Configuración no válida');fid=fopen(file,'w','n','UTF-8');assert(fid>=0);fprintf(fid,'# GEOSOLAR; tracking; comparación mensual 2026\n# parameters: %s\n# Hora solar; mismo paso en ambas comparaciones\n',jsonencode(lab.State));fclose(fid);
            writetable(lab.MonthlyData,file,'Delimiter',';','Encoding','UTF-8','WriteMode','append','WriteVariableNames',true);
        end
    end
    methods (Access=private)
        function key=tmyContextKey(lab)
            p=lab.physical();key=string(sprintf('%.6f_%.6f_%.10f_%.10f',p.lat,p.lon,p.ns,p.eo));
        end
        function key=annualConfigKey(lab)
            p=lab.physical();key=string(jsonencode(rmfield(p,{'time','camera','speed','date','reference','zone','bt','slopeUnits','h'})));
        end
        function annualDialog(lab)
            try,lab.calculateAnnual();catch err
                if isvalid(lab.Owner)&&isgraphics(lab.Owner.Figure),lab.AnnualStatus.Text=['No se ha calculado la curva. ' err.message];lab.refreshAnnualAvailability();end
            end
        end
        function finishAnnual(lab)
            lab.Busy=false;lab.refreshAnnualAvailability();
        end
        function refreshAnnualAvailability(lab)
            if ~isgraphics(lab.AnnualButton),return;end
            rejected=lab.RejectedTmyLocation==lab.locationKey(lab.State);
            lab.AnnualButton.Enable=lab.Valid&&~lab.Busy&&~rejected;
            if rejected,lab.AnnualStatus.Text=['No se ha calculado la curva. ' char(lab.RejectedTmyMessage)];end
        end
        function exportPlotDialog(lab,k)
            if ~lab.Valid,return;end
            [f,p]=uiputfile('*.png');if isequal(f,0),return;end
            axes=[lab.Axes lab.MonthlyAxes lab.AnnualAxes];exportgraphics(axes(k),fullfile(p,f),'Resolution',160);
        end
        function exportAnnualDialog(lab)
            [f,p]=uiputfile('*.csv','Guardar CSV anual separado por tabuladores');if ~isequal(f,0),lab.exportAnnual(fullfile(p,f));end
        end
        function exportMonthlyDialog(lab)
            [f,p]=uiputfile('*.csv');if ~isequal(f,0),lab.exportMonthly(fullfile(p,f));end
        end
    end
    methods (Static)
        function key=locationKey(s)
            key=string(sprintf('%.6f_%.6f',s.lat,s.lon));
        end
        function closeProgress(dialog)
            if isvalid(dialog),delete(dialog);end
        end
        function z=ground(x,y,p),z=x*tand(p.eo)+y*tand(p.ns);end
        function [v,origin]=vertices(p,state,P,j)
            origin=[(j-1)*P 0 p.h+(j-1)*P*tand(p.eo)];
            v=origin+[-1;1;1;-1]*p.L/2*state.t+[-1;-1;1;1]*p.W/2*state.axis;
        end
    end
end
