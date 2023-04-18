
addpath("data/")
addpath("functions/")

% trackfile = '/Users/jmissik/Desktop/Postdoc/Animal movement/Southern_Lakes_Caribou/Southern Lakes Caribou.csv';
trackfile = '/Users/jmissik/Desktop/repos/movebank_vis/data/caribou_NDVI.csv';
data = read_downloaded_data(trackfile);

start_time = '2008-01-01 00:00:00';
end_time = '2008-02-25 00:00:00';

data = data(strcmp(data.individual_local_identifier, 'QU_car007'), :); 
data = removevars(data,{'visible', 'individual_local_identifier', 'individual_taxon_canonical_name', 'sensor_type', 'study_name'});
data = removevars(data,{'comments', 'study_specific_measurement', 'algorithm_marked_outlier', 'tag_local_identifier'});

data = data((data.timestamp >= start_time) & (data.timestamp <= end_time), :);
data = resample_track_data(data, days(1));

% datadir = fullfile('data', 'NDVI_caribou_tif', 'tif');
datadir = '/Users/jmissik/Desktop/Postdoc/Animal movement/BC_caribou_snow/tif';

elevation_file = '/Users/jmissik/Desktop/Postdoc/Animal movement/ASTGTM_NC.003_ASTER_GDEM_DEM_doy2000061_aid0001.tif'; 

year = 2008;
start_day = 1;
end_day = 165;

%display options
track_color = 'c';
track_marker = 'o';

npoints = 4;
frame_rate = 1;


datafile = @(filename) fullfile(datadir,filename);

videoFilename = fullfile(pwd,'test.avi');
if exist(videoFilename,'file')
    delete(videoFilename)
end
writer = VideoWriter(videoFilename);
writer.FrameRate = frame_rate;
writer.Quality = 100;
open(writer)



fig = figure;

%set up geo axes and basemap
% gx = geoaxes;
buffer = 0.10 * (max([(max(data.location_lat)-(min(data.location_lat))) (max(data.location_long)-(min(data.location_long)))]));
latlim = [(min(data.location_lat) - buffer) (max(data.location_lat) + buffer)];
lonlim = [(min(data.location_long)-buffer) (max(data.location_long)+buffer)];
[dem, Rdem] = readgeoraster(elevation_file); 
dem = double(dem);
% geolimits(gx, latlim, lonlim)
% geobasemap(gx,'satellite');

% webmap('World Topographic Map');
hold on



for k=1:length(data.location_lat)
    % Update the time values and assign the Time property for each server.
    date = data.timestamp(k);
    current_day = num2str(day(date, 'dayofyear'), '%03.f');

%     Retrieve the file for this time 
%     cachefile = datafile(['MOD13A1.006__500m_16_days_NDVI_doy' num2str(year) current_day '_aid0001.tif']);
      cachefile = datafile(['MOD10A1.006_NDSI_Snow_Cover_doy' num2str(year) current_day '_aid0001.tif']);

      disp(cachefile)
%     hold on
    if exist(cachefile, 'file')
        [A,R] = readgeoraster(cachefile);
        A = double(A);
        disp('updating  ndvi')
    end
    cmap = colormap(winter);
%     gs = geoshow(A,R);% 'DisplayType','surface' ); 
    gs = geoshow(A, R, 'DisplayType', 'texturemap',...
    'AlphaDataMapping','scaled',...
    'AlphaData',gradient(A));
%     colormap winter;
%     cb = colorbar;
%     disp(cb.Children)
%     cb=cbar();
%     imh=cb.Children(1);
%     imh.AlphaData = imh.CData;
%     imh.AlphaDataMapping = 'scaled';
    
%     alpha .3;
    xlim(lonlim)
    ylim(latlim)
    hold on
    
    if (k - npoints) < 1
        oldest_point = 1;
    else
        oldest_point = k - npoints;
    end 
    x = data.location_long(oldest_point:k);
    y = data.location_lat(oldest_point:k);
    y(end) = NaN;
    c = (1:size(x,1))/size(x,1);

%     h = plot(x, y, '-o', 'LineWidth', 10, 'Color', 'red');

%     h = patch([x nan],[y nan],[z nan],[z nan], 'edgecolor', 'interp'); 
% %     colorbar;colormap(jet);
%     h = surface([x;x],[y;y],[z;z],[c;c],...
%         'facecol','no',...
%         'edgecol','interp',...
%         'linew',10);
    h = patch(x, y, c, 'EdgeColor','red','Marker','o', 'LineWidth', 10);
%     colormap(jet);
%     colorbar;colormap(jet);
    amap = linspace(0,1,size(x,1))';
%     h=patch(x,y,c,'red');
    set(h,'facealpha',0);
    set(h,'Marker', 'o', 'MarkerSize', 8,  'MarkerEdgeColor', 'none','EdgeColor','red',...
   'LineWidth',8,'FaceVertexAlphaData',amap, 'LineJoin', 'round',...
   'EdgeAlpha','interp', 'FaceAlpha', 'flat', ...
   'FaceVertexCData',amap ); %ones(size(amap))


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