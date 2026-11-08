function controls=datePresets(parent,getDate,setDate)
% Selector docente reutilizable por los laboratorios de instalaciones.
root=uigridlayout(parent,[2 1]);root.Padding=[0 0 0 0];root.RowSpacing=3;root.RowHeight={30,0};
row=uigridlayout(root,[1 3]);row.Padding=[0 0 0 0];row.ColumnSpacing=3;
controls.December=uibutton(row,'Text','21 diciembre','FontSize',10,'ButtonPushedFcn',@(~,~)choose(12,21));
controls.June=uibutton(row,'Text','21 junio','FontSize',10,'ButtonPushedFcn',@(~,~)choose(6,21));
controls.Toggle=uibutton(row,'Text','Equinoccios ▾','FontSize',10,'ButtonPushedFcn',@toggle);
dates=uigridlayout(root,[1 2]);dates.Padding=[0 0 0 0];dates.Visible='off';
controls.March=uibutton(dates,'Text','20 marzo','FontSize',10,'ButtonPushedFcn',@(~,~)choose(3,20));
controls.September=uibutton(dates,'Text','22 septiembre','FontSize',10,'ButtonPushedFcn',@(~,~)choose(9,22));
controls.Root=root;controls.EquinoxDates=dates;
for button=[controls.December controls.June controls.March controls.September]
    button.Tooltip='Fecha de referencia didáctica; conserva el año seleccionado.';
end
    function choose(month,day)
        current=datetime(getDate(),'InputFormat','yyyy-MM-dd');
        selected=datetime(year(current),month,day);setDate(char(string(selected,'yyyy-MM-dd')));
    end
    function toggle(~,~)
        open=strcmp(dates.Visible,'off');dates.Visible=open;
        heights=parent.RowHeight;
        if open,root.RowHeight={30,30};heights{root.Layout.Row}=66;controls.Toggle.Text='Equinoccios ▴';
        else,root.RowHeight={30,0};heights{root.Layout.Row}=32;controls.Toggle.Text='Equinoccios ▾';end
        parent.RowHeight=heights;
    end
end
