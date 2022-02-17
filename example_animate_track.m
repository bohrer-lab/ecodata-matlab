% Example of animated track
% Data is imported using the API

clearvars;
addpath functions/

% Get data from Movebank
study_ID = '216040785'; %Caribou study

data = import_from_movebank(study_ID);

% Select one animal to display
data = data(strcmp(data.individual_local_identifier, 'BP_car032'), :);

fileout = 'output/caribou_track_animation.avi';
fig = animate_track(data, fileout);