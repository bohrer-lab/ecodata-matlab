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

recordmovie = true;    % Set to true to record AVI.

videoFilename = fullfile(pwd,'output/eagles_final2.avi'); % Name of movie to output.
frame_rate = 14;

% start_date = [];
% end_date = [];

start_lon = 0;
end_lon = 0;
start_lat = 0;
end_lat = 0;
%
start_date = datetime("15-May-2004");
% end_date = datetime("30-Sep-2004");
end_date = datetime("30-May-2004");


% start_lon = -125;
% end_lon = -100;
% start_lat = 30;
% end_lat = 50;

% numquivers = 1;

npoints = 10;  % points in eagle data to display at once
max_age = 4; % max timesteps before resetting a quiver

quiver_respawn = 12;
vecscl=20; % quiver vector scalar param (inverse of size, bigger = smaller)
speedfactor = 0.01;     % Speed of particles scaled with U & V.

min_elevation = -1500;
max_elevation = 3000;
d_elevation = 200;

parent_path = fileparts(mfilename('fullpath'));
% directory for wind data netcdf
% netcdf_path = fullfile(parent_path, "..", "data", "user_datasets", "wind_data", "adaptor.mars.internal-1654960100.582873-11470-5-61b1b1cb-cfbe-49fd-a03f-3f06495e0ed9.nc");
netcdf_path = fullfile(parent_path, "..", "data", "user_datasets", "wind_data", "eagle_ds_2004_thinned2.nc");
% directory for u component data
% u_d = dir(fullfile(parent_path, "..", "data", "user_datasets", "wind_data", "ECMWF_wind_BC_caribou_April2008-1678726286799667131", "ECMWF_wind_BC_caribou_April2008-1678726286799667131", "ECMWF ERA5 SL Wind (10 m above Ground U Component)"));
% directory for v component data
% v_d = dir(fullfile(parent_path, "..", "data", "user_datasets", "wind_data", "ECMWF_wind_BC_caribou_April2008-1678726286799667131", "ECMWF_wind_BC_caribou_April2008-1678726286799667131", "ECMWF ERA5 SL Wind (10 m above Ground V Component)"));
file_ts_pre_str = "Component)-";
file_ts_post_str = "-0-0.tif";
ts_input_format = "yyyyMMddHHmmssSSS";

% eagle data path
e_d = fullfile(parent_path, "..", "data","user_datasets", "wind_data", "HawkWatch International Golden Eagles.csv");



m_map_path = fullfile(parent_path, "..", "m_map");
addpath(genpath(m_map_path))


%% Load and process files

netcdf_lat = double(ncread(netcdf_path, "latitude"));
netcdf_lon = double(ncread(netcdf_path, "longitude"));


%% Read in U & V

U = ncread(netcdf_path, "u10");
V = ncread(netcdf_path, "v10");
netcdf_time = double(ncread(netcdf_path, "time"));
timestamp = datetime(datevec(netcdf_time/24 + datenum('1900-01-01 00:00:00')));

%% filter based on start date;

if ~isempty(start_date)
    filter = timestamp >= start_date;
    timestamp = timestamp(filter);
    netcdf_time = netcdf_time(filter);
    U = U(:, :,filter);
    V = V(:, :,filter);
end
if ~isempty(end_date)
    filter = timestamp <= end_date;
    timestamp = timestamp(filter);
    netcdf_time = netcdf_time(filter);
    U = U(:, :,filter);
    V = V(:, :,filter);
end


%% Load eagle data
data_eagle = read_downloaded_data(e_d);

ts_diff = timestamp(2) - timestamp(1);
start_time = min(timestamp);
end_time = max(timestamp);

data_e_filt = sortrows(data_eagle( ...
    (data_eagle.timestamp >= start_time) ...
    & (data_eagle.timestamp <= end_time), :));

if start_lon
    data_e_filt = data_e_filt(data_e_filt.location_long >= start_lon, :);
end
if end_lon
    data_e_filt = data_e_filt(data_e_filt.location_long <= end_lon, :);
end
if start_lat
    data_e_filt = data_e_filt(data_e_filt.location_lat >= start_lat, :);
end
if end_lat
    data_e_filt = data_e_filt(data_e_filt.location_lat <= end_lat, :);
end



[inds, c] = split_tt_by_individual(data_e_filt, hours(1));


for i = 1:length(c)
    c{i}{2} = outerjoin(c{i}{2}, timetable(timestamp));
end


%% Initialize figure

fig = figure;
[minlat,maxlat] = bounds(data_e_filt.location_lat);
[minlon,maxlon] = bounds(data_e_filt.location_long);
minlat = double(minlat);
maxlat = double(maxlat);
minlon = double(minlon);
maxlon = double(maxlon);


% ax = axesm('MapProjection','mercator','MapLatLimit',[minlat,maxlat],'MapLonLimit',[minlon,maxlon]);
% geobasemap('satellite');


m_proj('lambert','lon',[minlon,maxlon],'lat', [minlat,maxlat]);


[CS,CH]=m_etopo2('contourf',[min_elevation:d_elevation:0 0:d_elevation:max_elevation],'edgecolor','none');
 m_grid('linestyle','none','tickdir','out','linewidth',3);

caxis([min_elevation max_elevation]);
colormap([m_colmap('blues',64);m_colmap('gland',128)]);
brighten(.5);

ax=m_contfbar(1,[.5 .8],CS,CH);
% title(ax,{'Level/m',''}); % Move up by inserting a blank line
hold on



%% subselect netcdf data based on eagle data
lat_filter = netcdf_lat >= minlat & netcdf_lat <= maxlat;
lon_filter = netcdf_lon >= minlon & netcdf_lon <= maxlon;
netcdf_lat_filtered = netcdf_lat(lat_filter);
netcdf_lon_filtered = netcdf_lon(lon_filter);
U_filtered = U(lon_filter, lat_filter, :);
V_filtered = V(lon_filter, lat_filter, :);


gridsize_pre_interp = [length(netcdf_lon_filtered) length(netcdf_lat_filtered)];
gridlength_pre_interp = prod(gridsize_pre_interp);


%% interpolate data to numquiver points

% x1 = length(netcdf_lon_filtered);
% x2 = length(netcdf_lat_filtered);
%
% [factors,pos]=intersect(factor(x1), factor(x2));
%
%
% if gridlength_pre_interp < numquivers
%     found_scalar = false;
%     for idx = 1:numquivers
%
%         if found_scalar
%             break
%         end
%         scalar = idx;
%         temp_gridsize = scalar * gridsize_pre_interp;
%
%         if prod(temp_gridsize) >= numquivers
%             found_scalar = true;
%             break
%         end
%         for factor_ = factors
%             scalar = idx + 1 / factor_;
%             temp_gridsize = scalar * gridsize_pre_interp;
%             if prod(temp_gridsize) >= numquivers
%                 found_scalar = true;
%                 break
%             end
%         end
%
%     end
% else
%     scalar = 1;
% end


% interp2(LON,LATflip,double(Uflip),particle.lon,particle.lat);
%
%%
scalar = 1;
lat_resampled = interp1( ...
    linspace(1, length(netcdf_lat_filtered), length(netcdf_lat_filtered)), ...
    netcdf_lat_filtered, ...
    linspace(1, length(netcdf_lat_filtered), length(netcdf_lat_filtered) * scalar));

lon_resampled = interp1( ...
    linspace(1, length(netcdf_lon_filtered), length(netcdf_lon_filtered)), ...
    netcdf_lon_filtered, ...
    linspace(1, length(netcdf_lon_filtered), length(netcdf_lon_filtered) * scalar));

d_lat = mean(-diff(lat_resampled));
d_lon = mean(-diff(lon_resampled));
% [XX, YY, ZZ] = meshgrid(netcdf_lon_filtered,netcdf_lat_filtered,netcdf_time);

[LONq, LATq, TIMEq] = meshgrid(lon_resampled,lat_resampled, netcdf_time);

% we call permute pecause this returns lat lon time orderbut we need it
% in lon lat time order
U_interp = permute(interp3(netcdf_lat_filtered,netcdf_lon_filtered,netcdf_time, U_filtered,LATq, LONq,TIMEq), [2 1 3]);
V_interp = permute(interp3(netcdf_lat_filtered,netcdf_lon_filtered,netcdf_time, V_filtered,LATq, LONq,TIMEq), [2 1 3]);

%% Calculate grid

gridsize = [length(lon_resampled) length(lat_resampled)];
gridlength = prod(gridsize);

[LAT,LON] = meshgrid(lat_resampled, lon_resampled);


%% Assign particle structure

particle.lat = LAT;
particle.lon = LON;
particle.age = zeros(gridsize);
particle.u = U_interp(:,:,1);
particle.v = V_interp(:,:,1);

particle_h = cell(1,max_age);  % cell to hold particles
for p = 1:length(particle_h)
    particle.age = particle.age - 1;
    particle_h{p} = particle;
end

%% Set up for map and animation


% Set up video writer
file_idx = 1;
temp_fn = videoFilename;
while exist(temp_fn,'file')
    temp_fn = strrep(videoFilename, '.avi', string(file_idx) + '.avi');
    file_idx = file_idx + 1;
end
videoFilename = temp_fn;
writer = VideoWriter(videoFilename);
writer.FrameRate = frame_rate;
writer.Quality = 100;
open(writer)


%% Plot particles and calculate new positions based on U & V

numquivers = prod(gridsize);

for timeidx = 1:length(timestamp)

    if timeidx > 1
        for i=1:length(q_cells); delete(q_cells{i}); end
        for i=1:length(h_cells); delete(h_cells{i}); end
        for i=1:length(s_cells); delete(s_cells{i}); end
    end
    q_cells = cell(1,length(particle_h));



    for p = 1:length(particle_h)
        % Update age
        if mod(timeidx, quiver_respawn) == 0
            particle_h{p}.age = particle_h{p}.age + 1;
        end

        if particle_h{p}.age >= 0


            % Calculate velocity vector

            U_ = U_interp(:,:,timeidx);
            V_ = V_interp(:,:,timeidx);


            for i_lat = 1:size(particle_h{p}.lat, 1)
                for j_lat = 1:size(particle_h{p}.lat, 2)
                    l = particle_h{p}.lat(i_lat, j_lat);
                    for i_net_lat = 1:length(lat_resampled)
                        within_range = abs(lat_resampled(i_net_lat) - l) <= d_lat / 2;
                        if within_range
                            particle_h{p}.v(i_lat, j_lat) = V_(i_lat, j_lat);
                            break
                        end
%
%                         if lat_rounded(i_lat, j_lat) == lat_resampled(i_net_lat)
%                             particle_h{p}.v(i_lat, j_lat) = V_(i_lat, j_lat);
%                         end
                    end
                end
            end

            for i_lon = 1:size(particle_h{p}.lon, 1)
                for j_lon = 1:size(particle_h{p}.lon, 2)
                    l = particle_h{p}.lon(i_lon, j_lon);
                    for i_net_lon = 1:length(lon_resampled)
                        within_range = abs(lon_resampled(i_net_lon) - l) <= d_lon / 2;
                        if within_range
                            particle_h{p}.u(i_lon, j_lon) = V_(i_lon, j_lon);
                            break
                        end
%                         if lon_rounded(i_lon, j_lon) == lon_resampled(i_net_lon)
%                             particle_h{p}.u(i_lon, j_lon) = U_(i_lon, j_lon);
%                         end
                    end
                end
            end





             % Update quivers

            quiverh = m_vec(vecscl, particle_h{p}.lon,particle_h{p}.lat,particle_h{p}.u,particle_h{p}.v,[.25, .25, 1],'edgeclip','on');

            alpha_ = 1 - particle_h{p}.age(1) / max_age;
            quiverh.FaceVertexAlphaData = alpha_;
            quiverh.FaceAlpha = 'flat' ;
%             quiverh.EdgeAlpha = alpha_;
            quiverh.LineStyle = 'none';


            q_cells{p} = quiverh;




            % Calculate Next Position
            particle_lon_next = particle_h{p}.lon + speedfactor * particle_h{p}.u;
            particle_lat_next = particle_h{p}.lat + speedfactor * particle_h{p}.v;
            particle_h{p}.lon = particle_lon_next;
            particle_h{p}.lat = particle_lat_next;



          if mod(timeidx, quiver_respawn) == 0
            % Check of out of range and mark those as inactive
            lonoutofrange = (particle_h{p}.lon < minlon) | (particle_h{p}.lon > maxlon);
            latoutofrange = (particle_h{p}.lat < minlat) | (particle_h{p}.lat > maxlat);
            too_old = (particle_h{p}.age > max_age);
             %             particle_h{p}.active = ~(lonoutofrange | latoutofrange | too_old);
            particle_h{p}.active = ~(too_old);

            %             Reassign inactive particles

                for idx = 1:numquivers

                    if ~particle_h{p}.active(idx)
                        particle_h{p}.lat(idx) = LAT(idx);
                        particle_h{p}.lon(idx) = LON(idx);
            % %
                        particle_h{p}.age(idx) = 0;

                    end
                end
            end
        end
    end
            % Update title
            title(string(timestamp(timeidx)));

        h_cells = cell(1,length(inds));
        s_cells = cell(1,length(inds));
        for i=1:length(inds)
            data_ind = c{1,i}{2};


            if (timeidx - npoints) < 1
                oldest_point = 1;
            else
                oldest_point = timeidx - npoints;
            end

            x = data_ind.location_long(oldest_point:timeidx);
            y = data_ind.location_lat(oldest_point:timeidx);


            xseg = [x(1:end-1),x(2:end)];
            yseg = [y(1:end-1),y(2:end)];

            segColors = flipud(hot(size(xseg,1))); % Choose a colormap
            sgamap = logspace(0,1,size(xseg,1));
            sgamap = sgamap/max(sgamap);
            segColors(:,4) = sgamap;

            scatterColors = flipud(hot(size(x,1))); % Choose a colormap
            scamap = logspace(0,1,size(x,1));
            scamap = scamap/max(scamap);



            h = m_plot(xseg',yseg','LineWidth',6);
            s = m_scatter(x, y, 100, scatterColors, 'filled');
            s.AlphaData = scamap;
            s.AlphaDataMapping = 'scaled';
    %         set(s, 'AlphaData', scamap);
    %         set(s, 'Color', scatterColors);
            set(h, {'Color'}, mat2cell(segColors,ones(size(xseg,1),1),4));

            h_cells{i} = h;
            s_cells{i} = s;

        end


        drawnow;

        %% Record movie

    if recordmovie

        % Save the current frame as an RGB image.
        frame = getframe(gcf);


        writeVideo(writer,frame);

        clear frame
    end

end

close(writer)

%%
function [inds,c] = split_tt_by_individual(data, resample_interval)
    data2 = data(:, {'location_lat', 'location_long', 'individual_local_identifier'});
    inds = unique(data2.individual_local_identifier);

    c = cell(1,length(inds));
    for i = 1:length(c), c{1,i} = {inds{i},data2(strcmp(data2.individual_local_identifier, inds{i}), :)}; end

    %resample
    for i = 1:length(c), c{1,i}{2} = resample_track_data(c{1,i}{2}(:, {'location_lat', 'location_long'}), resample_interval); end

end