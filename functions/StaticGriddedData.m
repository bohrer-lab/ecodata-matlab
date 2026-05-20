classdef StaticGriddedData < handle
    % A cached 2-D gridded field from a NetCDF (no time dimension)
    % API-compatible shim for time-aware pipelines: exposes 'timevar'
    % and related fields but ignores them internally.

    properties
        % Config
        filename
        latvar
        lonvar
        var_of_interest

        % Colormap (accepts either an Nx3 double map or a name; stored as Nx3)
        cmap
        invert_cmap (1,1) logical = false
        cbar_limits
        show_colorbar (1,1) logical = true

        % --- Compatibility properties (time-related; ignored for static layers)
        timevar char = ''          % kept only so animator code can assign to it
        time_values = []           % no time axis here
        time_index (1,1) double = NaN

        % Cached data
        lat
        lon
        field2d
        is_loaded = false
    end

    methods
        function obj = StaticGriddedData(filein, kwargs)
            % kwargs: latvar, lonvar, var_of_interest,
            %         cmap (Nx3 or name string), invert_cmap (logical),
            %         cbar_limits (1x2 or []), show_colorbar (logical),
            %         timevar (char/string, optional; ignored in logic)
            arguments
                filein
                kwargs.latvar
                kwargs.lonvar
                kwargs.var_of_interest
                kwargs.cmap = parula(256)
                kwargs.invert_cmap (1,1) logical = false
                kwargs.cbar_limits = []
                kwargs.show_colorbar (1,1) logical = true
                kwargs.timevar = ''      % allow passing but ignore functionally
            end
            

            obj.filename        = filein;
            obj.latvar          = kwargs.latvar;
            obj.lonvar          = kwargs.lonvar;
            obj.var_of_interest = kwargs.var_of_interest;
            obj.cmap            = kwargs.cmap;   
            obj.invert_cmap     = kwargs.invert_cmap;
            obj.cbar_limits     = kwargs.cbar_limits;
            obj.show_colorbar   = kwargs.show_colorbar;

            % Normalize cmap: allow either a name or an Nx3 array
            if ischar(kwargs.cmap) || isstring(kwargs.cmap)
                name = lower(char(kwargs.cmap));
                % 1) (supports 'blue','green','diverging','jet', etc.)
                try
                    obj.cmap = s_colmap(name, 256);
                catch
                    % 2) colormaps
                    try
                        obj.cmap = feval(name, 256);
                    catch
                        warning('StaticGriddedData:cmapName', ...
                            'Unrecognized colormap "%s". Falling back to parula(256).', name);
                        obj.cmap = parula(256);
                    end
                end
            else
                % Nx3
                obj.cmap = kwargs.cmap;
            end

            obj.invert_cmap    = kwargs.invert_cmap;
            obj.cbar_limits    = kwargs.cbar_limits;
            obj.show_colorbar  = kwargs.show_colorbar;

            % Keep timevar only for API compatibility
            if ~isempty(kwargs.timevar)
                obj.timevar = char(kwargs.timevar);
            end
        end

        function load(obj)
            % Read and cache the 2-D field (and lat/lon).
            if obj.is_loaded
                return
            end

            [lat, lon, field2d] = read_nc_2d( ...
                obj.filename, obj.latvar, obj.lonvar, obj.var_of_interest);

            % Ensure latitude ascending; if flipped, flip data too.
            if numel(lat) > 1 && lat(1) > lat(end)
                lat     = flipud(lat);
                field2d = flipud(field2d);
            end

            obj.lat      = lat;
            obj.lon      = lon;
            obj.field2d  = field2d;
            obj.is_loaded = true;
        end

        % -------- Optional convenience for code that queries "has time?"
        function tf = has_time(obj) %
            tf = false; % static layer: no time axis
        end

        function A = current_frame(obj)
            % For compatibility with frame-based drawers in animator
            if ~obj.is_loaded
                obj.load();
            end
            A = obj.field2d;
        end

        function load_time_index(obj) %
            % Static (no time axis) – for compatibility.
        end
    end


end
