% Test examples for animation function 
% Current working directory should be movebank_vis

%% Setup
% Current directory should be movebank_vis
addpath(genpath('functions'))
addpath(genpath('m_map'))
addpath(genpath('data'))

% Files 
trackfile = get_fullpath('bears_with_ref.csv');
ncfile = get_fullpath('NDVI_bears_daily.nc');
roads_shapefile = get_fullpath('GNWT_bear_roads.shp');
lakes_shapefile = get_fullpath('GNWT_lakes_lowres_bear.shp');
river_shapefile = get_fullpath('GNWT_rivers_lowres_bear.shp');
lakes_rasterfile = get_fullpath('GNWT_local_lakes.tif');
labels_file = get_fullpath('communities_location_labels.csv');

% Gridded NDVI data
ndvi_data = containers.Map( ...
    {'filename', 'latvar', 'lonvar', 'timevar', 'var_of_interest', 'cmap', 'invert_cmap'}, ...
    {ncfile, 'lat', 'lon', 'time', '_500_m_16_days_NDVI', 'green', 'true'});

% Shapefile of lakes 
lakes_color = [0.1294    0.6745    0.8706]; %light blue
lakes = containers.Map( ...
    {'filename', 'FaceColor', 'EdgeColor', 'FaceAlpha'}, ...
    {lakes_shapefile, lakes_color, lakes_color, 1});

% Shapefile of rivers 
river_color = [0.1294    0.6745    0.8706]; %light blue
rivers = containers.Map( ...
    {'filename', 'LineColor', 'LineWidth'}, ...
    {river_shapefile, river_color, 1});

% Shapefile of roads 
roads = containers.Map({'filename', 'LineColor', 'LineWidth'}, ...
                       {roads_shapefile, 'k', 1.1});

% Labeled points
label_data = containers.Map({'filename', 'marker_color', 'marker_size'}, ...
                            {labels_file, 'k', 10});

% Contour data 
contour_file = get_fullpath('ECMWF_bears_daily.nc');
contour_data = containers.Map( ...
    {'filename', 'latvar', 'lonvar', 'timevar', 'var_of_interest', 'LineColor', 'LineWidth', 'LineAlpha', 'ShowText'}, ...
    {contour_file, 'latitude', 'longitude', 'time', 't2m', 'k', 0.7, 0.4, 'off'});

% Track data
track_data = read_downloaded_data(trackfile);

% Output location
output_directory = fullfile('output', 'bear_test');

%% Bears with NDVI, water, labeled points
% Color by nickname

track_memory = 500;
start_time = datetime('2022-06-01');
end_time = datetime('2022-6-15');

shapefile_stack = {lakes, rivers};

animate_gridded_ndvi(track_data, ...
    gridded_data=ndvi_data, ...
    shapefile_stack=shapefile_stack, ...
    labeled_points = label_data, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory, ...
    group_by='animal_nick_name');

%% Without gridded data
% Color by nickname

track_memory = 500;
start_time = datetime('2022-06-01');
end_time = datetime('2022-6-15');

shapefile_stack = {lakes, rivers};

animate_gridded_ndvi(track_data, ...
    shapefile_stack=shapefile_stack, ...
    labeled_points = label_data, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory, ...
    group_by='animal_nick_name');

%% Fade tracks

track_memory = 500;
start_time = datetime('2022-06-01');
end_time = datetime('2022-6-15');

shapefile_stack = {lakes, rivers};

animate_gridded_ndvi(track_data, ...
    shapefile_stack=shapefile_stack, ...
    fade_tracks=true,...
    labeled_points = label_data, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory, ...
    group_by='animal_nick_name');


%% Custom colormap, track marker size 
% Color by nickname

colors = cmap_from_colors([    0.6353    0.0784    0.1843
    0.8510    0.3255    0.0980
    0.7176    0.2745    1.0000]);

track_memory = 500;
start_time = datetime('2022-06-01');
end_time = datetime('2022-6-15');

shapefile_stack = {lakes, rivers};

animate_gridded_ndvi(track_data, ...
    track_cmap=colors,...
    track_marker_size = 70, ...
    shapefile_stack=shapefile_stack, ...
    labeled_points = label_data, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory, ...
    group_by='animal_nick_name');


%% Hourly time resolution
% Color by nickname

track_memory = 500;
start_time = datetime('2022-06-01');
end_time = datetime('2022-6-03');

shapefile_stack = {lakes, rivers};

animate_gridded_ndvi(track_data, ...
    track_frequency = hours(1), ...
    shapefile_stack=shapefile_stack, ...
    labeled_points = label_data, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory, ...
    group_by='animal_nick_name');

%% Hourly track resolution, daily gridded data resolution
% Color by nickname

track_memory = 500;
start_time = datetime('2022-06-01');
end_time = datetime('2022-6-03');

shapefile_stack = {lakes, rivers};

animate_gridded_ndvi(track_data, ...
    gridded_data=ndvi_data, ...
    track_frequency = hours(1), ...
    shapefile_stack=shapefile_stack, ...
    labeled_points = label_data, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory, ...
    group_by='animal_nick_name');

%% With elevation contours
% Color by nickname

elevation = containers.Map({'nlevels', 'LineColor', 'LineWidth', 'ShowText'}, ...
                            {5, 'k', 1, 'off'});

track_memory = 500;
start_time = datetime('2022-06-01');

end_time = datetime('2022-6-15');

shapefile_stack = {lakes, rivers};

animate_gridded_ndvi(track_data, ...
    shapefile_stack=shapefile_stack, ...
    labeled_points = label_data, ...
    elevation=elevation, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory, ...
    group_by='animal_nick_name');

%% Test track memory stays after end of data
% Color by nickname

track_memory = 500;
start_time = datetime('2022-09-01');
end_time = datetime('2022-09-30');

shapefile_stack = {lakes, rivers};

animate_gridded_ndvi(track_data, ...
    shapefile_stack=shapefile_stack, ...
    labeled_points = label_data, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory, ...
    group_by='animal_nick_name');


%% Including a contour variable
% Gridded NDVI, daily resolution
% ECMWF temperature, plotted as contour 
% Shapefile with roads 
% Shapefile with rivers
% Shapefile with lakes 
% File with labeled points (no time constraint) 

track_memory = 500;
start_time = datetime('2022-06-01');

end_time = datetime('2022-6-15');

shapefile_stack = {rivers, lakes};

animate_gridded_ndvi(track_data, ...
    gridded_data=ndvi_data, ...
    contour_data=contour_data, ...
    shapefile_stack = shapefile_stack, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory);

%% Labels start & end 
% Color by nickname

labels_file = get_fullpath('test_labels.csv');
label_data = containers.Map({'filename', 'marker_color', 'marker_size'}, ...
                            {labels_file, 'k', 10});

track_memory = 500;
start_time = datetime('2022-06-01');
end_time = datetime('2022-6-15');

shapefile_stack = {lakes, rivers};

animate_gridded_ndvi(track_data, ...
    shapefile_stack=shapefile_stack, ...
    labeled_points = label_data, ...
    start_time=start_time, end_time=end_time, track_memory=track_memory, ...
    output_directory = output_directory, ...
    group_by='animal_nick_name');


