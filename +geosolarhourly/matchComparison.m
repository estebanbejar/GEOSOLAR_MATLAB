function [values,stamps]=matchComparison(times,points,mode)
% Solo identificación del registro cercano para el tooltip; no remuestrea.
values=nan(size(times));stamps=NaT(size(times),'TimeZone','UTC');
if isempty(points),return;end
if strcmp(mode,'hourly')
    target=posixtime(times);source=posixtime(points.Time);edges=[-Inf;(source(1:end-1)+source(2:end))/2;Inf];
    index=discretize(target,edges,'IncludedEdge','right');valid=abs(target-source(index))<=3600;
else
    [valid,index]=ismember(times,points.Time);
end
values(valid)=points.Global(index(valid));stamps(valid)=points.Time(index(valid));
end
