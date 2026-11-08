function s=state(t)
%STATE Didactic Kepler orbit. t: days since Jan 1, 2026 (fractional allowed).
% One idealized year is exactly 365 days; perihelion is t=2 (Jan 3).
validateattributes(t,{'numeric'},{'real','finite'});
e=.0167; period=365; epsilon=23.44;
M=2*pi*(t-2)/period;
E=M;
for j=1:8, E=E-(E-e*sin(E)-M)./(1-e*cos(E)); end
s.position=[reshape(cos(E)-e,1,[]);reshape(sqrt(1-e^2)*sin(E),1,[]);zeros(1,numel(t))];
s.distance=sqrt(sum(s.position.^2,1));
s.sunDirection=-s.position./s.distance;
% Fix the axis so the model's March equinox is March 20 (t=78).
marchM=2*pi*(78-2)/period; marchE=marchM;
for j=1:8, marchE=marchE-(marchE-e*sin(marchE)-marchM)/(1-e*cos(marchE)); end
marchNu=atan2(sqrt(1-e^2)*sin(marchE),cos(marchE)-e);
s.axisLongitude=marchNu-pi/2;
s.axis=[sind(epsilon)*cos(s.axisLongitude);sind(epsilon)*sin(s.axisLongitude);cosd(epsilon)];
s.declination=asind(max(-1,min(1,s.axis'*s.sunDirection)));
s.declination(abs(s.declination)<1e-12)=0;
s.speedRelative=sqrt(2./s.distance-1);
s.meanAnomaly=M; s.eccentricAnomaly=E; s.eccentricity=e;
s.obliquity=epsilon; s.period=period;
end
