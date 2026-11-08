function h=meridianObject(ax,kind,x,z,varargin)
% Embed the latitude diagram in the equatorial XZ meridian plane (Y=0).
if strcmp(kind,'text')
    h=geosolar.sceneObject(ax,'text',x,0,z,varargin{:});
else
    h=geosolar.sceneObject(ax,'plot3',x,zeros(size(x)),z,varargin{:});
end
end
