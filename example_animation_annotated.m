% Examples of animated tracks annotated with environmental variables
% Data is imported from a saved file

clearvars;

addpath functions/
addpath data/


% MODIS SNOW
data = read_downloaded_data('snow_caribou.csv');
data = data(strcmp(data.individual_local_identifier, 'BP_car032'), :);
var = 'MODISSnow500m8dTerraSnowCover';

fileout = 'output/caribou_snow_animation.avi';
fig = animate_track_annotated(data, var, fileout);


% MODIS NDVI
data = read_downloaded_data('caribou_NDVI.csv');
data = data(strcmp(data.individual_local_identifier, 'BP_car032'), :);
var = 'MODISLandVegetationIndices500m16dTerraNDVI';

fileout = 'output/caribou_ndvi_animation.avi';
fig = animate_track_annotated(data, var, fileout);
