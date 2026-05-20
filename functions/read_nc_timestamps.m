function nc_timestamp = read_nc_timestamps(nc_filename, timevar, kwargs)
%READ_NC_TIMESTAMPS Read NetCDF time variable and convert to datetime.
%
% Stable hybrid version:
% - preserves old simple behavior for common legacy cases
% - supports generic CF-style time units
% - avoids fragile assumptions about variable dimensions
%
% Supported examples:
%   hours since 1900-01-01 00:00:00
%   days since 2000-01-01 00:00:00
%   seconds since 1970-01-01 00:00:00
%   hours since 2015-07-01T00:00:00Z
%   days since 1990-01-01

    arguments
        nc_filename
        timevar
        kwargs.start (1,1) double {mustBeInteger,mustBePositive} = 1
        kwargs.count (1,1) double = Inf
    end

    % Validate variable existence
    info = ncinfo(nc_filename);
    var_names = string({info.Variables.Name});

    if ~any(var_names == string(timevar))
        error('read_nc_timestamps:TimeVariableNotFound', ...
            'Time variable "%s" not found in file: %s', timevar, nc_filename);
    end

    % Read full numeric time vector first.
    % This is safer than trying to infer start/count from guessed dimensions.
    netcdf_time = double(ncread(nc_filename, timevar));
    netcdf_time = netcdf_time(:);

    n = numel(netcdf_time);

    if kwargs.start > n
        error('read_nc_timestamps:InvalidStart', ...
            'Requested start=%d exceeds available time length=%d.', ...
            kwargs.start, n);
    end

    if isinf(kwargs.count)
        idx_end = n;
    else
        idx_end = min(n, kwargs.start + kwargs.count - 1);
    end

    netcdf_time = netcdf_time(kwargs.start:idx_end);

    % Read units
    try
        time_units = ncreadatt(nc_filename, timevar, 'units');
    catch
        error('read_nc_timestamps:MissingUnits', ...
            'Time variable "%s" has no "units" attribute in file: %s', ...
            timevar, nc_filename);
    end

    time_units = char(time_units);
    time_units_trim = strtrim(time_units);

    % Legacy explicit cases first (same idea as old stable version)
    if startsWith(time_units_trim, 'hours since 1900-01-01', 'IgnoreCase', true)
        base_time = datetime(1900,1,1,0,0,0);
        nc_timestamp = base_time + hours(netcdf_time);
        return
    end

    if startsWith(time_units_trim, 'days since 2000-01-01', 'IgnoreCase', true)
        base_time = datetime(2000,1,1,0,0,0);
        nc_timestamp = base_time + days(netcdf_time);
        return
    end

    % Generic CF-style parser
    expr = '^\s*(seconds|minutes|hours|days)\s+since\s+(.+?)\s*$';
    tok = regexp(time_units_trim, expr, 'tokens', 'once');

    if isempty(tok)
        error('read_nc_timestamps:UnsupportedTimeUnits', ...
            'Unsupported time units for variable "%s": %s', timevar, time_units_trim);
    end

    unit_name = lower(strtrim(tok{1}));
    base_str  = strtrim(tok{2});

    % Normalize common variants
    base_str = strrep(base_str, 'T', ' ');
    base_str = regexprep(base_str, 'Z$', '+00:00');

    % Fix odd second formatting like 00:00:0.0 -> 00:00:00.0
    base_str = regexprep(base_str, ...
        '(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:)(\d)(\.\d+)?$', ...
        '$10$2$3');

    dt_formats = { ...
        'yyyy-MM-dd HH:mm:ss.SSSXXX', ...
        'yyyy-MM-dd HH:mm:ssXXX', ...
        'yyyy-MM-dd HH:mm:ss.SSS', ...
        'yyyy-MM-dd HH:mm:ss', ...
        'yyyy-MM-dd HH:mmXXX', ...
        'yyyy-MM-dd HH:mm', ...
        'yyyy-MM-dd' ...
    };

    base_time = NaT;

    for k = 1:numel(dt_formats)
        try
            if contains(base_str, '+') || contains(base_str, 'Z')
                base_time = datetime(base_str, ...
                    'InputFormat', dt_formats{k}, ...
                    'TimeZone', 'UTC');
            else
                base_time = datetime(base_str, ...
                    'InputFormat', dt_formats{k});
            end

            if ~isnat(base_time)
                break
            end
        catch
        end
    end

    if isnat(base_time)
        error('read_nc_timestamps:BaseTimeParseFailed', ...
            'Could not parse base time from units "%s".', time_units_trim);
    end

    switch unit_name
        case 'seconds'
            nc_timestamp = base_time + seconds(netcdf_time);
        case 'minutes'
            nc_timestamp = base_time + minutes(netcdf_time);
        case 'hours'
            nc_timestamp = base_time + hours(netcdf_time);
        case 'days'
            nc_timestamp = base_time + days(netcdf_time);
        otherwise
            error('read_nc_timestamps:UnsupportedUnit', ...
                'Unsupported time unit "%s" in units "%s".', unit_name, time_units_trim);
    end

    % Return timezone-naive datetime for compatibility with existing code
    try
        nc_timestamp.TimeZone = '';
    catch
    end
end