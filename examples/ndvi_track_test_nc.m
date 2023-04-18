
close all
clear all

%%


addpath("data/")
addpath("functions/")
addpath("examples/")
addpath("m_map/")

%% options
trackfile = '/Users/jmissik/Desktop/repos/movebank_vis/data/caribou_NDVI.csv';
modisncfile = '/Users/jmissik/Desktop/Postdoc/Animal movement/MOD13A1.006_500m_aid0001_all.nc';

start_time = datetime('2006-03-05 00:00:00');
end_time = datetime('2008-7-31 00:00:00');

npoints = 4; % track memory
frame_rate = 14;

videoFilename = fullfile(pwd,'test.avi');


%% read and prepare data

% track data
data = read_downloaded_data(trackfile);

% filter to time of interest
data = data((data.timestamp >= start_time) & (data.timestamp <= end_time), :);

% split to separate tt for each individual animal,
% and interpolate to daily
[inds, c] = split_tt_by_individual(data);


% unpack MODIS netcdf data 
nc_lat = ncread(modisncfile, 'lat');
nc_long = ncread(modisncfile, 'lon');
nc_ndvi = ncread(modisncfile, '_500m_16_days_NDVI');
nc_time = ncread(modisncfile, 'time');

% Time in the MODIS netcdf if stored as days since 2000-01-01. Convert to
% regular timestamp
nctimestamp = datetime(datevec(double(nc_time + datenum('2000-01-01 00:00:00'))));

% adjust the start time for the plot so it doesn't start before there is
% MODIS data available 
if start_time < min(nctimestamp); start_time = min(nctimestamp); end

%% Set up for map and animation


% Set up video writer
if exist(videoFilename,'file')
    delete(videoFilename)
end
writer = VideoWriter(videoFilename);
writer.FrameRate = frame_rate;
writer.Quality = 100;
open(writer)

% get geolimits for map
buffer = 0.10 * (max([(max(data.location_lat)-(min(data.location_lat))) (max(data.location_long)-(min(data.location_long)))]));
[latlim, lonlim] = get_geolimits(data, .10);

% Projection
m_proj('lambert','lon',lonlim,'lat',latlim);   
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 3);
hold on

 


%% plotting

for k=start_time:end_time

    if ismember(k, nctimestamp)    
        A = nc_ndvi(:, :, nctimestamp == k)';
        colormap(winter)
        m_shadedrelief(nc_long,nc_lat, A)
    end 
    cmap = colormap(winter);

    hold on
    
    h_cells = cell(1,length(inds));
    for i=1:length(inds)
        data_ind = c{1,i}{2};

        if max(data_ind.timestamp) >= k

            if height(data_ind(timerange(start_time,k), :)) < npoints
                
                oldest_point = start_time;
            else
                
                oldest_point = data_ind.timestamp(find(data_ind.timestamp == k) - npoints + 1);
            end 

            x = data_ind.location_long(oldest_point:k);
            y = data_ind.location_lat(oldest_point:k);


            xseg = [x(1:end-1),x(2:end)]; 
            yseg = [y(1:end-1),y(2:end)]; 

            h = m_plot(xseg',yseg','LineWidth',10); 
            h_cells{i} = h;

        segColors = flipud(autumn(size(xseg,1))); % Choose a colormap
        set(h, {'Color'}, mat2cell(segColors,ones(size(xseg,1),1),3))

    
    %     h = plot(x, y, '-o', 'LineWidth', 10, 'Color', 'red');
    
    %     h = patch([x nan],[y nan],[z nan],[z nan], 'edgecolor', 'interp'); 
    % %     colorbar;colormap(jet);
    %     h = surface([x;x],[y;y],[z;z],[c;c],...
    %         'facecol','no',...
    %         'edgecol','interp',...
    %         'linew',10);
%             h = patch(x, y, col, 'EdgeColor','red','Marker','o', 'LineWidth', 10);
    %     colormap(jet);
    %     colorbar;colormap(jet);
%             amap = linspace(0,1,size(x,1))';
    %     h=patch(x,y,c,'red');
%             set(h,'facealpha',0);
%             set(h,'Marker', 'o', 'MarkerSize', 8,  'MarkerEdgeColor', 'none','EdgeColor','red',...
%            'LineWidth',8,'FaceVertexAlphaData',amap, 'LineJoin', 'round',...
%            'EdgeAlpha','interp', 'FaceAlpha', 'flat', ...
%            'FaceVertexCData',amap ); %ones(size(amap))
%             uistack(h,'top')
        end

            
        end
    
%     addpoints(an, data.location_lat(k), data.location_long(k));
        title(datestr(k))

        drawnow

        % Save the current frame as an RGB image.
        frame = getframe(gcf);


    writeVideo(writer,frame);
    for i=1:length(h_cells); delete(h_cells{i}); end
%     delete(gs);
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