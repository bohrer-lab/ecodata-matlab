% Examples of static plots of tracks annotated with environmental variables
%
% Data is imported from a saved file

clearvars;

addpath functions/
addpath data/

% Plot NDVI data

% Read in some test data
data = read_downloaded_data('caribou_NDVI.csv');
data = data(strcmp(data.individual_local_identifier, 'BP_car032'), :); %Select one caribou

% Variable to plot:
var = 'MODISLandVegetationIndices500m16dTerraNDVI';

output_file = 'output/NDVI_test.png';
plot_annotated_track(data, var, output_file)


% Plot snow data

% Read in some test data
data = read_downloaded_data('snow_caribou.csv');
data = data(strcmp(data.individual_local_identifier, 'BP_car032'), :); %Select one caribou

% Variable to plot:
var = 'MODISSnow500m8dTerraSnowCover';

output_file = 'output/snow_test.png';
plot_annotated_track(data, var, output_file)
