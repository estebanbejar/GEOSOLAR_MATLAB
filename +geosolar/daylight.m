function d = daylight(phi,delta)
%DAYLIGHT Vectorized regime classification; tolerance in unit solar U.
geosolar.position(phi,delta,12); % Shared input validation.
a = sind(phi).*sind(delta); b = cosd(phi).*cosd(delta);
a = a+zeros(size(b)); b = b+zeros(size(a)); tol = 1e-10;
d.hours = nan(size(a)); d.sunrise = d.hours; d.sunset = d.hours;
d.regime = repmat("ordinario",size(a));
for k=1:numel(a)
    if a(k)-b(k)>tol
        d.hours(k)=24; d.regime(k)="día polar";
    elseif a(k)+b(k)<-tol
        d.hours(k)=0; d.regime(k)="noche polar";
    elseif abs(b(k))<=tol
        d.regime(k)="rasante permanente";
    else
        w=acosd(max(-1,min(1,-a(k)/b(k))));
        d.hours(k)=2*w/15;
        d.sunrise(k)=12-w/15; d.sunset(k)=12+w/15;
        if abs(a(k)-b(k))<=tol
            d.regime(k)="contacto tangencial a medianoche";
        elseif abs(a(k)+b(k))<=tol
            d.regime(k)="contacto tangencial al mediodía";
        end
    end
end
end
