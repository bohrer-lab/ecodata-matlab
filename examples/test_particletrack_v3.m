%% TEST_PARTICLETRACK   Visualizes vector field of wind using particles
%  v3   Converts data structure to Tables
%  v2   Regenerates quivers that go out of range
%       Randomizes generation
%       Add "active" and "age" fields
%       Refactor code to remove for loops (use comma sep lists and deal function)

% This variant is based on v2 and changes data to tables from structures

close all
clear all

%% Parameters
speedfactor = 0.01;     % Speed of particles scaled with U & V.
recordmovie = true;    % Set to true to record AVI.
moviefilename = 'Y2Y_3';  % Name of movie to output.
                        % Change to inf to iterate over all files.

npoints = 20;  % points in eagle data to display at once

file_path = matlab.desktop.editor.getActiveFilename;
parts = strsplit(file_path, filesep);
parent_path = strjoin(parts(1:end-1), filesep);
% directory for wind data netcdf
netcdf_path = fullfile(parent_path, "..", "data", "wind_data", "adaptor.mars.internal-1654960100.582873-11470-5-61b1b1cb-cfbe-49fd-a03f-3f06495e0ed9.nc");
% directory for u component data
u_d = dir(fullfile(parent_path, "..", "data", "wind_data", "ECMWF_wind_BC_caribou_April2008-1678726286799667131", "ECMWF_wind_BC_caribou_April2008-1678726286799667131", "ECMWF ERA5 SL Wind (10 m above Ground U Component)"));
% directory for v component data
v_d = dir(fullfile(parent_path, "..", "data", "wind_data", "ECMWF_wind_BC_caribou_April2008-1678726286799667131", "ECMWF_wind_BC_caribou_April2008-1678726286799667131", "ECMWF ERA5 SL Wind (10 m above Ground V Component)"));
file_ts_pre_str = "Component)-";
file_ts_post_str = "-0-0.tif";
ts_input_format = "yyyyMMddHHmmssSSS";

% eagle data path
e_d = fullfile(parent_path, "..", "data", "wind_data", "HawkWatch International Golden Eagles.csv");


m_map_path = fullfile(parent_path, "..", "m_map");
addpath(genpath(m_map_path))

%% Load and process files

netcdf_lat = double(ncread(netcdf_path, "latitude"));
netcdf_lon = double(ncread(netcdf_path, "longitude"));


%% Read in U & V

U = ncread(netcdf_path, "u10");
V = ncread(netcdf_path, "v10");
netcdf_time = ncread(netcdf_path, "time");
timestamp = datetime(datevec(double(double(netcdf_time)/24 + datenum('1900-01-01 00:00:00'))));


%% Load eagle data
data_eagle = read_downloaded_data(e_d);

ts_diff = timestamp(2) - timestamp(1);
start_time = min(timestamp);
end_time = max(timestamp);

data_e_filt = data_eagle( ...
    (data_eagle.timestamp >= start_time) ...
    & (data_eagle.timestamp <= end_time), :);


lat_lon = data_e_filt{:, ["location_long", "location_lat"]};
varNames = {'lon', 'lat'};
data_e_filt = array2timetable(lat_lon, 'RowTimes',data_e_filt.timestamp,'VariableNames',varNames);
data_e_filt = sortrows(data_e_filt);

data_e_resample = resample_track_data(data_e_filt, ts_diff);
data_e_resample = outerjoin(data_e_resample, timetable(timestamp));


%% Initialize figure

fig = figure;
[minlat,maxlat] = bounds(data_e_resample.lat);
[minlon,maxlon] = bounds(data_e_resample.lon);
minlat = double(minlat);
maxlat = double(maxlat);
minlon = double(minlon);
maxlon = double(maxlon);

d_lat = abs(netcdf_lat(2) - netcdf_lat(1));
d_lon = abs(netcdf_lon(2) - netcdf_lon(1));
% ax = axesm('MapProjection','mercator','MapLatLimit',[minlat,maxlat],'MapLonLimit',[minlon,maxlon]);
% geobasemap('satellite');
% 
ax = worldmap([minlat,maxlat],[minlon,maxlon]);

land = shaperead('landareas.shp', 'UseGeoCoords', true);
geoshow(ax, land, 'FaceColor', [0.5 0.7 0.5])

lakes = shaperead('worldlakes.shp', 'UseGeoCoords', true);
geoshow(lakes, 'FaceColor', 'blue')

rivers = shaperead('worldrivers.shp', 'UseGeoCoords', true);
geoshow(rivers, 'Color', 'blue')


[N,R] = egm96geoid;
geoshow(N,R,'DisplayType','contour')
% [c,h] = contourm(N,R);


%% subselect netcdf data based on eagle data
lat_filter = netcdf_lat >= minlat & netcdf_lat <= maxlat;
lon_filter = netcdf_lon >= minlon & netcdf_lon <= maxlon;
netcdf_lat_filtered = netcdf_lat(lat_filter);
netcdf_lon_filtered = netcdf_lon(lon_filter);
U_filtered = U(lon_filter, lat_filter, :);
V_filtered = V(lon_filter, lat_filter, :);

[LAT,LON] = meshgrid(netcdf_lat_filtered, netcdf_lon_filtered);

gridsize = [size(LAT)];


%% Calculate grid

lonsize = abs(maxlon - minlon);
latstart = min(data_e_resample.lat);%min(LAT,[],'all');
latend = max(data_e_resample.lat);%max(LAT,[],'all');
latsize = abs(maxlat - minlat);
cellsize = [lonsize/(gridsize(2)-1) latsize/(gridsize(1)-1)];
clearradius = sqrt(cellsize(1)^2+cellsize(2)^2)/5;
gridlength = prod(gridsize);




%% Assign particle structure

particle.lat = LAT;
particle.lon = LON;
particle.age = zeros(size(gridsize));

hold on;
particle_h = []; % Initialize array of particle handles


%% Plot particles and calculate new positions based on U & V

numquivers = prod(gridsize);

for timeidx = 1:length(timestamp)
    % Calculate velocity vector

    U_ = U_filtered(:,:,timeidx);
    V_ = V_filtered(:,:,timeidx);

    particle.u = U_;
    particle.v = V_;


    % Update title
    title(string(timestamp(timeidx)));

    % Update age
    particle.age = particle.age + 1;

    % Update quivers
    if timeidx > 1
        delete(quiverh);
        delete(h);
    end

%     quiverh = cell(numquivers);
%     for idx = 1:numquivers
%         if timeidx > 1
%             delete(quiverh{idx});
%         end
%         begin_point = [particle.lat(idx) particle.lon(idx)];
%         end_point = [particle.lat(idx) + particle.v(idx) particle.lon(idx) + particle.u(idx)];
%         quiverh{idx} = plot_arrow_geoplot(begin_point, end_point);
%     end
%     quiverh = quiverm(particle.lat,particle.lon,particle.v,particle.u,'c',1);
    quiverh = quiverm(particle.lat,particle.lon,particle.v,particle.u);
%     quiverh = quiver(particle.lat,particle.lon,particle.v,particle.u);
    % To color the quivers using RGB you can use the following
    % set(quiverh,'Color',[0 1 1]);

    hold on
%     plot eagle data
    if (timeidx - npoints) < 1
        oldest_point = 1;
    else
        oldest_point = timeidx - npoints;
    end
    x = data_e_resample.lat(oldest_point:timeidx);
    y = data_e_resample.lon(oldest_point:timeidx);
    lat = x;
    lon = y;
%     lat = x(~isnan(x));
%     lon = y(~isnan(x));
%     lon(end) = NaN;
    c = (1:3)/size(lat,1);
%     c = [.6, .7, .3];
%     h = patch(lat, lon, c);% 'EdgeColor','red','Marker','o', 'LineWidth', 10);
%     h = patchm(x, y, c);%, 'EdgeColor','red','Marker','o', 'LineWidth', 10);




% 
%     lat_eagle = data_e_resample.lat;
%     lon_eagle = data_e_resample.lon;
    h = plotm(lat, lon, '-o', 'Color', 'red');
%     h = geoplot(lat, lon, '-o', 'Color', 'red');
% 
% 

    % Update
    drawnow;

    lat_rounded = round(particle.lat / d_lat)*d_lat;
    lon_rounded = round(particle.lon / d_lat)*d_lon;
    for i_lat = 1:size(lat_rounded, 1)
        for j_lat = 1:size(lat_rounded, 2)
            for i_net_lat = 1:length(netcdf_lat_filtered)
                if lat_rounded(i_lat, j_lat) == netcdf_lat_filtered(i_net_lat)
                    particle.v(i_lat, j_lat) = V_(i_lat, j_lat);
                end
            end
        end
    end

    for i_lon = 1:size(lon_rounded, 1)
        for j_lon = 1:size(lon_rounded, 2)
            for i_net_lon = 1:length(netcdf_lon_filtered)
                if lon_rounded(i_lon, j_lon) == netcdf_lon_filtered(i_net_lon)
                    particle.u(i_lon, j_lon) = U_(i_lon, j_lon);
                end
            end
        end
    end

    % Calculate Next Position
    particle_lon_next = particle.lon + speedfactor * particle.u;
    particle_lat_next = particle.lat + speedfactor * particle.v;
    particle.lon = particle_lon_next;
    particle.lat = particle_lat_next;

    % Check of out of range and mark those as inactive
    lonoutofrange = (particle.lon < minlon) | (particle.lon > maxlon);
    latoutofrange = (particle.lat < minlat) | (particle.lat > maxlat);
    particle.active = ~(lonoutofrange | latoutofrange);

    % Reassign inactive particles
    for idx = 1:numquivers
        if ~particle.active(idx)
            particle.lat(idx) = LAT(idx);
            particle.lon(idx) = LON(idx);
% 
            particle.age(idx) = 0;
%          
%             latdist = particle.lat(idx) - [particle.lat];
%             londist = particle.lon(idx) - [particle.lon];
%             particledist = sqrt(latdist.^2 + londist.^2);
%             particledist = particledist(particle.active); % remove distance of inactive particles
%             if min(particledist) > clearradius
%                 particletooclose = false;
%             else
%                 particletooclose = true;
%             end
%             searchidx = 0;
%             while particletooclose
%                 particle.lat(idx) = minlat + (maxlat-minlat) * rand;
%                 particle.lon(idx) = minlon + (maxlon-minlon) * rand;
%                 % Add check to see if this particle is close to any other active particles
%                 latdist = particle.lat(idx) - [particle.lat];
%                 londist = particle.lon(idx) - [particle.lon];
%                 particledist = sqrt(latdist.^2 + londist.^2);
%                 particledist = particledist(particle.active); % remove distance of inactive particles
%                 if min(particledist) > clearradius
%                     particletooclose = false;
%                 else
%                     searchidx = searchidx + 1;
%                     %disp([num2str(searchidx) ' searching for new position'])
%                 end
%             end
        end
    end

    if recordmovie
        M(timeidx) = getframe(gcf);  % for recording movie
    end
end


%% Record movie

if recordmovie
    % create the video writer with 1 fps
    writerObj = VideoWriter(moviefilename,'Uncompressed AVI');
    writerObj.FrameRate = 10;
    % set the seconds per image
    % open the video writer
    open(writerObj);
    % write the frames to the video
    for i=1:length(M)
        % convert the image to a frame
        frame = M(i) ;
        writeVideo(writerObj, frame);
    end
    % close the writer object
    close(writerObj);
end