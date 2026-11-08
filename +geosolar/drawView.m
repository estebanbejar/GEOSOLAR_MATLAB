function drawView(ax,index,s)
% Construct once, then update data without replacing graphic objects.
first=~isappdata(ax,'gsObjects');
if first, setappdata(ax,'gsObjects',{}); end
setappdata(ax,'gsIndex',0);
colors=[217 108 9;33 128 75;23 104 181;166 30 130]/255;
deltas=[23.45 0 -23.45 s.delta];
names={'Junio +23,45°','Equinoccios 0°','Diciembre −23,45°','Caso seleccionado'};
titles={'1. Declinación solar','2. Recorridos en el Ecuador','3. Ángulo horario',...
 '1. Latitud y altura solar al mediodía','2. Recorridos solares en la latitud seleccionada','4. Relación entre ángulos'};
if first
hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');
ax.FontName='Arial'; ax.FontSize=11;
title(ax,titles{index},'Color',[.07 .2 .31],'FontSize',16);
xlim(ax,[-1.45 1.45]); ylim(ax,[-1.4 1.4]); zlim(ax,[-1.3 1.4]);
end
q=linspace(0,360,181); p=geosolar.position(s.phi,s.delta,s.time);
switch index
 case 1
    [x,y,z]=sphere(32);
    geosolar.sceneObject(ax,'surf',.48*x,.48*y,.48*z,'FaceColor',[.85 .91 .95],'EdgeColor','none','FaceAlpha',.5);
    geosolar.sceneObject(ax,'patch',1.1*cosd(q),1.1*sind(q),zeros(size(q)),[.7 .8 .88],'FaceAlpha',.15,'EdgeColor',[.5 .6 .7]);
    geosolar.sceneObject(ax,'plot3',[0 0],[0 0],[-.8 .9],'-','Color',[.2 .3 .4]);
    geosolar.sceneObject(ax,'text',0,0,1,'N · eje terrestre');
    for j=1:4
        ray=1.22*[cosd(deltas(j));0;sind(deltas(j))];
        geosolar.sceneObject(ax,'plot3',[0 ray(1)],[0 0],[0 ray(3)],'Color',colors(j,:),'LineWidth',2,'LineStyle',style(j));
    end
    a=linspace(0,s.delta,50);
    geosolar.sceneObject(ax,'plot3',.8*cosd(a),zeros(size(a)),.8*sind(a),'Color',colors(4,:),'LineWidth',2);
    geosolar.sceneObject(ax,'text',.85*cosd(s.delta/2),0,.85*sind(s.delta/2),'δ','Color',colors(4,:),'FontSize',15);
    geosolar.sceneObject(ax,'text',-1,-.6,-.22,'Plano ecuatorial');
    if first, view(ax,[-28 16]); end
    subtitle(ax,'Direcciones de culminación · independiente de φ');
 case {2,5}
    if index==2, phi=0; else, phi=s.phi; end
    geosolar.sceneObject(ax,'patch',cosd(q),sind(q),zeros(size(q)),[.7 .8 .88],'FaceAlpha',.12,'EdgeColor',[.4 .5 .6]);
    geosolar.sceneObject(ax,'plot3',[-1.15 1.15],[0 0],[0 0],'Color',[.65 .65 .65]);
    geosolar.sceneObject(ax,'plot3',[0 0],[-1.15 1.15],[0 0],'Color',[.65 .65 .65]);
    geosolar.sceneObject(ax,'plot3',[0 0],[0 0],[0 1.1],':','Color',[.5 .5 .5]);
    geosolar.sceneObject(ax,'text',1.15,0,0,'Este'); geosolar.sceneObject(ax,'text',-1.15,0,0,'Oeste');
    geosolar.sceneObject(ax,'text',0,1.15,0,'Norte'); geosolar.sceneObject(ax,'text',0,-1.15,0,'Sur'); geosolar.sceneObject(ax,'text',0,0,1.15,'Cenit');
    refs=gobjects(1,4);
    for j=1:4
        path=geosolar.dailyPath(phi,deltas(j));
        refs(j)=geosolar.sceneObject(ax,'plot3',path.visible(1,:),path.visible(2,:),path.visible(3,:),...
            'Color',colors(j,:),'LineWidth',1.7,'LineStyle',style(j));
        geosolar.sceneObject(ax,'plot3',path.night(1,:),path.night(2,:),path.night(3,:),...
            ':','Color',.5+.5*colors(j,:),'LineWidth',1);
    end
    v=geosolar.position(phi,s.delta,s.time);
    geosolar.sceneObject(ax,'plot3',[0 v.E],[0 v.N],[0 v.U],'-','Color',colors(4,:),'LineWidth',1.4);
    geosolar.sceneObject(ax,'plot3',[0 v.E v.E],[0 v.N v.N],[0 0 v.U],'--','Color',colors(4,:));
    geosolar.sceneObject(ax,'plot3',v.E,v.N,v.U,'o','MarkerSize',8,'MarkerFaceColor',colors(4,:),'Color','white');
    if v.horizontalNorm>1e-10
        a=linspace(0,v.alpha,50); h=[v.E;v.N]/v.horizontalNorm;
        arc=[.4*h(1)*cosd(a);.4*h(2)*cosd(a);.4*sind(a)];
    else
        arc=nan(3,50);
    end
    geosolar.sceneObject(ax,'plot3',arc(1,:),arc(2,:),arc(3,:),'Color',colors(4,:),'LineWidth',2);
    if first, view(ax,[125 22]); end
    subtitle(ax,sprintf('φ = %+.2f° · α = %.2f° · punteado: noche',phi,v.alpha));
    if index==5 && first
        legend(ax,refs,names,'Location','southoutside','NumColumns',2,'FontSize',9);
    end
 case 3
    geosolar.sceneObject(ax,'plot',cosd(q),sind(q),'Color',[.4 .5 .6]);
    for h=[10 12 14]
        w=15*(h-12); r=[cosd(w);-sind(w)];
        geosolar.sceneObject(ax,'plot',[0 r(1)],[0 r(2)],':','Color',[.55 .6 .65]);
        geosolar.sceneObject(ax,'text',1.08*r(1),1.08*r(2),sprintf('%02d h',h));
    end
    geosolar.sceneObject(ax,'plot',[0 1.2],[0 0],'-','Color',[.1 .2 .3],'LineWidth',1.5);
    x=cosd(s.delta)*cosd(p.omega); y=-cosd(s.delta)*sind(p.omega);
    geosolar.sceneObject(ax,'plot',[0 x],[0 y],'Color',colors(4,:),'LineWidth',2);
    geosolar.sceneObject(ax,'plot',x,y,'o','MarkerFaceColor',colors(4,:),'Color',colors(4,:));
    a=linspace(0,-p.omega,80); geosolar.sceneObject(ax,'plot',.45*cosd(a),.45*sind(a),'Color',colors(4,:));
    geosolar.sceneObject(ax,'text',-.55,.1,'Polo norte'); geosolar.sceneObject(ax,'text',-1.3,-1.15,'+X: mediodía   +Y: mañana');
    subtitle(ax,sprintf('ω = 15°(t − 12) = %.1f° · δ = %+.2f°',p.omega,s.delta));
    geosolar.sceneObject(ax,'text',-1.3,-1.35,'Desde +Z · tarde: sentido horario','FontSize',10);
 case 4
    r=.48; o=r*[cosd(s.phi);sind(s.phi)];
    up=[cosd(s.phi);sind(s.phi)]; north=[-sind(s.phi);cosd(s.phi)];
    % Equatorial XYZ: rotation axis +Z; observer and solar rays in XZ.
    % Include the five parallels in the mesh so the section rims coincide
    % with surface vertices rather than crossing coarse sphere facets.
    latitudes=[66.55 23.45 0 -23.45 -66.55];
    meshLatitude=unique([linspace(-90,90,121),latitudes]);
    [longitude,latitudeGrid]=meshgrid(q,meshLatitude);
    geosolar.sceneObject(ax,'surf',r*cosd(latitudeGrid).*cosd(longitude),...
        r*cosd(latitudeGrid).*sind(longitude),r*sind(latitudeGrid),...
        'FaceColor',[.63 .78 .90],'FaceAlpha',.18,'EdgeColor','none');
    % Geographic meridians converge at both poles; subdued behind the angles.
    meridianLatitude=linspace(-90,90,181);
    for meridianLongitude=0:30:330
        geosolar.sceneObject(ax,'plot3',...
            r*cosd(meridianLatitude)*cosd(meridianLongitude),...
            r*cosd(meridianLatitude)*sind(meridianLongitude),...
            r*sind(meridianLatitude),...
            'Color',[.60 .63 .66],'LineWidth',.4);
    end
    for j=1:numel(latitudes)
        height=r*sind(latitudes(j)); radius=r*cosd(latitudes(j));
        % Plane sections are bounded by the sphere, not oversized disks.
        geosolar.sceneObject(ax,'patch',radius*cosd(q),radius*sind(q),height*ones(size(q)),...
            [.60 .65 .69],'FaceAlpha',.045,'EdgeColor','none');
        geosolar.sceneObject(ax,'plot3',radius*cosd(q),radius*sind(q),height*ones(size(q)),...
            'Color',[.42 .45 .48],'LineWidth',.6);
    end
    labels={'Círculo polar ártico','Trópico de Cáncer','Ecuador',...
        'Trópico de Capricornio','Círculo polar antártico'};
    for j=1:numel(latitudes)
        geosolar.sceneObject(ax,'text',-.73,-.05,r*sind(latitudes(j)),...
            labels{j},'FontSize',8,'Color',[.35 .38 .41]);
    end
    if first
        view(ax,[12 10]);
        xlim(ax,[-.85 1.5]); ylim(ax,[-.6 .6]); zlim(ax,[-1.15 1.35]);
    end
    geosolar.meridianObject(ax,'plot',r*cosd(q),r*sind(q),'Color',[.4 .5 .6]);
    geosolar.meridianObject(ax,'plot',[0 0],[-.65 .75],'Color',[.4 .5 .6]);
    geosolar.meridianObject(ax,'plot',[-.65 .65],[0 0],':','Color',[.4 .5 .6]);
    geosolar.meridianObject(ax,'line',o(1)+[-.85 .85]*north(1),o(2)+[-.85 .85]*north(2),'Color',[.2 .3 .4]);
    geosolar.meridianObject(ax,'line',o(1)+[0 .85]*up(1),o(2)+[0 .85]*up(2),'Color',[.5 .5 .5],'LineStyle',':');
    geosolar.meridianObject(ax,'text',o(1)+.9*up(1),o(2)+.9*up(2),'Cenit');
    geosolar.meridianObject(ax,'text',o(1)+.9*north(1),o(2)+.9*north(2),'Norte');
    geosolar.meridianObject(ax,'text',o(1)-.9*north(1),o(2)-.9*north(2),'Sur');
    for j=1:4
        ray=[cosd(deltas(j));sind(deltas(j))];
        geosolar.meridianObject(ax,'line',o(1)+[0 .95]*ray(1),o(2)+[0 .95]*ray(2),'Color',colors(j,:),'LineWidth',2,'LineStyle',style(j));
    end
    a=linspace(0,s.phi,50); geosolar.meridianObject(ax,'plot',.28*cosd(a),.28*sind(a),'Color',[.3 .3 .3]);
    geosolar.meridianObject(ax,'text',.3*cosd(s.phi/2),.3*sind(s.phi/2),'φ');
    geosolar.meridianObject(ax,'line',[0 o(1)],[0 o(2)],'Color',[.4 .4 .4]);
    geosolar.meridianObject(ax,'plot',o(1),o(2),'ko','MarkerFaceColor','k','MarkerSize',4);
    v=geosolar.position(s.phi,s.delta,12);
    if v.N>=0, start=s.phi+90; else, start=s.phi-90; end
    finish=s.delta+360*round((start-s.delta)/360);
    a=linspace(start,finish,60);
    geosolar.meridianObject(ax,'plot',o(1)+.42*cosd(a),o(2)+.42*sind(a),'Color',colors(4,:),'LineWidth',1.5);
    geosolar.meridianObject(ax,'text',o(1)+.48*cosd(mean(a)),o(2)+.48*sind(mean(a)),'α','Color',colors(4,:));
    subtitle(ax,sprintf('Siempre ω = 0° · α mediodía = %.2f°',v.alpha));
    geosolar.meridianObject(ax,'text',-.75,-1.05,'Ecuador, trópicos y círculos polares');
 case 6
    if first, axis(ax,'normal'); xlim(ax,[0 1]); ylim(ax,[0 1]); end
    if isnan(p.gamma), gamma='indeterminado'; else, gamma=sprintf('%.2f°',p.gamma+0); end
    lines={ '\bf sin α = sin φ sin δ + cos φ cos δ cos ω',...
      sprintf('sin α = sin(%.2f°) sin(%.2f°)',s.phi,s.delta),...
      sprintf('          + cos(%.2f°) cos(%.2f°) cos(%.2f°)',s.phi,s.delta,p.omega),...
      sprintf('α = %.5f°     γ = %s',p.alpha,gamma),...
      'Ecuador: sin α = cos δ cos ω',...
      sprintf('Mediodía: 90° − |φ − δ| = %.2f°',90-abs(s.phi-s.delta)),...
      'Acimut: Sur = 0°; Este < 0°; Oeste > 0°',...
      'γ = atan2(−E, −N); cenit: indeterminado',...
      'X = Este; Y = Norte; Z = Cenit',...
      '0 h y 24 h: la misma posición solar'};
    lines{end+1}='';
    if abs(s.phi)==90, lines{end}='Polo: marco y acimut convencionales'; end
    for k=1:numel(lines)
        geosolar.sceneObject(ax,'text',.01,.95-(k-1)*.09,lines{k},'FontSize',12,'Interpreter','tex');
    end
end
end
function s=style(j)
if j==4, s='--'; else, s='-'; end
end
