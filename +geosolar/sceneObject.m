function h=sceneObject(ax,kind,varargin)
% Reuse the same graphic handles in deterministic scene traversal order.
cache=getappdata(ax,'gsObjects');
i=getappdata(ax,'gsIndex')+1; setappdata(ax,'gsIndex',i);
if i>numel(cache)
    h=feval(kind,ax,varargin{:}); cache{i}=h;
    setappdata(ax,'gsObjects',cache);
    return
end
h=cache{i};
switch kind
    case {'plot','line'}
        set(h,'XData',varargin{1},'YData',varargin{2});
    case {'plot3','surf','patch'}
        set(h,'XData',varargin{1},'YData',varargin{2},'ZData',varargin{3});
    case 'text'
        if isnumeric(varargin{3})
            set(h,'Position',[varargin{1:3}],'String',varargin{4});
        else
            set(h,'Position',[varargin{1:2} 0],'String',varargin{3});
        end
end
end
