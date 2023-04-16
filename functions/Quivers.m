classdef Quivers < handle
    properties
        filename
        latvar
        lonvar
        timevar
        u_var  % u vector component
        v_var  % v vector component

        quiver_lifespan % Lifespan (max number of timesteps) before resetting a quiver
        quiver_respawn_interval  % interval (in number of timesteps) for which quivers will respawn
        quiver_size  % Size of quivers
        quiver_speed  % Speed of quivers, scaled with u&v
        quiver_color

        varnames
        time_index
        dt

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
                kwargs.quiver_lifespan = 4;
                kwargs.quiver_respawn_interval = 4;
                kwargs.quiver_size = 1;
                kwargs.quiver_speed = 1;
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
                obj.quiver_lifespan = kwargs.quiver_lifespan;
                obj.quiver_respawn_interval = kwargs.quiver_respawn_interval;
                obj.quiver_size = kwargs.quiver_size;
                obj.quiver_speed = kwargs.quiver_speed;
                obj.quiver_color = kwargs.quiver_color;
            end
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
            obj.d_lat = mean(abs(diff(obj.lat)));
            obj.d_lon = mean(abs(diff(obj.lon)));

            obj.gridsize = [length(obj.lon) length(obj.lat)];
            obj.gridlength = prod(obj.gridsize);
            [obj.LAT, obj.LON] = meshgrid(obj.lat, obj.lon);
        end


    end
end
