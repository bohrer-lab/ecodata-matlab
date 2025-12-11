function cm = s_resolve_cmap(label_or_map, N)
% Convert a colormap label or Nx3 array into a valid Nx3 colormap

    if nargin < 2 || isempty(N), N = 256; end

    if isnumeric(label_or_map)
        cm = label_or_map;    % already Nx3
        return
    end

    name = lower(char(string(label_or_map)));

    % 1) Try project generator (as used in Gridded Colormap)
    try
        cm = s_colmap(name, N);
        return
    catch
        % continue
    end

    % 2) Try MATLAB built-ins
    try
        cm = feval(name, N);
        return
    catch
        % continue
    end

    % 3) Fallback
    warning('s_resolve_cmap:unknown', ...
        'Unrecognized colormap "%s". Using parula(%d).', name, N);
    cm = parula(N);
end