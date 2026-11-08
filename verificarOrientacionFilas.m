function verificarOrientacionFilas
root=fileparts(mfilename('fullpath'));out=fullfile(root,'outputs');diary(fullfile(out,'orientacion_filas_verificacion.txt'));d=onCleanup(@()diary('off'));
g=iniciarGeosolar;c=onCleanup(@()delete(g));g.selectLab(3,'Filas');f=g.Fixed;
for phi=[40 -40]
    f.setParameter('lat',phi);f.setParameter('alpha',0);
    if phi>0,f.setParameter('date','2026-12-21');else,f.setParameter('date','2026-06-21');end
    v=f.Current.vertices{1};[e,n]=f.world(v(:,1),v(:,2));xyz=[e n v(:,3)];
    normal=cross(xyz(2,:)-xyz(1,:),xyz(3,:)-xyz(1,:));normal=normal/norm(normal);
    assert(abs(normal(1))<1e-12&&normal(2)*phi<0&&normal(3)>0);
    arrow=findall(f.Axes(2),'Tag','frontDirection');assert(abs(arrow.UData)<1e-12&&arrow.VData*phi<0);
    rendered=findall(f.Axes(1),'Tag','fixedTable');
    for mesh=rendered'
        v=[mesh.XData(:) mesh.YData(:) mesh.ZData(:)];actual=cross(v(2,:)-v(1,:),v(3,:)-v(1,:));
        assert(abs(actual(1))<1e-10&&actual(2)*phi<0&&actual(3)>0);
    end
    drawnow;pause(.5);suffix='norte';if phi<0,suffix='sur';end
    exportgraphics(f.Axes(2),fullfile(out,['orientacion_planta_' suffix '.png']),'Resolution',180);
    exportgraphics(f.Axes(1),fullfile(out,['orientacion_3d_' suffix '.png']),'Resolution',180);
    fprintf('Latitud %+.0f°: normal frontal [Este Norte Cenit] = [%+.6f %+.6f %+.6f]\n',phi,normal);
    fprintf('La dirección longitudinal de la fila es Este–Oeste; el frente es %s.\n',string(ternary(phi>0,'Sur','Norte')));
end
disp('PASS: normales frontales y dirección longitudinal en coordenadas geográficas.');
end
function y=ternary(test,a,b),if test,y=a;else,y=b;end,end
