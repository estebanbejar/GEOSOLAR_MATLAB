function m = pv_este_oeste_modelo(p, fecha, horas)
% Conjuntos simétricos: x hacia Oeste y eje y hacia Sur cuando alpha=0.
% alpha gira el conjunto desde N-S; caras con acimuts alpha-90 y alpha+90.
arguments
    p struct
    fecha datetime
    horas double
end
validateattributes(p.beta,{'numeric'},{'scalar','>=',0,'<=',90});
validateattributes(p.d,{'numeric'},{'scalar','nonnegative','finite'});
validateattributes(p.n,{'numeric'},{'scalar','integer','positive'});
validateattributes(p.L,{'numeric'},{'scalar','positive','finite'});
validateattributes(p.W,{'numeric'},{'scalar','positive','finite'});
m.gap=.05; m.b=p.L*cosd(p.beta);m.H=p.L*sind(p.beta);
m.width=2*m.b+m.gap;m.d=p.d;m.P=m.width+p.d;
m.LCR=2*m.b/m.P;m.vertices=cell(2*p.n,1);
m.origins=zeros(2*p.n,3);m.tangents=zeros(2*p.n,3);
for j=1:p.n
    x=(j-1)*m.P;
    for face=1:2
        k=2*j-2+face;direction=3-2*face;
        origin=[x+(face-1)*m.width,0,p.h];
        tangent=[direction*cosd(p.beta),0,sind(p.beta)];
        m.origins(k,:)=origin;m.tangents(k,:)=tangent;
        m.vertices{k}=origin+[0,-p.W/2,0;0,p.W/2,0; ...
            p.L*tangent+[0,p.W/2,0];p.L*tangent+[0,-p.W/2,0]];
    end
end
doy=day(fecha,'dayofyear');dec=-23.44*cosd(360*(doy-355)/365.2422);
w=15*(horas(:)-12);
south=sind(p.lat)*cosd(dec).*cosd(w)-cosd(p.lat)*sind(dec);
west=cosd(dec).*sind(w);z=sind(p.lat)*sind(dec)+cosd(p.lat)*cosd(dec).*cosd(w);
a=p.alpha-90;
m.sun=[-south*cosd(a)-west*sind(a),west*cosd(a)-south*sind(a),z];
m.alt=asind(z);m.az=atan2d(west,south);
normals=[-sind(p.beta),0,cosd(p.beta);sind(p.beta),0,cosd(p.beta)];
m.incidencia=asind(max(-1,min(1,m.sun*normals')));
m.posterior=m.alt>0 & m.incidencia<=1e-10;
m.incidencia(m.alt<=0,:)=nan;
m.fraccion=nan(numel(horas),2*p.n);m.fraccionGeometrica=m.fraccion;
m.sombras=cell(numel(horas),2*p.n);m.suelo=m.sombras;
rect=polyshape([0,p.L,p.L,0],[-p.W/2,-p.W/2,p.W/2,p.W/2]);
for t=1:numel(horas)
    if m.alt(t)<=0,continue;end
    s=m.sun(t,:);
    for k=1:2*p.n
        v=m.vertices{k};g=v-v(:,3)/s(3).*s;
        m.suelo{t,k}=polyshape;
        if polyarea(g(:,1),g(:,2))>1e-10
            m.suelo{t,k}=polyshape(g(:,1),g(:,2));
        end
        face=mod(k-1,2)+1;normal=normals(face,:);den=dot(s,normal);
        shaded=polyshape;origin=m.origins(k,:);
        if den>1e-10
            for i=1:2*p.n
                if i==k,continue;end
                v=m.vertices{i};distance=(v-origin)*normal'/den;
                % Clip blockers to the sunward half-space before projection.
                clipped=zeros(0,3);
                for q=1:size(v,1)
                    r=mod(q,size(v,1))+1;d1=distance(q);d2=distance(r);
                    if d1>1e-9,clipped(end+1,:)=v(q,:);end %#ok<AGROW>
                    if (d1>1e-9)~=(d2>1e-9)
                        clipped(end+1,:)=v(q,:)+(1e-9-d1)/(d2-d1)*(v(r,:)-v(q,:)); %#ok<AGROW>
                    end
                end
                if size(clipped,1)<3,continue;end
                ray=(clipped-origin)*normal'/den;
                projected=clipped-ray.*s-origin;
                u=projected*m.tangents(k,:)';y=projected(:,2);
                if polyarea(u,y)<1e-12,continue;end
                polygon=polyshape(u,y);
                shaded=union(shaded,intersect(rect,polygon));
            end
        end
        m.sombras{t,k}=shaded;
        m.fraccionGeometrica(t,k)=min(1,max(0,area(shaded)/(p.L*p.W)));
        m.fraccion(t,k)=m.fraccionGeometrica(t,k);
        if m.posterior(t,face),m.fraccion(t,k)=1;end
    end
end
end
