function verificarVistaInicialFilas
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');g=iniciarGeosolar;c=onCleanup(@()delete(g));
g.selectLab(3,'Filas');f=g.Fixed;ax=f.Axes(1);
assert(strcmp(ax.Visible,'off')&&strcmp(ax.XGrid,'off')&&strcmp(ax.YGrid,'off')&&strcmp(ax.ZGrid,'off'));
assert(numel(findall(ax,'Tag','fixedTable'))==f.State.n);
for p=findall(ax,'Tag','fixedTable')'
    assert(all(p.XData>=ax.XLim(1)&p.XData<=ax.XLim(2)));
    assert(all(p.YData>=ax.YLim(1)&p.YData<=ax.YLim(2)));
    assert(all(p.ZData>=ax.ZLim(1)&p.ZData<=ax.ZLim(2)));
end
initial=[ax.XLim ax.YLim ax.ZLim ax.View];
exportapp(g.Figure,fullfile(out,'filas_primera_apertura.png'));
drawnow;
exportgraphics(ax,fullfile(out,'filas_primera_vista.png'),'Resolution',160);
f.render();assert(max(abs(initial-[ax.XLim ax.YLim ax.ZLim ax.View]))<1e-10);
g.selectLab(1,'Órbita');g.selectLab(3,'Filas');assert(max(abs(initial-[ax.XLim ax.YLim ax.ZLim ax.View]))<1e-10);
exportapp(g.Figure,fullfile(out,'filas_sin_planos_traseros.png'));
disp('PASS: primer encuadre, cinco mesas completas, límites estables y vista sin caja/rejilla.');
end
