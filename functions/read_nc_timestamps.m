function nc_timestamp = read_nc_timestamps(nc_filename, timevar, kwargs)
    % Checks the time format of the dataset, and produces a datetime
    % accordingly 
    % Checks for ECMWF format and NASA format
    % Other options not yet supported 
    arguments
        nc_filename
        timevar
        kwargs.start = 1
        kwargs.count = Inf
    end

    % Get dimension info 
    dim_info = struct2table(ncinfo(nc_filename).Dimensions);
    ndims = height(dim_info);
    
    % Get index of time dimension
    tind = find(strcmp(dim_info.Name, timevar));

    % Get max index for time dimension
    tind_max = dim_info.Length(tind);

    % Read the time metadata 
    time_units = ncreadatt(nc_filename, timevar, 'units');

    if kwargs.start + kwargs.count > tind_max
        kwargs.count = Inf;
    end

    netcdf_time = ncread(nc_filename, timevar, kwargs.start, kwargs.count);

    % ECMWF format 
    if startsWith(time_units, 'hours since 1900-01-01')
        nc_timestamp = datetime(datevec(double(netcdf_time)/24 + datenum('1900-01-01 00:00:00')));

    % NASA format 
    elseif startsWith(time_units, 'days since 2000-01-01')
        nc_timestamp = datetime(datevec(double(netcdf_time + datenum('2000-01-01 00:00:00'))));
    
    end
end
