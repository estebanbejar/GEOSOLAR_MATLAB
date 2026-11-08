function modes=resolutionModes(startDate,endDate)
% Fechas inclusivas: un mes/año se mide por calendario, también en bisiestos.
startDate=datetime(year(startDate),month(startDate),day(startDate));
endDate=datetime(year(endDate),month(endDate),day(endDate));modes={};
if isnat(startDate)||isnat(endDate)||endDate<startDate,return;end
if days(endDate-startDate)<31,modes={'hourly'};end
modes{end+1}='daily';
if endDate+caldays(1)>=startDate+calmonths(1),modes{end+1}='monthly';end
if endDate+caldays(1)>=startDate+calyears(1),modes{end+1}='yearly';end
end
