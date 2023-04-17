classdef Quivers < handle
    properties
        filename
        latvar
        lonvar
        timevar
        u_var  % u vector component
        v_var  % v vector component

        quiver_size  % Size of quivers
        quiver_speed  % Speed of quivers, scaled with u&v
        quiver_color

        varnames
        time_index
        dt

        max_age % Lifespan (max number of timesteps) before resetting a quiver
        lat
        lon
        d_lat
        d_lon
        gridsize
        gridlength
        LAT
        LON
        particle
        quiverh
        minlat
        maxlat
        minlon
        maxlon

    end

    methods

        function obj = Quivers(filein, kwargs)
            % Constructor
            arguments
                filein
                kwargs.latvar = ''
                kwargs.lonvar = ''
                kwargs.timevar = ''
                kwargs.u_var = ''
                kwargs.v_var = ''
                kwargs.quiver_size = .02;
                kwargs.quiver_speed = 10;
                kwargs.quiver_color = ''
            end

            if nargin > 0
                obj.filename = filein;
                obj.latvar = kwargs.latvar;
                obj.lonvar = kwargs.lonvar;
                obj.timevar = kwargs.timevar;
                obj.u_var = kwargs.u_var;
                obj.v_var = kwargs.v_var;
                obj.varnames = {ncinfo(filein).Variables.Name};
                obj.quiver_size = kwargs.quiver_size;
                obj.quiver_speed = kwargs.quiver_speed;
                obj.quiver_color = kwargs.quiver_color;
            end
            % quiver speed is rescaled
            obj.quiver_speed = obj.quiver_speed/100;
            obj.max_age = 10;
            obj.load_time_index();
            obj.calc_quiver_grid();
            obj.set_quiver_size();
        end

        function obj = load_time_index(obj)
            if ~isempty(obj.timevar)
                obj.time_index = read_nc_timestamps(obj.filename, obj.timevar);
                obj.dt = obj.time_index(2) - obj.time_index(1);
            end
        end

        function obj = calc_quiver_grid(obj)
            obj.lat = double(ncread(obj.filename, obj.latvar));
            obj.lon = double(ncread(obj.filename, obj.lonvar));
            obj.d_lat = abs(obj.lat(2) - obj.lat(1));
            obj.d_lon = abs(obj.lon(2) - obj.lon(1));

            obj.gridsize = [length(obj.lon) length(obj.lat)];
            obj.gridlength = prod(obj.gridsize);
            [obj.LAT, obj.LON] = meshgrid(obj.lat, obj.lon);

            if isempty(obj.minlat)
                obj.minlat = min(obj.lat);
            end
            if isempty(obj.maxlat)
                obj.maxlat = max(obj.lat);
            end
            if isempty(obj.minlon)
                obj.minlon = min(obj.lon);
            end
            if isempty(obj.maxlon)
                obj.maxlon = max(obj.lon);
            end
        end

        function obj = update_bbox(obj, latlim, lonlim)
            arguments
                obj
                latlim = [];
                lonlim = [];
            end
            if ~isempty(latlim)
                obj.minlat = latlim(1);
                obj.maxlat = latlim(2);
            end

            if ~isempty(lonlim)
                obj.minlon = lonlim(1);
                obj.maxlon = lonlim(2);
            end
        end

        function obj = setup_particles(obj, U, V)
            obj.particle.lat = obj.LAT;
            obj.particle.lon = obj.LON;
            obj.particle.age = randi([0 obj.max_age],obj.gridsize);
            obj.particle.u = U;
            obj.particle.v = V;
            obj.particle.active = ones(obj.gridsize);
        end

        function obj = set_quiver_size(obj)

            if obj.quiver_size == 0
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

                L = 1/20;

                vecscl = M*sc/L;
                obj.quiver_size = 1/vecscl;
            end
        end


        function obj = move_particles(obj, U, V)

            if isempty(obj.particle)
                obj.setup_particles(U, V);
            end

            %% Plot particles and calculate new positions based on U & V

            numquivers = prod(obj.gridsize);
            % q_cells = cell(1,length(particle_h));

                % Calculate velocity vector

                for i_lat = 1:size(obj.particle.lat, 1)
                    for j_lat = 1:size(obj.particle.lat, 2)
                        l = obj.particle.lat(i_lat, j_lat);
            %                     for i_net_lat = 1:length(LAT)
                        for i_net_lat = 1:length(obj.lat)
            %                         disp(l)
                            within_range = abs(obj.lat(i_net_lat) - l) <= obj.d_lat/2;
            %                         disp(within_range)
                            if within_range
            %                             disp(within_range)
            %                     obj.particle.v(i_lat, j_lat) = V(i_lat, j_lat);
                                break
                            end
                        end
                    end
                end

                for i_lon = 1:size(obj.particle.lon, 1)
                    for j_lon = 1:size(obj.particle.lon, 2)
                        l = obj.particle.lon(i_lon, j_lon);
                        for i_net_lon = 1:length(obj.lon)
                            within_range = abs(obj.lon(i_net_lon) - l) <= obj.d_lon/2;
                            if within_range
            %                     obj.particle.u(i_lon, j_lon) = U(i_lon, j_lon);
                                break
                            end
                        end
                    end
                end

                obj.particle.v(i_lon, j_lon) = V(i_net_lon, i_net_lat);
                obj.particle.u(i_lon, j_lon) = U(i_net_lon, i_net_lat);


                % Calculate Next Position
                particle_lon_next = obj.particle.lon + obj.quiver_speed  * obj.particle.u;
                particle_lat_next = obj.particle.lat + obj.quiver_speed  * obj.particle.v;
                obj.particle.lon = particle_lon_next;
                obj.particle.lat = particle_lat_next;


                % Check of out of range and mark those as inactive
                lonoutofrange = (obj.particle.lon < obj.minlon) | (obj.particle.lon > obj.maxlon);
                latoutofrange = (obj.particle.lat < obj.minlat) | (obj.particle.lat > obj.maxlat);
                too_old = (obj.particle.age >= obj.max_age);
                obj.particle.active = ~(lonoutofrange | latoutofrange | too_old);

                % Reassign inactive particles
                for idx = 1:numquivers

                    if ~obj.particle.active(idx)
                        obj.particle.lat(idx) = obj.LAT(idx);
                        obj.particle.lon(idx) = obj.LON(idx);
                        obj.particle.age(idx) = 0;

                    end
                end
            obj.particle.age = obj.particle.age + 1;
        end


        function obj = plot(obj)
            vecscl = 1/obj.quiver_size;
            obj.quiverh = m_vec(vecscl, obj.particle.lon,obj.particle.lat,obj.particle.u,obj.particle.v,obj.quiver_color,'edgeclip','on');

            alpha_ = max(1 - obj.particle.age(1) / obj.max_age, 0);

            obj.quiverh.FaceVertexAlphaData = alpha_;
            obj.quiverh.FaceAlpha = alpha_;
            obj.quiverh.EdgeAlpha = alpha_;
            obj.quiverh.LineStyle = '-';
            obj.quiverh.AlphaDataMapping = 'none';
        end

    end
end
