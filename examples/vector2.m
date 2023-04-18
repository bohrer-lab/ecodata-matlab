function [] = vector2(quivers, U, V)
%VECTOR Summary of this function goes here

quiver_speed = quivers.quiver_speed/100;

%% Plot particles and calculate new positions based on U & V

numquivers = prod(quivers.gridsize);
% q_cells = cell(1,length(particle_h));

    % Calculate velocity vector

    for i_lat = 1:size(quivers.particle.lat, 1)
        for j_lat = 1:size(quivers.particle.lat, 2)
            l = quivers.particle.lat(i_lat, j_lat);
%                     for i_net_lat = 1:length(LAT)
            for i_net_lat = 1:length(quivers.lat)
%                         disp(l)
                within_range = abs(quivers.lat(i_net_lat) - l) <= quivers.d_lat/2;
%                         disp(within_range)
                if within_range
%                             disp(within_range)
%                     quivers.particle.v(i_lat, j_lat) = V(i_lat, j_lat);
                    break
                end
            end
        end
    end

    for i_lon = 1:size(quivers.particle.lon, 1)
        for j_lon = 1:size(quivers.particle.lon, 2)
            l = quivers.particle.lon(i_lon, j_lon);
            for i_net_lon = 1:length(quivers.lon)
                within_range = abs(quivers.lon(i_net_lon) - l) <= quivers.d_lon/2;
                if within_range
%                     quivers.particle.u(i_lon, j_lon) = U(i_lon, j_lon);
                    break
                end
            end
        end
    end
%     disp(U(i_net_lon, i_net_lat))
%     disp(quivers.particle.u(i_lon, j_lon))
    quivers.particle.v(i_lon, j_lon) = V(i_net_lon, i_net_lat);
    quivers.particle.u(i_lon, j_lon) = U(i_net_lon, i_net_lat);
%     disp(particle.u(i_lon, j_lon))





     % Update quivers
%             vecscl=1/quivers.quiver_size; % quiver vector scalar param (inverse of size, bigger = smaller)

%     [plot_lon, plot_lat] = m_ll2xy(particle.lon, particle.lat);


%     disp("calling m_vec")

%     quiverh = m_vec(vecscl, particle.lon,particle.lat,particle.u,particle.v,[.25, .25, 1],'edgeclip','on');
% %             quiverh = quiver(plot_lon, plot_lat, particle.u, particle.v, 'color', [1 0 0 0.1]);
% 
% %     drawnow;
%     alpha_ = max(1 - particle.age(1) / quivers.max_age, 0);
% %             disp(particle.age(1))
% %             disp(particle.age(1)/quivers.max_age)
% %             disp(quivers.max_age)
% %             disp(alpha_)
%     quiverh.FaceVertexAlphaData = alpha_;
%     quiverh.FaceAlpha = 'flat' ;
%     quiverh.EdgeAlpha = alpha_;
%     quiverh.LineStyle = 'none';
%     quiverh.AlphaDataMapping = 'none';


%     q_cells{p} = quiverh;


    % Calculate Next Position
    particle_lon_next = quivers.particle.lon + quiver_speed * quivers.particle.u;
    particle_lat_next = quivers.particle.lat + quiver_speed * quivers.particle.v;
    quivers.particle.lon = particle_lon_next;
    quivers.particle.lat = particle_lat_next;


    % Check of out of range and mark those as inactive
    lonoutofrange = (quivers.particle.lon < quivers.minlon) | (quivers.particle.lon > quivers.maxlon);
    latoutofrange = (quivers.particle.lat < quivers.minlat) | (quivers.particle.lat > quivers.maxlat);
    too_old = (quivers.particle.age >= quivers.max_age);
    quivers.particle.active = ~(lonoutofrange | latoutofrange | too_old);

    % Reassign inactive particles

    for idx = 1:numquivers

        if ~quivers.particle.active(idx)
            quivers.particle.lat(idx) = quivers.LAT(idx);
            quivers.particle.lon(idx) = quivers.LON(idx);
% %
            quivers.particle.age(idx) = 0;

        end
    end
quivers.particle.age = quivers.particle.age + 1;

% Update title

% delete(quiverh)

% for i=1:length(q_cells); delete(q_cells{i}); end
    % for i=1:length(h_cells); delete(h_cells{i}); end
    % for i=1:length(s_cells); delete(s_cells{i}); end

end
