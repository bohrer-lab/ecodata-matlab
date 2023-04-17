% Parameters (general)
minlat = 34.65;
maxlat = 66.77;
minlon = -154.77;
maxlon = -106.89;

start_date = datetime("15-May-2004");
end_date = datetime("20-May-2004");

% parameters (wind)
max_age = 10; % max timesteps before resetting a quiver

% quiver_size = .01;
quiver_size = 0;
quiver_speed = 10;     % Speed of particles scaled with U & V.

% directory for wind data netcdf
netcdf_path = '/Users/madelinescyphers/Documents/projs_.nosync/movebank_vis/data/user_datasets/eagle_ds_2004_thinned2.nc';

% quiver speed is rescaled
quiver_speed = quiver_speed/100;


%% Load and process files

netcdf_lat = double(ncread(netcdf_path, "latitude"));
netcdf_lon = double(ncread(netcdf_path, "longitude"));

d_lat = abs(netcdf_lat(2) - netcdf_lat(1));
d_lon = abs(netcdf_lon(2) - netcdf_lon(1));

%% Read in U & V

U = ncread(netcdf_path, "u10");
V = ncread(netcdf_path, "v10");
netcdf_time = double(ncread(netcdf_path, "time"));
timestamp = datetime(datevec(netcdf_time/24 + datenum('1900-01-01 00:00:00')));

%% calc vecscl
% quiver vector scalar param (inverse of size, bigger = smaller)

if quiver_size == 0
    uvmag = abs(U(:,:,1) + i*V(:,:,1));
    [M,I] = max(uvmag, [], 'all');
    
    OrigAxUnits = get(gca,'Units');
    if OrigAxUnits(1:3) == 'nor'
       OrigPaUnits = get(gcf, 'paperunits');
       set(gcf, 'paperunits', 'inches');
       figposInches = get(gcf, 'paperposition');
       set(gcf, 'paperunits', OrigPaUnits);
       axposNor = get(gca, 'position');
       axWidLenInches = axposNor(3:4) .* figposInches(3:4);
    else
       set(gca, 'units', 'inches');
       axposInches = get(gca, 'position');
       set(gca, 'units', OrigAxUnits);
       axWidLenInches = axposInches(3:4);
    end
    
    % Multiply inches by the following to get data units:
    scX = diff(get(gca, 'XLim'))/axWidLenInches(1);
    scY = diff(get(gca, 'YLim'))/axWidLenInches(2);
    sc = max([scX;scY]);  %max selects the dimension limited by
                          % the plot box.
    
    L = 1/30;
    
    vecscl = M*sc/L;
else
    vecscl = 1/quiver_size;
end

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

%% Initialize figure

fig = figure;


m_proj('lambert','lon',[minlon,maxlon],'lat', [minlat,maxlat]);


hold on

%% Calculate grid

% % we call permute pecause this returns lat lon time orderbut we need it
% % in lon lat time order
% U_interp = permute(interp3(netcdf_lat,netcdf_lon,netcdf_time, U,LATq, LONq,TIMEq), [2 1 3]);
% V_interp = permute(interp3(netcdf_lat,netcdf_lon,netcdf_time, V,LATq, LONq,TIMEq), [2 1 3]);

[LAT,LON] = meshgrid(netcdf_lat, netcdf_lon);

gridsize = [length(netcdf_lon) length(netcdf_lat)];

%% Assign particle structure

particle.lat = LAT;
particle.lon = LON;
particle.age = zeros(gridsize);
particle.u = U(:,:,1);
particle.v = V(:,:,1);

particle_h = cell(1,max_age);  % cell to hold particles
for p = 1:length(particle_h)
    particle.age = randi([0 max_age],gridsize);
    particle_h{p} = particle;
end


%% Plot particles and calculate new positions based on U & V

numquivers = prod(gridsize);


for timeidx = 1:length(timestamp)

    if timeidx > 1
        for i=1:length(q_cells); delete(q_cells{i}); end
        % for i=1:length(h_cells); delete(h_cells{i}); end
        % for i=1:length(s_cells); delete(s_cells{i}); end
    end
    q_cells = cell(1,length(particle_h));



    for p = 1:length(particle_h)
        % Update age
%         if mod(timeidx, quiver_respawn) == 0
%             particle_h{p}.age = particle_h{p}.age + 1;
%         end


        if particle_h{p}.age > 0


            % Calculate velocity vector

            U_ = U(:,:,timeidx);
            V_ = V(:,:,timeidx);


            for i_lat = 1:size(particle_h{p}.lat, 1)
                for j_lat = 1:size(particle_h{p}.lat, 2)
                    l = particle_h{p}.lat(i_lat, j_lat);
%                     for i_net_lat = 1:length(LAT)
                    for i_net_lat = 1:length(netcdf_lat)
%                         disp(l)
                        within_range = abs(netcdf_lat(i_net_lat) - l) <= d_lat/2;
%                         disp(within_range)
                        if within_range
%                             disp(within_range)
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
                    for i_net_lon = 1:length(netcdf_lon)
                        within_range = abs(netcdf_lon(i_net_lon) - l) <= d_lon/2;
                        if within_range
                            particle_h{p}.u(i_lon, j_lon) = U_(i_lon, j_lon);
                            break
                        end
%                         if lon_rounded(i_lon, j_lon) == lon_resampled(i_net_lon)
%                             particle_h{p}.u(i_lon, j_lon) = U_(i_lon, j_lon);
%                         end
                    end
                end
            end





             % Update quivers
%             vecscl=1/quiver_size; % quiver vector scalar param (inverse of size, bigger = smaller)

            [plot_lon, plot_lat] = m_ll2xy(particle_h{p}.lon, particle_h{p}.lat);


            quiverh = m_vec(vecscl, particle_h{p}.lon,particle_h{p}.lat,particle_h{p}.u,particle_h{p}.v,[.25, .25, 1],'edgeclip','on');
%             quiverh = quiver(plot_lon, plot_lat, particle_h{p}.u, particle_h{p}.v, 'color', [1 0 0 0.1]);

            
            alpha_ = max(1 - particle_h{p}.age(1) / max_age, 0);
%             disp(particle_h{p}.age(1))
%             disp(particle_h{p}.age(1)/max_age)
%             disp(max_age)
%             disp(alpha_)
            quiverh.FaceVertexAlphaData = alpha_;
            quiverh.FaceAlpha = 'flat' ;
            quiverh.EdgeAlpha = alpha_;
            quiverh.LineStyle = 'none';
            quiverh.AlphaDataMapping = 'none';


            q_cells{p} = quiverh;


            % Calculate Next Position
            particle_lon_next = particle_h{p}.lon + quiver_speed * particle_h{p}.u;
            particle_lat_next = particle_h{p}.lat + quiver_speed * particle_h{p}.v;
            particle_h{p}.lon = particle_lon_next;
            particle_h{p}.lat = particle_lat_next;


            % Check of out of range and mark those as inactive
            lonoutofrange = (particle_h{p}.lon < minlon) | (particle_h{p}.lon > maxlon);
            latoutofrange = (particle_h{p}.lat < minlat) | (particle_h{p}.lat > maxlat);
            too_old = (particle_h{p}.age >= max_age);
            particle_h{p}.active = ~(lonoutofrange | latoutofrange | too_old);

            % Reassign inactive particles

            for idx = 1:numquivers

                if ~particle_h{p}.active(idx)
                    particle_h{p}.lat(idx) = LAT(idx);
                    particle_h{p}.lon(idx) = LON(idx);
        % %
                    particle_h{p}.age(idx) = 0;

                end
            end
        end
        particle_h{p}.age = particle_h{p}.age + 1;
    end

            % Update title
            title(string(timestamp(timeidx)));


        drawnow;
end