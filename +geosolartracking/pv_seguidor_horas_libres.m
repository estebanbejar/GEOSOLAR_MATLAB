function h = pv_seguidor_horas_libres(p,fecha,P,backtracking)
% Total daily hours with direct sun and no shade on ANY row.
% One-minute midpoint quadrature in solar time, independent of display zone.
t=((0:1439)+0.5)/60;
m=geosolartracking.pv_seguidor_estado(p,geosolartracking.pv_seguidor_solar(p.lat,fecha,t),P,backtracking);
free=m.front & all(m.fraction<=1e-8,2);
h=sum(free)/60;
end
