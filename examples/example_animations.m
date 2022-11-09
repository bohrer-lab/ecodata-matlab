%% Test examples 
addpath ../functions/
addpath ../m_map/
addpath ../data

%% GNWT bears
% Gridded NDVI, daily resolution
% Shapefile with roads 
% Geotif with lakes 
% File with labeled points (no time constraint) 

trackfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT-ENR_Laval University Black Bear Monitoring.csv';
ncfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/NDVI_bears_daily.nc';

roads_shapefile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT_bear_roads.shp/GNWT_bear_roads.shp';
roads = containers.Map({'filename', 'LineColor', 'LineWidth'}, {roads_shapefile, 'k', 1.1});

rasterfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT_local_lakes.tif';
raster_color = [0.1294    0.6745    0.8706]; %light blue

labeled_pointsf = '/Users/jmissik/Desktop/Postdoc/Animal movement/GNWT_data/communities_location_labels.csv';

output_directory = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/output/bear_test';

start_time = datetime('2022-06-01 00:00:00');
end_time = datetime('2022-6-15 00:00:00');


track_memory = 500; % track memory

latmin = 61;
latmax = 63.7;
lonmin = -118;
lonmax = -113.7;
track_data = read_downloaded_data(trackfile);


animate_gridded_ndvi(track_data, ...
    gridded_data=ncfile, gridded_varname='_500_m_16_days_EVI', ...
    shapefile = roads('filename'), raster_image=rasterfile, ...
    raster_cmap = raster_color, labeled_pointsf=labeled_pointsf, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory, latmin=latmin, ...
    latmax = latmax, lonmin=lonmin, lonmax=lonmax, cmap='green', invert_cmap=1)

%% Without passing lat/lon limits, using defaults calculated by tracks extent
% Gridded NDVI, daily resolution
% Shapefile with roads 
% Shapefile with rivers
% Shapefile with lakes 
% File with labeled points (no time constraint) 

% Tracks
trackfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT-ENR_Laval University Black Bear Monitoring.csv';
track_memory = 500; % track memory

% Gridded data
ncfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/NDVI_bears_daily.nc';
gridded_data = containers.Map( ...
    {'filename', 'latvar', 'lonvar', 'timevar', 'var_of_interest', 'cmap', 'invert_cmap'}, ...
    {ncfile, 'lat', 'lon', 'time', '_500_m_16_days_EVI', 'green', 'true'});

% Roads shapefile 
roads_shapefile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT_bear_roads.shp/GNWT_bear_roads.shp';
roads = containers.Map({'filename', 'LineColor', 'LineWidth'}, {roads_shapefile, 'k', 1.05});

% Shapefile of lakes 
lakes_shapefile = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/GNWT_lakes_lowres_bear.shp/GNWT_lakes_lowres_bear.shp';
lakes_color = [0.1294    0.6745    0.8706]; %light blue
lakes = containers.Map( ...
    {'filename', 'FaceColor', 'EdgeColor', 'FaceAlpha'}, ...
    {lakes_shapefile, lakes_color, lakes_color, 1});

% Shapefile of rivers 
river_shapefile = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/GNWT_rivers_lowres_bear.shp/GNWT_rivers_lowres_bear.shp';
river_color = [0.1294    0.6745    0.8706]; %light blue
rivers = containers.Map( ...
    {'filename', 'LineColor', 'LineWidth'}, ...
    {river_shapefile, river_color, 1});

shapefile_stack = {lakes, rivers, roads};

% Labeled points
labeled_pointsf = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/communities_location_labels.csv';

output_directory = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/output/bear_test';

start_time = datetime('2022-06-01 00:00:00');
end_time = datetime('2022-6-15 00:00:00');



track_data = read_downloaded_data(trackfile);


animate_gridded_ndvi(track_data, ...
    gridded_data=gridded_data, ...
    shapefile_stack = shapefile_stack, ...
    labeled_pointsf=labeled_pointsf, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory);

%% Including a contour variable
% Gridded NDVI, daily resolution
% ECMWF temperature, plotted as contour 
% Shapefile with roads 
% Shapefile with rivers
% Shapefile with lakes 
% File with labeled points (no time constraint) 

% Tracks
trackfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT-ENR_Laval University Black Bear Monitoring.csv';
track_memory = 500; % track memory

% Gridded data
ncfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/NDVI_bears_daily.nc';
gridded_data = containers.Map( ...
    {'filename', 'latvar', 'lonvar', 'timevar', 'var_of_interest', 'cmap', 'invert_cmap'}, ...
    {ncfile, 'lat', 'lon', 'time', '_500_m_16_days_EVI', 'green', 'true'});

% Contour data 
contour_file = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/ECMWF_bears_daily.nc';
contour_data = containers.Map( ...
    {'filename', 'latvar', 'lonvar', 'timevar', 'var_of_interest', 'LineColor', 'LineWidth', 'LineAlpha', 'ShowText'}, ...
    {contour_file, 'latitude', 'longitude', 'time', 't2m', 'k', 0.7, 0.4, 'off'});

% Roads shapefile 
roads_shapefile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT_bear_roads.shp/GNWT_bear_roads.shp';
roads = containers.Map({'filename', 'LineColor', 'LineWidth'}, {roads_shapefile, 'k', 1.05});

% Shapefile of lakes 
lakes_shapefile = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/GNWT_lakes_lowres_bear.shp/GNWT_lakes_lowres_bear.shp';
lakes_color = [0.1294    0.6745    0.8706]; %light blue
lakes = containers.Map( ...
    {'filename', 'FaceColor', 'EdgeColor', 'FaceAlpha'}, ...
    {lakes_shapefile, lakes_color, lakes_color, 1});

% Shapefile of rivers 
river_shapefile = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/GNWT_rivers_lowres_bear.shp/GNWT_rivers_lowres_bear.shp';
river_color = [0.1294    0.6745    0.8706]; %light blue
rivers = containers.Map( ...
    {'filename', 'LineColor', 'LineWidth'}, ...
    {river_shapefile, river_color, 1});

shapefile_stack = {lakes, rivers, roads};

% Labeled points
labeled_pointsf = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/communities_location_labels.csv';

output_directory = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/output/bear_test';

start_time = datetime('2022-06-01 00:00:00');
end_time = datetime('2022-6-15 00:00:00');



track_data = read_downloaded_data(trackfile);


animate_gridded_ndvi(track_data, ...
    gridded_data=gridded_data, ...
    contour_data=contour_data, ...
    shapefile_stack = shapefile_stack, ...
    labeled_pointsf=labeled_pointsf, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory);


%% %% Including a contour variable, no roads or labeled points
% Gridded NDVI, daily resolution
% ECMWF temperature, plotted as contour 

% Tracks
trackfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT-ENR_Laval University Black Bear Monitoring.csv';
track_memory = 500; % track memory

% Gridded data
ncfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/NDVI_bears_daily.nc';
gridded_data = containers.Map( ...
    {'filename', 'latvar', 'lonvar', 'timevar', 'var_of_interest', 'cmap', 'invert_cmap'}, ...
    {ncfile, 'lat', 'lon', 'time', '_500_m_16_days_EVI', 'green', 'true'});

% Shapefile of lakes 
lakes_shapefile = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/GNWT_lakes_lowres_bear.shp/GNWT_lakes_lowres_bear.shp';
lakes_color = [0.1294    0.6745    0.8706]; %light blue
lakes = containers.Map( ...
    {'filename', 'FaceColor', 'EdgeColor', 'FaceAlpha'}, ...
    {lakes_shapefile, lakes_color, lakes_color, 1});

% Shapefile of rivers 
river_shapefile = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/GNWT_rivers_lowres_bear.shp/GNWT_rivers_lowres_bear.shp';
river_color = [0.1294    0.6745    0.8706]; %light blue
rivers = containers.Map( ...
    {'filename', 'LineColor', 'LineWidth'}, ...
    {river_shapefile, river_color, 1});

shapefile_stack = {lakes, rivers};

% Contour data 
contour_file = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/ECMWF_bears_daily.nc';
contour_color = [0.5020    0.5020    0.5020];
contour_data = containers.Map( ...
    {'filename', 'latvar', 'lonvar', 'timevar', 'var_of_interest', 'LineColor', 'LineWidth', 'ShowText'}, ...
    {contour_file, 'latitude', 'longitude', 'time', 't2m', contour_color, 0.7, 'off'});

output_directory = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/output/bear_test';

start_time = datetime('2022-06-01 00:00:00');
end_time = datetime('2022-6-15 00:00:00');



track_data = read_downloaded_data(trackfile);


animate_gridded_ndvi(track_data, ...
    gridded_data=gridded_data, ...
    contour_data=contour_data, ...
    shapefile_stack=shapefile_stack, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory);

%% GNWT bears
% Gridded NDVI, daily resolution
% Shapefile with roads 
% Shapefile with lakes 
% File with labeled points (no time constraint) 

trackfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT-ENR_Laval University Black Bear Monitoring.csv';
ncfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/NDVI_bears_daily.nc';

roads_shapefile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT_bear_roads.shp/GNWT_bear_roads.shp';
roads = containers.Map({'filename', 'LineColor', 'LineWidth'}, {roads_shapefile, 'k', 1.1});

rasterfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT_local_lakes.tif';
raster_color = [0.1294    0.6745    0.8706]; %light blue

labeled_pointsf = '/Users/jmissik/Desktop/Postdoc/Animal movement/GNWT_data/communities_location_labels.csv';

output_directory = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/output/bear_test';

start_time = datetime('2022-06-01 00:00:00');
end_time = datetime('2022-6-15 00:00:00');


track_memory = 500; % track memory

latmin = 61;
latmax = 63.7;
lonmin = -118;
lonmax = -113.7;
track_data = read_downloaded_data(trackfile);


animate_gridded_ndvi(track_data, ...
    gridded_data=ncfile, gridded_varname='_500_m_16_days_EVI', ...
    shapefile = roads('filename'), raster_image=rasterfile, ...
    raster_cmap = raster_color, labeled_pointsf=labeled_pointsf, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory, latmin=latmin, ...
    latmax = latmax, lonmin=lonmin, lonmax=lonmax, cmap='green', invert_cmap=1)


%%
ncfile = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/ECMWF_bears_daily.nc';

netcdf_time = ncread(ncfile, 'time');
nc_lat = ncread(ncfile, 'latitude');
nc_lon = ncread(ncfile, 'longitude');
nc_var = ncread(ncfile, 't2m');
[LAT,LON] = meshgrid(nc_lat(:,1), nc_lon(:,1));

timestamp = datetime(datevec(double(netcdf_time)/24 + datenum('1900-01-01 00:00:00')));


latmin = 61;
latmax = 64;
lonmin = -118;
lonmax = -113.7;

% Projection
figure()
m_proj('Cylindrical Equal-Area','lat',[latmin latmax],'long',[lonmin lonmax])

m_contour(LON, LAT, nc_var(:,:,1), 'ShowText','on', 'LineWidth', 2, 'alpha', 0.2)
m_grid()


%%
trackfile = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/GNWT_data/bears_with_ref.csv';
track_data = read_downloaded_data(trackfile);

marker = '/Users/jmissik/Desktop/Postdoc/Animal movement/gifmarker/caribou.gif';

latmin = 61;
latmax = 64;
lonmin = -118;
lonmax = -113.7;

% Projection
figure()
m_proj('Cylindrical Equal-Area','lat',[latmin latmax],'long',[lonmin lonmax])
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 3);

track_data = track_data(1:6,:);
x = track_data.location_long;
y = track_data.location_lat;
g = track_data.animal_sex;
l = m_scatter(x,y);
% gifmarkers(l, marker, 'Size', 5)
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 3);


