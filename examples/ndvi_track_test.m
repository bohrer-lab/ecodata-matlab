
addpath("data/")
addpath("functions/")

trackfile = '/Users/jmissik/Desktop/Postdoc/Animal movement/Southern_Lakes_Caribou/Southern Lakes Caribou.csv';
data = read_downloaded_data(trackfile);

start_time = '2021-01-01 00:00:00';
end_time = '2021-03-21 00:00:00';

data = data(strcmp(data.individual_local_identifier, 'CCH1923'), :); 
data = removevars(data,{'visible', 'individual_local_identifier', 'individual_taxon_canonical_name', 'sensor_type', 'study_name'});
data = data((data.timestamp >= start_time) & (data.timestamp <= end_time), :);
data = resample_track_data(data, days(1));

% datadir = fullfile('data', 'NDVI_caribou_tif', 'tif');
datadir = '/Users/jmissik/Desktop/Postdoc/Animal movement/NDVI_caribou_tif/tif/';

year = 2021;
start_day = 1;
end_day = 150;

%display options
track_color = 'c';
track_marker = 'o';

npoints = 7;


datafile = @(filename) fullfile(datadir,filename);

videoFilename = fullfile(pwd,'test.avi');
if exist(videoFilename,'file')
    delete(videoFilename)
end
writer = VideoWriter(videoFilename);
writer.FrameRate = 400;
writer.Quality = 100;
open(writer)



fig = figure;

%set up geo axes and basemap
gx = geoaxes;
buffer = 0.10 * (max([(max(data.location_lat)-(min(data.location_lat))) (max(data.location_long)-(min(data.location_long)))]));
latlim = [(min(data.location_lat) - buffer) (max(data.location_lat) + buffer)];
lonlim = [(min(data.location_long)-buffer) (max(data.location_long)+buffer)];
geolimits(gx, latlim, lonlim)
% geobasemap(gx,'satellite');
% an = animatedline(gx, Color=track_color, Marker=track_marker);
% an = animatedline(Color=track_color, Marker=track_marker);

% webmap('World Topographic Map');
% hold on

% date = data.timestamp(1);
% current_day = num2str(day(date, 'dayofyear'), '%03.f');
% cachefile = datafile(['MOD13A1.006__500m_16_days_NDVI_doy' num2str(year) current_day '_aid0001.tif']);
% disp(cachefile)
% %     hold on
% if exist(cachefile, 'file')
%     [A,R] = readgeoraster(cachefile);
%     A = double(A);
%     disp('updating  ndvi')
% end
% geoshow(A,R, 'DisplayType','surface' ); 
% 




% 
basefile = datafile(['MOD13A1.006__500m_16_days_NDVI_doy' num2str(year) num2str(start_day, '%03.f') '_aid0001.tif']);
for k=1:length(data.location_lat)
    % Update the time values and assign the Time property for each server.
    date = data.timestamp(k);
    current_day = num2str(day(date, 'dayofyear'), '%03.f');

%     Retrieve the file for this time 
    cachefile = datafile(['MOD13A1.006__500m_16_days_NDVI_doy' num2str(year) current_day '_aid0001.tif']);
    disp(cachefile)
%     hold on
    if exist(cachefile, 'file')
        [A,R] = readgeoraster(cachefile);
        A = double(A);
        disp('updating  ndvi')
    end
%     cmap = colormap(winter);
%     geoshow(A,R);% 'DisplayType','surface' ); 
    gs = geoshow(A, R, 'DisplayType', 'texturemap');
    colormap winter;
    alpha .5;
    xlim(lonlim)
    ylim(latlim)
    hold on
    
    if (k - npoints) < 1
        oldest_point = 1;
    else
        oldest_point = k - npoints;
    end 
    h = plot(data.location_long(oldest_point:k), data.location_lat(oldest_point:k), '-o', 'LineWidth', 10, 'Color', 'red');
    uistack(h,'top')
    title(datestr(data.timestamp(k)))
%     addpoints(an, data.location_lat(k), data.location_long(k));


        drawnow

        % Save the current frame as an RGB image.
        frame = getframe(gcf);


    writeVideo(writer,frame);
    delete(h);
    delete(gs);
%     clf
end
close(writer)
close all