function verificarCreditosSuite()
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'creditos_verificacion.txt'));d=onCleanup(@()diary('off'));
before=timerfindall;g=iniciarGeosolar('PersistLocation',false);guard=onCleanup(@()delete(g));
assert(numel(g.NavigationButtons)==8&&strcmp(g.NavigationButtons(8).Text,'Créditos')&&strcmp(g.Credits.Panel.Visible,'off'));
g.toggle();assert(g.Playing);g.NavigationButtons(8).ButtonPushedFcn([],[]);assert(g.ActiveLab==8&&~g.Playing&&strcmp(g.Clock.Running,'off'));
assert(strcmp(g.Credits.Panel.Visible,'on')&&strcmp(g.Credits.Side.Visible,'on')&&strcmp(g.Orbit.Panel.Visible,'off')&&strcmp(g.Hourly.Panel.Visible,'off'));
g.toggle();assert(~g.Playing);p=g.Credits;
assert(contains(p.TextLabels.Purpose.Text,'Tecnología e Instalaciones Fotovoltaicas')&&contains(p.TextLabels.Purpose.Text,'Grado en Electrónica Industrial y Automática'));
assert(strcmp(p.TextLabels.Author.Text,'Esteban Sánchez Hernández')&&contains(p.TextLabels.Affiliation.Text,'Departamento de Física Aplicada')&&contains(p.TextLabels.Codex.Text,'GPT-6.1 Sol'));
assert(strcmp(p.Links.ORCID.URL,'https://orcid.org/0000-0003-1341-8767')&&strcmp(p.Links.Repository.URL,'https://github.com/estebanbejar/GEOSOLAR_MATLAB'));
assert(strcmp(p.Links.Web.URL,'https://estebanbejar.github.io/GEOSOLAR/')&&strcmp(p.Links.WebRepository.URL,'https://github.com/estebanbejar/GEOSOLAR'));
fields=fieldnames(p.Links);for k=1:numel(fields),assert(startsWith(p.Links.(fields{k}).URL,'https://'));end
assert(contains(join(string(p.LicenseText.Value)),'MIT License')&&strcmp(p.LicenseText.Editable,'off')&&contains(p.VersionLabel.Text,'0.7'));
drawnow;pause(.5);exportapp(g.Figure,fullfile(out,'creditos_suite.png'));
g.Figure.WindowState='normal';g.Figure.Position=[30 30 1050 720];drawnow;pause(.5);exportapp(g.Figure,fullfile(out,'creditos_1050.png'));
g.selectLab(7,'Series horarias');assert(~isempty(g.Hourly.Current)&&strcmp(p.Panel.Visible,'off'));
g.selectLab(8,'Créditos');g.selectLab(2,'Geometría solar');assert(strcmp(p.Panel.Visible,'off')&&strcmp(p.Side.Visible,'off')&&strlength(g.LastError)==0);
delete(guard);assert(numel(timerfindall)==numel(before));
disp('PASS: Créditos a la derecha de 07, texto aprobado, autoría/modelo, enlaces HTTPS, MIT, versión/fecha, dos tamaños, navegación, parada de animación y cierre.');
end
