classdef GeosolarCredits < handle
    properties (SetAccess=private)
        Panel
        Side
        Links
        TextLabels
        LicenseText
        VersionLabel
    end
    properties (Constant)
        Version='0.7'
        Updated='8 de noviembre de 2026'
    end
    methods
        function page=GeosolarCredits(sideHost,host)
            page.Side=uipanel(sideHost,'BorderType','none','Visible','off');page.Side.Layout.Row=1;page.Side.Layout.Column=1;
            side=uigridlayout(page.Side,[9 1]);side.Scrollable='on';side.RowHeight={32,88,30,30,30,30,30,80,'1x'};
            uilabel(side,'Text','Créditos','FontSize',17,'FontWeight','bold');
            uilabel(side,'Text','Información docente, autoría, fuentes de datos y licencias de GEOSOLAR MATLAB.','WordWrap','on');
            uihyperlink(side,'Text','ORCID del autor','URL','https://orcid.org/0000-0003-1341-8767');
            uihyperlink(side,'Text','GEOSOLAR_MATLAB · GitHub','URL','https://github.com/estebanbejar/GEOSOLAR_MATLAB');
            uihyperlink(side,'Text','GEOSOLAR · versión HTML','URL','https://estebanbejar.github.io/GEOSOLAR/');
            uihyperlink(side,'Text','GEOSOLAR · GitHub','URL','https://github.com/estebanbejar/GEOSOLAR');
            uihyperlink(side,'Text','PVGIS · web oficial','URL','https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis_en');
            uilabel(side,'Text',sprintf('Universidad de Salamanca\nEscuela Técnica Superior de Ingeniería Industrial'),'WordWrap','on');
            page.Panel=uipanel(host,'BorderType','none','Visible','off');page.Panel.Layout.Row=1;page.Panel.Layout.Column=1;
            content=uigridlayout(page.Panel,[20 1]);content.Scrollable='on';content.Padding=[22 14 22 18];content.RowSpacing=8;
            content.RowHeight={40,195,28,26,52,26,48,28,65,24,30,60,28,156,28,105,28,70,220,36};
            page.TextLabels.Title=uilabel(content,'Text','Créditos y aviso de uso','FontSize',23,'FontWeight','bold','FontColor',[.09 .20 .31]);
            intro=uigridlayout(content,[3 1]);intro.Padding=[0 0 0 0];intro.RowSpacing=4;intro.RowHeight={52,24,'1x'};
            page.TextLabels.Purpose=uilabel(intro,'Text','GEOSOLAR MATLAB es una herramienta didáctica para la asignatura Tecnología e Instalaciones Fotovoltaicas, del Grado en Electrónica Industrial y Automática de la Escuela Técnica Superior de Ingeniería Industrial de la Universidad de Salamanca.','WordWrap','on');
            page.Links.School=uihyperlink(intro,'Text','https://industriales.usal.es/','URL','https://industriales.usal.es/');
            page.TextLabels.Disclaimer=uilabel(intro,'Text',sprintf(['Su finalidad es facilitar la comprensión de la geometría solar, la irradiación y el comportamiento de las instalaciones fotovoltaicas mediante simulaciones y visualizaciones interactivas.\n\n' ...
                'Los modelos incorporan simplificaciones y aproximaciones con fines docentes. Sus resultados no sustituyen el cálculo, la verificación normativa ni la evaluación técnica necesarios para proyectar una instalación real. El software se proporciona sin garantías de ausencia de errores.']),'WordWrap','on');
            page.heading(content,'Autoría y desarrollo');
            page.TextLabels.Author=uilabel(content,'Text','Esteban Sánchez Hernández','FontSize',16,'FontWeight','bold');
            page.TextLabels.Affiliation=uilabel(content,'Text','Catedrático de Escuela Universitaria del Área de Tecnología Electrónica, Departamento de Física Aplicada, Universidad de Salamanca.','WordWrap','on');
            page.Links.ORCID=uihyperlink(content,'Text','ORCID: 0000-0003-1341-8767','URL','https://orcid.org/0000-0003-1341-8767');
            page.TextLabels.Codex=uilabel(content,'Text','Programado con Codex de OpenAI, utilizando GPT-6.1 Sol, bajo la dirección del autor.','WordWrap','on');
            page.heading(content,'Datos y servicios de PVGIS');
            page.TextLabels.PVGIS=uilabel(content,'Text','Esta aplicación utiliza datos y resultados del Photovoltaic Geographical Information System (PVGIS) de la Comisión Europea, Joint Research Centre (JRC).','WordWrap','on');
            uilabel(content,'Text','PVGIS © European Union, 2001–2026.');
            row=uigridlayout(content,[1 2]);row.ColumnWidth={'1x','1x'};row.Padding=[0 0 0 0];
            page.Links.PVGIS=uihyperlink(row,'Text','Web oficial de PVGIS','URL','https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis_en');
            page.Links.PVGISTerms=uihyperlink(row,'Text','Condiciones de uso y atribución','URL','https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis/general-information/usage-conditions-data-protection_en');
            uilabel(content,'Text','La documentación y los resultados de PVGIS no reflejan necesariamente la posición de la Comisión Europea. El uso de sus datos no implica respaldo institucional a esta aplicación.','WordWrap','on');
            page.heading(content,'Otros componentes y servicios');
            services=uigridlayout(content,[3 2]);services.ColumnWidth={150,'1x'};services.RowHeight={36,36,64};services.Padding=[0 0 0 0];
            page.Links.OSM=uihyperlink(services,'Text','OpenStreetMap','URL','https://www.openstreetmap.org/copyright');
            uilabel(services,'Text','Cartografía © colaboradores de OpenStreetMap, disponible bajo licencia ODbL.','WordWrap','on');
            page.Links.Leaflet=uihyperlink(services,'Text','Leaflet','URL','https://leafletjs.com/');
            uilabel(services,'Text','Biblioteca del selector de mapas, distribuida bajo licencia BSD de dos cláusulas.','WordWrap','on');
            page.Links.OpenMeteo=uihyperlink(services,'Text','Open-Meteo','URL','https://open-meteo.com/en/docs/geocoding-api');
            uilabel(services,'Text','Servicios de búsqueda de localidades y determinación del huso horario. Su geocodificación utiliza datos de GeoNames.','WordWrap','on');
            page.heading(content,'Código fuente y versión web');
            links=uigridlayout(content,[3 1]);links.RowHeight={28,28,28};links.Padding=[0 0 0 0];
            page.Links.Repository=uihyperlink(links,'Text','Repositorio GEOSOLAR_MATLAB','URL','https://github.com/estebanbejar/GEOSOLAR_MATLAB');
            page.Links.Web=uihyperlink(links,'Text','Versión HTML de GEOSOLAR','URL','https://estebanbejar.github.io/GEOSOLAR/');
            page.Links.WebRepository=uihyperlink(links,'Text','Repositorio de la versión HTML: GEOSOLAR','URL','https://github.com/estebanbejar/GEOSOLAR');
            page.heading(content,'Licencia');
            uilabel(content,'Text','El código de GEOSOLAR MATLAB se distribuye bajo licencia MIT, conservando las atribuciones y licencias de sus componentes y datos externos. Los logotipos y marcas pertenecen a sus respectivos titulares.','WordWrap','on');
            root=fileparts(mfilename('fullpath'));
            page.LicenseText=uitextarea(content,'Editable','off','Value',cellstr(splitlines(string(fileread(fullfile(root,'LICENSE'))))),'FontSize',11);
            page.VersionLabel=uilabel(content,'Text',sprintf('GEOSOLAR MATLAB · Versión %s · Actualización: %s',page.Version,page.Updated),'FontColor',[.3 .35 .37],'WordWrap','on');
            page.Panel.AutoResizeChildren='off';page.Panel.SizeChangedFcn=@(~,~)page.fit(content);page.fit(content);
        end
    end
    methods (Static,Access=private)
        function heading(parent,text)
            uilabel(parent,'Text',text,'FontSize',15,'FontWeight','bold','FontColor',[.09 .20 .31]);
        end
        function fit(content)
            rows=content.RowHeight;if content.Parent.Position(3)<950,rows{2}=310;else,rows{2}=195;end;content.RowHeight=rows;
        end
    end
end
