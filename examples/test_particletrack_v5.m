
% Parameters (general)
minlat = 34.65;
maxlat = 66.77;
minlon = -154.77;
maxlon = -106.89;


start_lon = 0;
end_lon = 0;
start_lat = 0;
end_lat = 0;
%
start_date = datetime("15-May-2004");
end_date = datetime("20-May-2004");


% parameters (wind)
max_age = 4; % max timesteps before resetting a quiver

quiver_respawn = 12;
quiver_size = 1;
quiver_speed = 1;     % Speed of particles scaled with U & V.


% directory for wind data netcdf

netcdf_path = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/eagle_ds_2004_thinned2.nc';


quiver_size = quiver_size/100;
quiver_speed = quiver_speed/100;

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




ts_diff = timestamp(2) - timestamp(1);
start_time = min(timestamp);
end_time = max(timestamp);


%% Initialize figure

fig = figure;


m_proj('lambert','lon',[minlon,maxlon],'lat', [minlat,maxlat]);


hold on



gridsize_pre_interp = [length(netcdf_lon) length(netcdf_lat)];
gridlength_pre_interp = prod(gridsize_pre_interp);


scalar = 1;
lat_resampled = interp1( ...
    linspace(1, length(netcdf_lat), length(netcdf_lat)), ...
    netcdf_lat, ...
    linspace(1, length(netcdf_lat), length(netcdf_lat) * scalar));

lon_resampled = interp1( ...
    linspace(1, length(netcdf_lon), length(netcdf_lon)), ...
    netcdf_lon, ...
    linspace(1, length(netcdf_lon), length(netcdf_lon) * scalar));

d_lat = mean(-diff(lat_resampled));
d_lon = mean(-diff(lon_resampled));
% [XX, YY, ZZ] = meshgrid(netcdf_lon,netcdf_lat,netcdf_time);

[LONq, LATq, TIMEq] = meshgrid(lon_resampled,lat_resampled, netcdf_time);

% we call permute pecause this returns lat lon time orderbut we need it
% in lon lat time order
U_interp = permute(interp3(netcdf_lat,netcdf_lon,netcdf_time, U,LATq, LONq,TIMEq), [2 1 3]);
V_interp = permute(interp3(netcdf_lat,netcdf_lon,netcdf_time, V,LATq, LONq,TIMEq), [2 1 3]);

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
            vecscl=1/quiver_size; % quiver vector scalar param (inverse of size, bigger = smaller)

            quiverh = m_vec(vecscl, particle_h{p}.lon,particle_h{p}.lat,particle_h{p}.u,particle_h{p}.v,[.25, .25, 1],'edgeclip','on');

            alpha_ = 1 - particle_h{p}.age(1) / max_age;
            quiverh.FaceVertexAlphaData = alpha_;
            quiverh.FaceAlpha = 'flat' ;
%             quiverh.EdgeAlpha = alpha_;
            quiverh.LineStyle = 'none';


            q_cells{p} = quiverh;




            % Calculate Next Position
            particle_lon_next = particle_h{p}.lon + quiver_speed * particle_h{p}.u;
            particle_lat_next = particle_h{p}.lat + quiver_speed * particle_h{p}.v;
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


        drawnow;

end



