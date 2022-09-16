
close all
clear all

%% paths
addpath("data/")
addpath("functions/")
addpath("examples/")
addpath("m_map/")

%% options
trackfile = 'data/example_datasets/caribou_NDVI.csv';
modisncfile = 'data/user_datasets/MOD13A1.006_500m_aid0001_all.nc';

output_directory = fullfile(pwd, 'output/testframes');

start_time = datetime('2002-06-26 00:00:00');
% end_time = datetime('2004-09-30 00:00:00');
end_time = datetime('2002-07-26 00:00:00');

npoints = 400; % track memory
frame_rate = 14;

save_frames = true; %whether to save all indivudual frames as image files
frame_resolution = 600;

videoFilename = fullfile(output_directory, 'ndvi_movie.avi');
min_elevation = -200;
max_elevation = 2000;
d_elevation = 200;

latmin = 54.5;
latmax = 55.5;
lonmin = -122.5;
lonmax = -121.5;


%% read and prepare data

% track data
data = read_downloaded_data(trackfile);
% data = data(strcmp(data.individual_local_identifier,  'BP_car022'),:);
data = data((data.location_long>=lonmin) & (data.location_long <=lonmax) & ...
    (data.location_lat>=latmin) & (data.location_lat <= latmax),:);

% filter to time of interest
data = data((data.timestamp >= start_time) & (data.timestamp <= end_time), :);

% split to separate tt for each individual animal,
% and interpolate to daily
[inds, c] = split_tt_by_individual(data, days(1));


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
% [CS,CH] = m_etopo2('contour',[min_elevation:d_elevation:0 0:d_elevation:max_elevation],'edgecolor', 'black');
m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 3);
% set(gcf,'color','w');   % Set background colour before m_image call

fig = gcf;
fig.WindowState = 'maximized';


% caxis([min_elevation max_elevation]);
% colormap([m_colmap('blues',64);m_colmap('gland',128)]);
% brighten(.5);

% ax=m_contfbar(1,[.5 .8],CS,CH);
% title(ax,{'Level/m',''}); % Move up by inserting a blank line
hold on


% topo base map
% [CS,CH]=m_etopo2('contourf',[min_elevation:d_elevation:0 0:d_elevation:max_elevation],'edgecolor','none');
%
% caxis([min_elevation max_elevation]);
% colormap([m_colmap('blues',64);m_colmap('gland',128)]);
% brighten(.5);

% title(ax,{'Level/m',''}); % Move up by inserting a blank line
% hold on




%% plotting

for k=start_time:end_time

    if ismember(k, nctimestamp)
        A = nc_ndvi(:, :, nctimestamp == k)';
        colormap(flipud(m_colmap('green')));
        m_image(nc_long,nc_lat, A);
%         alpha 0.2;
        caxis([-0.1 1])
        cb = colorbar;
        ylabel(cb,'MODIS NDVI','FontSize',12);
%         m_shadedrelief(nc_long,nc_lat, A, 'alpha', 0.4);
    end

%     [CS,CH] = m_etopo2('contour',[min_elevation:d_elevation:0 0:d_elevation:max_elevation],'edgecolor', 'black');

    hold on

    h_cells = cell(1,length(inds));
    s_cells = cell(1,length(inds));

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

            if ~isempty(x)
                xseg = [x(1:end-1),x(2:end)];
                yseg = [y(1:end-1),y(2:end)];

    %             scatterColors = flipud(hot(size(x,1)));
                zeds = zeros(size(xseg,1), 1);
                blk = [zeds zeds zeds];
                segColors = blk;
%                 segColors = flipud(spring(size(xseg,1))); % Choose a colormap
                scatterColor = [101/255 67/255 33/255];
                seg_amap = logspace(0,1,size(xseg,1));
                seg_amap = seg_amap/max(seg_amap);

    %             sc_amap = logspace(0,1,size(x,1));
    %             sc_amap = sc_amap/max(sc_amap);

                segColors(:,4) = seg_amap;

                h = m_plot(xseg',yseg','LineWidth',3);
                s = m_scatter(x(end),y(end),150,scatterColor,'h','filled');
                h_cells{i} = h;
                s_cells{i} = s;
                set(h, {'Color'}, mat2cell(segColors,ones(size(xseg,1),1),4))
%             set(s, 'AlphaData', sc_amap)
            end

        end


        end

%     addpoints(an, data.location_lat(k), data.location_long(k));
        title(datestr(k))

        drawnow

        % Save the current frame as an RGB image.
%         gcf.WindowState = 'maximized';      % Maximize the figure to your whole screen.
        frame = getframe(gcf);
          

        if save_frames
            %save image of each frame
            % Construct an output image file name.
            outputBaseFileName = sprintf('Frame-%s.png', k);
            outputFullFileName = fullfile(output_directory, outputBaseFileName);
            exportgraphics(gcf,outputFullFileName,'Resolution', frame_resolution)
        end


    writeVideo(writer,frame);
    for i=1:length(h_cells); delete(h_cells{i}); end
    for i=1:length(s_cells); delete(s_cells{i}); end
%     delete(CH)

%     delete(gs);
%     clf
end
close(writer)
close all

function [inds,c] = split_tt_by_individual(data, resample_interval)
    data2 = data(:, {'location_lat', 'location_long', 'individual_local_identifier'});
    inds = unique(data2.individual_local_identifier);

    c = cell(1,length(inds));
    for i = 1:length(c), c{1,i} = {inds{i},data2(strcmp(data2.individual_local_identifier, inds{i}), :)}; end

    %resample
    for i = 1:length(c), c{1,i}{2} = resample_track_data(c{1,i}{2}(:, {'location_lat', 'location_long'}), resample_interval); end

end