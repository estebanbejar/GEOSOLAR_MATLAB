function et=equationOfTime(t)
% NOAA annual harmonic approximation, minutes: apparent minus mean solar time.
% t is fractional day since January 1; annual curve evaluated at nominal noon.
validateattributes(t,{'numeric'},{'real','finite'});
g=2*pi*t/365;
et=229.18*(.000075+.001868*cos(g)-.032077*sin(g)...
    -.014615*cos(2*g)-.040849*sin(2*g));
end
