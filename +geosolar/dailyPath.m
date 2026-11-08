function path = dailyPath(phi,delta)
%DAILYPATH Columns are samples; exact horizon crossings added to 1 deg grid.
validateattributes(phi,{'numeric'},{'scalar'});
validateattributes(delta,{'numeric'},{'scalar'});
d=geosolar.daylight(phi,delta);
w=-180:180;
if isfinite(d.sunrise)
    w=unique([w 15*(d.sunrise-12) 15*(d.sunset-12)]);
end
p=geosolar.position(phi,delta,12+w/15);
path.xyz=[p.E;p.N;p.U]; path.omega=w;
path.visible=path.xyz; path.night=path.xyz;
path.visible(:,p.U< -1e-10)=NaN;
path.night(:,p.U>1e-10)=NaN;
end
