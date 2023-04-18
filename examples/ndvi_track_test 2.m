
addpath("data/")
addpath("functions/")

% trackfile = '/Users/jmissik/Desktop/Postdoc/Animal movement/Southern_Lakes_Caribou/Southern Lakes Caribou.csv';
trackfile = '/Users/jmissik/Desktop/repos/movebank_vis/data/caribou_NDVI.csv';
data = read_downloaded_data(trackfile);
% 
start_time = datetime('2008-03-05 00:00:00');
end_time = datetime('2008-7-31 00:00:00');
% start_time = datetime('2021-01-01 00:00:00');
% end_time = datetime('2021-03-21 00:00:00');

% data = data(strcmp(data.individual_local_identifier, 'QU_car007'), :); 
% data = data(strcmp(data.individual_local_identifier, 'CCH1923'), :); 

% data = removevars(data,{'comments', 'study_specific_measurement', 'algorithm_marked_outlier', 'tag_local_identifier'});
% 
data = data((data.timestamp >= start_time) & (data.timestamp <= end_time), :);


[inds, c] = split_tt_by_individual(data);


%netcdf modis 
modisncfile = '/Users/jmissik/Desktop/Postdoc/Animal movement/MOD13A1.006_500m_aid0001.nc';
nc_lat = ncread(modisncfile, 'lat');
nc_long = ncread(modisncfile, 'lon');
nc_time = ncread(modisncfile, 'time');
timestamp = datetime(datevec(double(nc_time + datenum('2000-01-01 00:00:00'))));
nc_ndvi = ncread(modisncfile, '_500m_16_days_NDVI');


m_proj('lambert','lon',[min(nc_long) max(nc_long)],'lat',[min(nc_lat) max(nc_lat)]);   % Projection
m_shadedrelief(nc_long,nc_lat, nc_ndvi(:,:, timestamp == d)');

% data = removevars(data,{'visible', 'individual_local_identifier', 'individual_taxon_canonical_name', 'sensor_type', 'study_name'});
% data = resample_track_data(data, days(1));

% datadir = fullfile('data', 'NDVI_caribou_tif', 'tif');
datadir = '/Users/jmissik/Desktop/Postdoc/Animal movement/NDVI_BC_caribou_2008/tif';

% elevation_file = '/Users/jmissik/Desktop/Postdoc/Animal movement/ASTGTM_NC.003_ASTER_GDEM_DEM_doy2000061_aid0001.tif'; 
% elevation_file = '/Users/jmissik/Desktop/Postdoc/Animal movement/DEM/southern_caribou_DEM.tif';
year = 2008;
start_day = day(start_time, 'dayofyear');
end_day = day(end_time, 'dayofyear');

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
% [dem, Rdem] = readgeoraster(elevation_file); 

% dem = double(dem);
% geolimits(gx, latlim, lonlim)
% geobasemap(gx,'satellite');

% webmap('World Topographic Map');
% geoshow(dem, Rdem, 'DisplayType', 'texturemap')
% colormap gray;
hold on



for k=start_day:end_day
    % Update the time values and assign the Time property for each server.
%     date = data.timestamp(k);
    current_day = num2str(k, '%03.f');

%     Retrieve the file for this time 
%     cachefile = datafile(['MOD13A1.006__500m_16_days_NDVI_doy' num2str(year) current_day '_aid0001.tif']);
%       cachefile = datafile(['MOD10A1.006_NDSI_Snow_Cover_doy' num2str(year) current_day '_aid0001.tif']);

      disp(cachefile)
%     hold on
    if exist(cachefile, 'file')
        [A,R] = readgeoraster(cachefile);
        A = double(A);
        disp('updating  raster')
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
    
    for i=1:length(inds)
        data_ind = c{1,i}{2};

        doy = day(data_ind.timestamp, 'dayofyear');
        if max(doy) >= k

            if (k - npoints) < 1
                oldest_point = 1;
            else
                oldest_point = k - npoints;
            end 
            x = data_ind.location_long((doy<=k) & (doy>=oldest_point));
            y = data_ind.location_lat((doy<=k) & (doy>=oldest_point));
            if ~isempty(y)
                y(end) = NaN;
            end
            col = (1:size(x,1))/size(x,1);
    
    %     h = plot(x, y, '-o', 'LineWidth', 10, 'Color', 'red');
    
    %     h = patch([x nan],[y nan],[z nan],[z nan], 'edgecolor', 'interp'); 
    % %     colorbar;colormap(jet);
    %     h = surface([x;x],[y;y],[z;z],[c;c],...
    %         'facecol','no',...
    %         'edgecol','interp',...
    %         'linew',10);
            h = patch(x, y, col, 'EdgeColor','red','Marker','o', 'LineWidth', 10);
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
        end

            
        end
    
%     addpoints(an, data.location_lat(k), data.location_long(k));
        current_datetime = datetime(year, 1,1) + k-1;
        title(datestr(current_datetime))

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

function [inds,c] = split_tt_by_individual(data)
    data2 = data(:, {'location_lat', 'location_long', 'individual_local_identifier'});
    inds = unique(data2.individual_local_identifier);

    c = cell(1,length(inds));
    for i = 1:length(c), c{1,i} = {inds{i},data2(strcmp(data2.individual_local_identifier, inds{i}), :)}; end
    
    %resample
    for i = 1:length(c), c{1,i}{2} = resample_track_data(c{1,i}{2}(:, {'location_lat', 'location_long'}), days(1)); end;

end