function az=frontAzimuth(p)
% Desvío respecto al ecuador: base Sur en HN y Norte en HS.
az=p.alpha;
if p.lat<0,az=az+180;end
end
