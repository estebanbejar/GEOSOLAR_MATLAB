function pv_seguidor_exportar_csv(r,archivo)
% Export the plotted samples of both annual curves, tab-separated .csv.
validateattributes(r.inverseGCR,{'numeric'},{'vector','finite','positive'});
validateattributes(r.H,{'numeric'},{'2d','finite','size',[numel(r.inverseGCR) 2]});
T=table(100./r.inverseGCR(:),r.inverseGCR(:),r.H(:,1),r.H(:,2), ...
    'VariableNames',{'GCR_porcentaje','inverso_GCR','sin_backtracking_kWh_m2_anio','con_backtracking_kWh_m2_anio'});
writetable(T,archivo,'FileType','text','Delimiter','\t','Encoding','UTF-8');
end
