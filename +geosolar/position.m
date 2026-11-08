function p = position(phi,delta,time)
%POSITION Angles in degrees; arrays use MATLAB implicit expansion.
validateattributes(phi,{'numeric'},{'real','finite','>=',-90,'<=',90});
validateattributes(delta,{'numeric'},{'real','finite','>=',-23.45,'<=',23.45});
validateattributes(time,{'numeric'},{'real','finite','>=',0,'<=',24});
p.omega = 15*(time-12);
p.E = -cosd(delta).*sind(p.omega);
p.N = cosd(phi).*sind(delta)-sind(phi).*cosd(delta).*cosd(p.omega);
p.U = sind(phi).*sind(delta)+cosd(phi).*cosd(delta).*cosd(p.omega);
p.E = p.E + zeros(size(p.U));
p.horizontalNorm = hypot(p.E,p.N);
p.alpha = atan2d(p.U,p.horizontalNorm);
p.gamma = atan2d(-p.E,-p.N);
p.gamma(p.horizontalNorm < 1e-10) = NaN;
p.conventionalFrame = abs(phi)==90;
p.status = repmat("rasante",size(p.U));
p.status(p.U>1e-10) = "sobre el horizonte";
p.status(p.U< -1e-10) = "bajo el horizonte";
end
