function [local,R] = equatorialToLocal(phi,equatorial)
% Columns are vectors: equatorial [X;Y;Z], local [E;N;U].
validateattributes(phi,{'numeric'},{'scalar','real','finite','>=',-90,'<=',90});
validateattributes(equatorial,{'numeric'},{'2d','nrows',3,'real','finite'});
R = [0 1 0;-sind(phi) 0 cosd(phi);cosd(phi) 0 sind(phi)];
local = R*equatorial;
end
