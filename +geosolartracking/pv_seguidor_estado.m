function m = pv_seguidor_estado(p,s,P,backtracking)
% Geometría vectorizada de mesas paralelas finitas en terreno plano inclinado.
% Giro negativo: frontal hacia Este. P: paso horizontal E-O.
a=[0 cosd(p.ns) sind(p.ns)]; c=[0 -sind(p.ns) cosd(p.ns)];
sx=s(:,1); sc=s*c'; ideal=atan2d(-sx,sc);
theta=ideal;
if backtracking
    r=abs(P*(sc-tand(p.eo)*cosd(p.ns)*sx))./(p.L*hypot(sx,sc));
    correction=acosd(min(1,max(0,r)));
    slope=atand(tand(p.eo)*cosd(p.ns));
    theta=ideal-sign(ideal-slope).*correction;
end
theta=max(-p.limit,min(p.limit,theta));
night=s(:,3)<=0; theta(night)=0;
t=cosd(theta)*[1 0 0]+sind(theta)*c;
normal=-sind(theta)*[1 0 0]+cosd(theta)*c;
inc=sum(s.*normal,2);
D=[P 0 P*tand(p.eo)];
lambda=(normal*D')./inc;
q=D-lambda.*s;
du=sum(q.*t,2); dv=q*a';
shade=max(0,1-abs(du)/p.L).*max(0,1-abs(dv)/p.W);
shade(~isfinite(shade)|inc<=1e-10)=0;
terrain=s(:,3)-tand(p.eo)*s(:,1)-tand(p.ns)*s(:,2);
front=inc>0 & terrain>0 & ~night;
fraction=repmat(shade,1,p.n);
for k=1:size(s,1)
    if lambda(k)>0, fraction(k,p.n)=0; else, fraction(k,1)=0; end
end
fraction(~front,:)=1; fraction(night,:)=NaN;
m=struct('theta',theta,'ideal',ideal,'t',t,'normal',normal,'axis',a, ...
    'incidence',asind(max(-1,min(1,inc))),'cosine',max(0,inc), ...
    'fraction',fraction,'geometric',shade,'front',front,'sun',s, ...
    'shift',[du dv],'lambda',lambda,'terrain',terrain);
m.theta(night)=NaN; m.incidence(night)=NaN;
% Minimum vertical clearance for the current position (axis follows terrain).
m.clearance=p.h-p.L/2*abs(t(:,3)-tand(p.eo)*t(:,1)-tand(p.ns)*t(:,2));
end
