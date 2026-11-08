function s = pv_seguidor_solar(lat,fecha,hora)
% Vector hacia el Sol en Este, Norte, vertical. Hora solar aparente.
d=-23.44*cosd(360*(day(fecha,'dayofyear')-355)/365.2422);
w=15*(hora(:)-12); d=d(:);
s=[-cosd(d).*sind(w), ...
    cosd(lat).*sind(d)-sind(lat).*cosd(d).*cosd(w), ...
    sind(lat).*sind(d)+cosd(lat).*cosd(d).*cosd(w)];
end
