function events=events
% Event dates derived from this same geometric model, not external ephemerides.
s=geosolarorbit.state(0); beta=s.axisLongitude; e=s.eccentricity;
nu=beta+[pi/2 pi 3*pi/2 0];
E=atan2(sqrt(1-e^2)*sin(nu),e+cos(nu));
t=mod(2+(E-e*sin(E))*365/(2*pi),365);
events.time=[t 2 184.5];
events.names={'Equinoccio de marzo','Solsticio de junio','Equinoccio de septiembre',...
    'Solsticio de diciembre','Perihelio','Afelio'};
events.short={'Marzo','Junio','Septiembre','Diciembre','Perihelio','Afelio'};
end
