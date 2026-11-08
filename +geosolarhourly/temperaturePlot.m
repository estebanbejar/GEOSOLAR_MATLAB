function line=temperaturePlot(ax,result,visible)
% T2m del CSV principal. Las medias se calculan desde registros horarios.
line=gobjects(1);p=result.Points;
if ~ismember('Temperature',p.Properties.VariableNames)||~any(isfinite(p.Temperature)),return;end
color=[.38 .23 .12];yyaxis(ax,'right');hold(ax,'on');
time=p.Time;if strcmp(result.Mode,'yearly'),time=year(time);end
marker='none';if strcmp(result.Mode,'yearly')||height(p)==1,marker='o';end
line=plot(ax,time,p.Temperature,'-.','Color',color,'LineWidth',1.8,'Marker',marker,'MarkerSize',4,'DisplayName','Temperatura del aire');
line.Visible=visible;
line.DataTipTemplate.DataTipRows=[dataTipTextRow('Fecha UTC',p.Time),dataTipTextRow('Temperatura del aire · °C',p.Temperature),dataTipTextRow('Registros',p.Records)];
finite=p.Temperature(isfinite(p.Temperature));lo=min(finite);hi=max(finite);padding=max(1,.08*(hi-lo));ylim(ax,[lo-padding hi+padding]);
ylabel(ax,'Temperatura del aire (°C)');ax.YAxis(2).Color=color;ax.YAxis(2).Visible=visible;
yyaxis(ax,'left');ax.YAxis(1).Color=[.15 .15 .15];
end
