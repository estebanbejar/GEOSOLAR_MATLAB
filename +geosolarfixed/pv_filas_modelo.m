function m = pv_filas_modelo(p, fecha, horas)
% Modelo didáctico: coordenadas locales x hacia el borde alto, y a lo largo.
% Horas solares; longitud geográfica no interviene en esta referencia.
arguments
    p struct
    fecha datetime
    horas double
end
b=p.L*cosd(p.beta); H=p.L*sind(p.beta);
m.frontAzimuth=geosolarfixed.frontAzimuth(p);
w=linspace(-22.5,22.5,1801);
dec=-23.44; if p.lat<0, dec=23.44; end
[sx,sy,sz]=sunlocal(p,dec,w);
if any(sz<=0)
    error('pv:polar','La ventana de diseño incluye el Sol bajo el horizonte. Cambie la latitud.');
end
K=max(max(0,-sx./sz));
m.d=H*K; m.P=b+m.d; m.b=b; m.H=H;
m.LCR=b/m.P; m.vertices=cell(p.n,1);
for j=1:p.n
    x=(j-1)*m.P;
    m.vertices{j}=[x,-p.W/2,p.h;x+b,-p.W/2,p.h+H; ...
        x+b,p.W/2,p.h+H;x,p.W/2,p.h];
end
doy=day(fecha,'dayofyear');
dec=-23.44*cosd(360*(doy-355)/365.2422);
[sx,sy,sz]=sunlocal(p,dec,15*(horas(:)-12));
m.sun=[sx(:),sy(:),sz(:)];
m.alt=asind(sz(:)); m.az=atan2d(cosd(dec)*sind(15*(horas(:)-12)), ...
    sind(p.lat)*cosd(dec)*cosd(15*(horas(:)-12))-cosd(p.lat)*sind(dec));
m.fraccion=nan(numel(horas),p.n);
m.sombras=cell(numel(horas),p.n); m.suelo=cell(numel(horas),p.n);
normal=[-sind(p.beta),0,cosd(p.beta)];
% Ángulo firmado con el plano: positivo frontal, negativo posterior.
m.incidencia=asind(max(-1,min(1,m.sun*normal')));
m.posterior=m.alt>0 & m.incidencia<=0;
m.incidencia(m.alt<=0)=nan;
m.fraccionGeometrica=m.fraccion;
rect=polyshape([0,p.L,p.L,0],[-p.W/2,-p.W/2,p.W/2,p.W/2]);
for k=1:numel(horas)
    s=m.sun(k,:);
    if s(3)<=0, continue; end
    for j=1:p.n
        v=m.vertices{j}; g=v-v(:,3)/s(3).*s;
        m.suelo{k,j}=polyshape(g(:,1),g(:,2));
        shaded=polyshape;
        den=dot(s,normal);
        if abs(den)>1e-10
            origin=[(j-1)*m.P,0,p.h];
            for i=1:p.n
                if i==j, continue; end
                v=m.vertices{i};
                t=dot(v(1,:)-origin,normal)/den;
                if t<=1e-9, continue; end
                q=v-t*s;
                polygon=polyshape((q(:,1)-origin(1))/cosd(p.beta),q(:,2));
                shaded=union(shaded,intersect(rect,polygon));
            end
        end
        m.sombras{k,j}=shaded;
        m.fraccionGeometrica(k,j)=min(1,max(0,area(shaded)/(p.L*p.W)));
        m.fraccion(k,j)=m.fraccionGeometrica(k,j);
        if m.posterior(k),m.fraccion(k,j)=1;end
    end
end
end

function [x,y,z]=sunlocal(p,dec,w)
south=sind(p.lat)*cosd(dec).*cosd(w)-cosd(p.lat)*sind(dec);
west=cosd(dec).*sind(w);
z=sind(p.lat)*sind(dec)+cosd(p.lat)*cosd(dec).*cosd(w);
alpha=geosolarfixed.frontAzimuth(p);
x=-south*cosd(alpha)-west*sind(alpha);
y=west*cosd(alpha)-south*sind(alpha);
end
