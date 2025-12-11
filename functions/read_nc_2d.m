function [lat, lon, field2d] = read_nc_2d(filename, latvar, lonvar, varname)
%READ_NC_2D Read a 2-D (lat,lon) field from NetCDF.
% Tries to robustly map the NetCDF variable to a [nlat x nlon] matrix,
% handling the following common layouts:
%   - var(lat,lon)
%   - var(lon,lat)
%   - var(time,lat,lon)
%   - var(lat,lon,time)
%   - var(lon,lat,time)
%
% For true 3-D variables (time > 1), the FIRST time slice is used.
%
% NOTE: This function does NOT currently honour any UI time selection.
% It is aimed at "static" use-cases where a single snapshot is enough.

    % 1) Read coordinate vectors 
    lat = ncread(filename, latvar);
    lon = ncread(filename, lonvar);

    % Ensure column vectors
    lat = lat(:);
    lon = lon(:);

    nlat = numel(lat);
    nlon = numel(lon);

    % 2) Read the variable 
    var = ncread(filename, varname);
    var = squeeze(var);
    sz  = size(var);
    nd  = ndims(var);

    if nd == 2

        % Pure 2-D case
        if isequal(sz, [nlat, nlon])
            field2d = var;
        elseif isequal(sz, [nlon, nlat])
            field2d = var.';   % transpose to [lat x lon]
        else
            error('read_nc_2d:SizeMismatch', ...
                'After squeeze: size(var)=[%d %d], but numel(lat)=%d, numel(lon)=%d', ...
                sz(1), sz(2), nlat, nlon);
        end

    elseif nd == 3

        % 3-D case: assume one dimension is time.
        % find the lat and lon dimensions by matching sizes,
        % then treat the remaining dimension as time and take the first slice.

        dims = sz;

        % Find indices whose length matches lat / lon
        idx_lat = find(dims == nlat, 1, 'first');
        idx_lon = find(dims == nlon, 1, 'first');

        if isempty(idx_lat) || isempty(idx_lon) || idx_lat == idx_lon
            error('read_nc_2d:LatLonNotFound', ...
                ['Could not identify latitude/longitude dimensions in %s. ', ...
                 'size(var)=[%s], nlat=%d, nlon=%d'], ...
                varname, num2str(dims), nlat, nlon);
        end

        % The remaining dimension is treated as time
        all_idx  = 1:3;
        idx_time = setdiff(all_idx, [idx_lat, idx_lon]);

        % Safety check
        if numel(idx_time) ~= 1
            error('read_nc_2d:AmbiguousTimeDim', ...
                'Ambiguous time dimension for variable %s with size=[%s]', ...
                varname, num2str(dims));
        end

        % Permute so that the array becomes [lat x lon x time]
        % i.e. dimensions: (lat, lon, time)
        perm_order = [idx_lat, idx_lon, idx_time];
        var_pl = permute(var, perm_order);   % size ~ [nlat x nlon x ntime]

        % Take the FIRST time slice
        field2d = var_pl(:, :, 1);

    else
        % More than 3 dimensions – not supported here
        error('read_nc_2d:Not2Dor3D', ...
            'Variable "%s" has ndims=%d after squeeze; only 2-D or 3-D supported.', ...
            varname, nd);
    end

    % 4) Ensure latitude ascending 
    if nlat > 1 && lat(1) > lat(end)
        lat     = flipud(lat);
        field2d = flipud(field2d);
    end


end

