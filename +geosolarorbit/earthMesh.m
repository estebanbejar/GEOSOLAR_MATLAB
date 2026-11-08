function [xyz,rgb]=earthMesh(axisVector,sunDirection)
% Fixed geographical mesh; direct RGB shading from the physical solar vector.
% Daily spin is intentionally omitted in this annual-motion dashboard.
[x,y,z]=sphere(40);
u=cross([0;1;0],axisVector); u=u/norm(u); v=cross(axisVector,u);
xyz=[u v axisVector]*[x(:)';y(:)';z(:)'];
illum=max(0,sunDirection'*xyz);
brightness=.18+.82*illum;
rgb=zeros([size(x),3]);
base=[.24 .59 .84];
for k=1:3, rgb(:,:,k)=reshape(base(k)*brightness,size(x)); end
xyz=reshape(xyz,3,size(x,1),size(x,2));
end
