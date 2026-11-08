function delta = declination(n)
%DECLINATION Didactic approximation, fixed non-leap year 2026.
validateattributes(n,{'numeric'},{'real','finite','integer','>=',1,'<=',365});
delta = 23.45*sind(360*(284+n)/365);
end
