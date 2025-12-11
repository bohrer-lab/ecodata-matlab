function cm = resolve_cmap(label_or_map, N)
%RESOLVE_CMAP Wrapper over s_resolve_cmap to maintain backward compatibility.
% Supports:
% - project map names ('green','blue','diverging',...),
% - directly Nx3 arrays.
%
% label_or_map – either a string with a name, or an Nx3 double.
% N – number of colors (default 256).

    if nargin < 2 || isempty(N)
        N = 256;
    end

    cm = s_resolve_cmap(label_or_map, N);
end
