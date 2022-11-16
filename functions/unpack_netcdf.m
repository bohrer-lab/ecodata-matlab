function [lat, lon, time, var] = unpack_netcdf(filename,latvar, lonvar, timevar, var_of_interest)
% Unpack netcdf file containing lat, long, time, and a variable of interest


    lat = ncread(filename, latvar);
    lon = ncread(filename, lonvar);
    var= ncread(filename, var_of_interest);
    time = read_nc_timestamps(filename, timevar);

end