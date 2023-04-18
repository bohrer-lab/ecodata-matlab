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
        use_simple_plot

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
        particle_h
        q_cells
        quiverh
        minlat
        maxlat
        minlon
        maxlon
        quiver_respawn
        frames

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
                kwargs.quiver_size = 0;
                kwargs.quiver_speed = 1;
                kwargs.quiver_color = ''
                kwargs.use_simple_plot=true
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
                obj.use_simple_plot=kwargs.use_simple_plot;
            end
            % quiver speed is rescaled
            obj.quiver_speed = obj.quiver_speed/100;
            % quiver size is rescaled
            obj.quiver_size= obj.quiver_size/100;
            obj.max_age = 24;
            obj.quiver_respawn = 12;
%             obj.load_time_index();
%             obj.calc_quiver_grid();
            obj.frames = 0;
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
%             obj.particle.lat = obj.LAT;
%             obj.particle.lon = obj.LON;
%             obj.particle.age = 0;
%             obj.particle.u = U;
%             obj.particle.v = V;
%             obj.particle.active = ones(obj.gridsize);

%             obj.particle_h = cell(1, obj.max_age);  % cell to hold particles
%             for p = 1:length(obj.particle_h)
%                 particle.lat = obj.LAT;
%                 particle.lon = obj.LON;
%                 particle.age = p;
% %                 disp(particle.age)
%                 particle.u = U;
%                 particle.v = V;
%                 particle.active = 1;
%                 obj.particle_h{p} = particle;
% %                 obj.particle_h{p}.age = p;
% %                 obj.particle_h{p}.active = obj.particle.age == p;
% 
% % 
% %                 obj.particle.age = obj.particle.age + p;
% %                 obj.particle_h{p} = particle;
%             end

            
%             particle.lat = obj.LAT;
%             particle.lon = obj.LON;
%             particle.age = zeros(obj.gridsize);
%             particle.u = U;
%             particle.v = V;
            rando = randi(obj.max_age, obj.gridsize);
            
            obj.particle_h = cell(1,obj.max_age);  % cell to hold particles
            for p = 1:length(obj.particle_h)
                particle.lat = obj.LAT;
                particle.lon = obj.LON;
                particle.age = p;
                particle.active = rando == p;
                particle.u = U;
                particle.v = V;
                particle.age = p;
                obj.particle_h{p} = particle;
            end
            obj.q_cells = cell(1,length(obj.particle_h));
        end

        function obj = set_quiver_size(obj, U, V)
            disp(obj.quiver_size)
            if obj.quiver_size == 0
                uvmag = abs(U(:,:,1) + i*V(:,:,1));
                M = max(uvmag, [], 'all');

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
             obj.frames = obj.frames + 1;
            if isempty(obj.particle)
                obj.setup_particles(U, V);
            end
            disp(obj.quiver_size)
            if obj.quiver_size == 0
                obj.set_quiver_size(U, V);
            end

            %% Plot particles and calculate new positions based on U & V

            numquivers = prod(obj.gridsize);
            % q_cells = cell(1,length(particle_h));
            for p = 1:length(obj.particle_h)
%                 if mod(obj.frames, obj.quiver_respawn) == 0
                    obj.particle_h{p}.age = obj.particle_h{p}.age + 1;
%                 end
%                 obj.particle_h{p}.age = obj.particle_h{p}.age + 1;
                % Calculate velocity vector
%                 if obj.particle_h{p}.age(1) >= 0  % && mod(obj.particle_h{p}.age, obj.quiver_respawn) == 0)

                for i_lat = 1:size(obj.particle_h{p}.lat, 1)
                    for j_lat = 1:size(obj.particle_h{p}.lat, 2)
                        l = obj.particle_h{p}.lat(i_lat, j_lat);
            %                     for i_net_lat = 1:length(LAT)
                        for i_net_lat = 1:length(obj.lat)
            %                         disp(l)
                            within_range = abs(obj.lat(i_net_lat) - l) <= obj.d_lat/2;
            %                         disp(within_range)
                            if within_range
            %                             disp(within_range)
            %                     obj.particle_h{p}.v(i_lat, j_lat) = V(i_lat, j_lat);
                                break
                            end
                        end
                    end
                end

                for i_lon = 1:size(obj.particle_h{p}.lon, 1)
                    for j_lon = 1:size(obj.particle_h{p}.lon, 2)
                        l = obj.particle_h{p}.lon(i_lon, j_lon);
                        for i_net_lon = 1:length(obj.lon)
                            within_range = abs(obj.lon(i_net_lon) - l) <= obj.d_lon/2;
                            if within_range
            %                     obj.particle_h{p}.u(i_lon, j_lon) = U(i_lon, j_lon);
                                break
                            end
                        end
                    end
                end

                obj.particle_h{p}.v(i_lon, j_lon) = V(i_net_lon, i_net_lat);
                obj.particle_h{p}.u(i_lon, j_lon) = U(i_net_lon, i_net_lat);


                % Calculate Next Position
%                 if mod(obj.particle_h{p}.age, obj.quiver_respawn) == 0
                    particle_lon_next = obj.particle_h{p}.lon + obj.quiver_speed  * obj.particle_h{p}.u;
                    particle_lat_next = obj.particle_h{p}.lat + obj.quiver_speed  * obj.particle_h{p}.v;
                    obj.particle_h{p}.lon = particle_lon_next;
                    obj.particle_h{p}.lat = particle_lat_next;
%                 end

%         if mod(obj.frames, obj.quiver_respawn) == 0
            lonoutofrange = (obj.particle_h{p}.lon < obj.minlon) | (obj.particle_h{p}.lon > obj.maxlon);
            latoutofrange = (obj.particle_h{p}.lat < obj.minlat) | (obj.particle_h{p}.lat > obj.maxlat);
            too_old = (obj.particle_h{p}.age >= obj.max_age);
             %             particle_h{p}.active = ~(lonoutofrange | latoutofrange | too_old);
%             obj.particle_h{p}.active = ~(too_old);

            %             Reassign inactive particles

%                 for idx = 1:numquivers

%                     if ~obj.particle_h{p}.active
%                         obj.particle_h{p}.lat(idx) = obj.LAT(idx);
%                         obj.particle_h{p}.lon(idx) = obj.LON(idx);
%             % %
%                         obj.particle_h{p}.age(idx) = 0;
% 
%                     end
                    if too_old
                        obj.particle_h{p}.lat  = obj.LAT;
                        obj.particle_h{p}.lon = obj.LON;
            % %
                        obj.particle_h{p}.age = 1;
                    end
%                 end
%         end
            
            end
        end


        function obj = plot(obj)
            vecscl = 1/obj.quiver_size;
%             disp(vecscl)
%             vecscl = 150;
            for p = 1:length(obj.particle_h)
%                 if mod(obj.particle_h{p}.age, obj.quiver_respawn) == 0
                    alpha_ = (max(1 - obj.particle_h{p}.age(1) / obj.max_age, 0));
                    if alpha_ > 1
                        alpha_ = 1;
                    end
%                     disp(alpha_)
                    lon = obj.particle_h{p}.lon;
                    lon(obj.particle_h{p}.active == 0) = 0;
                    lat = obj.particle_h{p}.lat;
                    lat(obj.particle_h{p}.active == 0) = 0;
                    u = obj.particle_h{p}.u;
                    u(obj.particle_h{p}.active == 0) = 0;
                    v = obj.particle_h{p}.v;
                    v(obj.particle_h{p}.active == 0) = 0;

                    quiverh = m_vec(vecscl, ...
                        lon, ...
                        lat, ...
                        u, ...
                        v, ...
                        obj.quiver_color, ...
                        'edgeclip','on', ...
                        'FaceVertexAlphaData',alpha_, ...
                        'FaceAlpha', 'flat', ...
                        'LineStyle', 'none');
        
                        
%                     quiverh = m_vec(vecscl, ...
%                         obj.particle_h{p}.lon(obj.particle_h{p}.active), ...
%                         obj.particle_h{p}.lat(obj.particle_h{p}.active), ...
%                         obj.particle_h{p}.u(obj.particle_h{p}.active), ...
%                         obj.particle_h{p}.v(obj.particle_h{p}.active), ...
%                         obj.quiver_color, ...
%                         'edgeclip','on', ...
%                         'FaceVertexAlphaData',alpha_, ...
%                         'FaceAlpha', 'flat', ...
%                         'LineStyle', 'none');
        

                    
%                     quiverh.FaceVertexAlphaData = alpha_;
%                     quiverh.FaceAlpha = 'flat';
%                     quiverh.EdgeAlpha = alpha_;
%                     quiverh.LineStyle = '-';
%                     obj.quiverh.AlphaDataMapping = 'none';
                    obj.q_cells{p} = quiverh;
%                 end
            end
        end

    end
end
