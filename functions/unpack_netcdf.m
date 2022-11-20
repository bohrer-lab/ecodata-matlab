function [lat, lon, time, var] = unpack_netcdf(filename,latvar, lonvar, timevar, var_of_interest, kwargs)
% Unpack netcdf file containing lat, long, time, and a variable of interest
% Option to read just a chunk of time 
arguments 
    filename
    latvar
    lonvar
    timevar
    var_of_interest
    kwargs.start = 1
    kwargs.count = Inf
end

    % Get dimension info 
    dim_info = struct2table(ncinfo(filename).Dimensions);
    ndims = height(dim_info);
    
    % Get index of time dimension
    tind = find(strcmp(dim_info.Name, timevar));
    
    % Set up arrays for start and count 
    start_array = ones(1, ndims);
    count_array = ones(1, ndims);
    count_array(:) = Inf;
    start_array(tind) = kwargs.start;
    count_array(tind) = kwargs.count;

    % Read lat and lon 
    lat = ncread(filename, latvar);
    lon = ncread(filename, lonvar);
    
    % Read a chunk
    time = read_nc_timestamps(filename, timevar, start=kwargs.start, count=kwargs.count);
    var = ncread(filename, var_of_interest, start_array, count_array);

end