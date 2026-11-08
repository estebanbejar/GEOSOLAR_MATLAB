function d = pv_seguidor_diseno(p,gcr)
% Paso conservador de filas largas, invierno 10:30 a 13:30 solar.
% Optional gcr (fraction, not percent) selects a manual horizontal pitch.
if nargin<2,gcr=[];end
validateattributes(p.lat,{'numeric'},{'scalar','finite','>=',-65,'<=',65});
for name={'L','W','h'}, validateattributes(p.(name{1}),{'numeric'},{'scalar','positive','finite'}); end
validateattributes(p.n,{'numeric'},{'scalar','integer','>=',1,'<=',30});
validateattributes(p.limit,{'numeric'},{'scalar','finite','>=',0,'<=',90});
for name={'ns','eo'}, validateattributes(p.(name{1}),{'numeric'},{'scalar','finite','>=',-45,'<=',45}); end
if isempty(gcr)
dec=-23.44; if p.lat<0, dec=23.44; end
w=linspace(-22.5,22.5,1801)';
s=[-cosd(dec)*sind(w),cosd(p.lat)*sind(dec)-sind(p.lat)*cosd(dec)*cosd(w), ...
    sind(p.lat)*sind(dec)+cosd(p.lat)*cosd(dec)*cosd(w)];
c=[0 -sind(p.ns) cosd(p.ns)]; sc=s*c';
den=sc-tand(p.eo)*cosd(p.ns)*s(:,1);
if any(s(:,3)<=0 | den<=1e-8)
    error('pv:diseno','El Sol queda bajo el horizonte o detrás del terreno en la ventana de invierno.');
end
theta=max(-p.limit,min(p.limit,atan2d(-s(:,1),sc)));
P=max(p.L,max(p.L*abs(cosd(theta).*sc-sind(theta).*s(:,1))./den));
else
    validateattributes(gcr,{'numeric'},{'scalar','finite','positive','<=',1});
    P=p.L/gcr;
end
d=struct('P',P,'GCR',p.L/P);
% Check full mechanical range, independent of date/backtracking.
g=linspace(-p.limit,p.limit,1801);
clearance=p.h-p.L/2*abs(sind(g)/cosd(p.ns)-tand(p.eo)*cosd(g));
d.clearance=min(clearance);
if d.clearance<=0
    error('pv:suelo','Los módulos interceptan el terreno. Aumente la altura del soporte (mínimo > %.2f m).',p.h-d.clearance);
end
end
