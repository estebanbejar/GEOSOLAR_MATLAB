function handles=annualBars(ax,result,comparison)
% Barras agrupadas por año, con huecos NaN para coberturas no coincidentes.
colors=[.86 .55 .1;.14 .61 .6;.58 .41 .74;.08 .24 .32;.87 .35 .38];
names={'Directa','Difusa','Reflejada','Global (suma)','Global del CSV comparado'};
p=result.Points;years=year(p.Time);if ~isempty(comparison),years=union(years,year(comparison.Points.Time));end
years=years(:);values=nan(numel(years),5);counts=values;
[~,idx]=ismember(year(p.Time),years);values(idx,1:4)=[p.Direct p.Diffuse p.Reflected p.Global];counts(idx,1:4)=repmat(p.Records,1,4);
order=[4 1 2 3];
if ~isempty(comparison)
    c=comparison.Points;[~,idx]=ismember(year(c.Time),years);values(idx,5)=c.Global;counts(idx,5)=c.Records;order(end+1)=5;
end
hold(ax,'off');bars=bar(ax,years,values(:,order),'grouped','BarWidth',.85);handles=gobjects(1,5);
for k=1:numel(order)
    key=order(k);b=bars(k);b.FaceColor=colors(key,:);b.EdgeColor='none';b.DisplayName=names{key};handles(key)=b;
    b.DataTipTemplate.DataTipRows=[dataTipTextRow('Año UTC',years),dataTipTextRow([names{key} ' · ' result.Units],values(:,key)),dataTipTextRow('Registros',counts(:,key))];
    if key~=5&&~isempty(comparison),b.DataTipTemplate.DataTipRows(end+1)=dataTipTextRow('Global comparada · kWh/m²',values(:,5));end
end
xlim(ax,[years(1)-.6 years(end)+.6]);xticks(ax,years(1:max(1,ceil(numel(years)/20)):end));xtickformat(ax,'%d');xlabel(ax,'Año UTC');
end
