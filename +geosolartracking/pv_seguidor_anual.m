function r = pv_seguidor_anual(p,met,ratios)
% kWh/m2 of module front surface per TMY. Isotropic sky, albedo 0.2.
% Finite aligned rows; diffuse/reflected masking by rows is not modelled.
if nargin<3,ratios=linspace(1,10,55);end
validateattributes(ratios,{'numeric'},{'vector','finite','>=',1});
H=zeros(numel(ratios),2);
for i=1:numel(ratios)
    for b=0:1
        m=geosolartracking.pv_seguidor_estado(p,met.sun,p.L*ratios(i),logical(b));
        loss=mean(m.fraction,2);loss(~isfinite(loss))=1;
        beam=met.dni.*m.cosine.*(1-loss);
        nz=m.normal(:,3);
        diffuse=met.dhi.*(1+nz)/2;
        reflected=0.2*met.ghi.*(1-nz)/2;
        total=beam+diffuse+reflected;
        total(met.sun(:,3)<=0)=0;
        H(i,b+1)=sum(total)/1000;
    end
end
r=struct('inverseGCR',ratios(:),'H',H);
end
