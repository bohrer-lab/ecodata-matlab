function generate_frame(tracks, frame_time, kwargs)
    arguments
        tracks
        frame_time
        kwargs.gridded_data = {}
        kwargs.contour_data = containers.Map()
        kwargs.quiver_data = {}
        kwargs.elevation = containers.Map()
        kwargs.shapefile_stack = {}
        kwargs.raster_image = NaN
        kwargs.raster_cmap = NaN
        kwargs.labeled_points = containers.Map()
        kwargs.output_directory
        kwargs.start_time
        kwargs.end_time
        kwargs.frame_resolution = 600
        kwargs.latlim = NaN;
        kwargs.lonlim = NaN;
        kwargs.frame_number = 0;
        kwargs.show_legend=true;
        kwargs.global_size_q = []
        kwargs.global_color_breaks = []
        kwargs.global_color_cmin = []
        kwargs.global_color_cmax = []
    end



    %% Set up for map
    % need to add space for custom legend
     
    oldDefaultFigureVisible = get(groot, 'DefaultFigureVisible');
    set(groot, 'DefaultFigureVisible', 'off');

    fig = figure( ...
        'Visible', 'off', ...
        'Color', 'w', ...
        'Units', 'pixels', ...
        'Position', [100 100 1600 900]);
    
    % Main map axes (reserve space on the right for colorbar + legend)
    map_ax = axes( ...
        'Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [0.06 0.08 0.72 0.84]);
    
    % [2026a compatibility] axes(map_ax);
    set(fig, 'CurrentAxes', map_ax); 
    
    % Map projection
    m_proj('Cylindrical Equal-Area', 'lat', kwargs.latlim, 'long', kwargs.lonlim)
    
    hold on


    last_env_cmap = [];
    % Holders for custom presence legends
    presence_size_title  = '';
    presence_size_sizes  = [];
    presence_size_labels = {};
    
    presence_color_title  = '';
    presence_color_colors = [];
    presence_color_labels = {};
    %% Plot gridded env data
    if ~isempty(kwargs.gridded_data)
        % Case A: static field (no time case) 
        if isa(kwargs.gridded_data, 'StaticGriddedData')
            gd = kwargs.gridded_data;
            if ~gd.is_loaded
                gd.load();
            end
    
            % Take field and enforce 2-D numeric
            field = gd.field2d;
    
            if ~isnumeric(field)
                error('StaticGriddedData:FieldNotNumeric', ...
                    'gd.field2d must be numeric, got %s', class(field));
            end
    
            if ndims(field) > 2
                field = squeeze(field);
            end
    
            if ~ismatrix(field)
                error('StaticGriddedData:FieldNot2D', ...
                    'gd.field2d must be 2-D after squeeze, got ndims=%d', ndims(field));
            end
    
            lat = gd.lat;
            lon = gd.lon;
    
            nlat = numel(lat);
            nlon = numel(lon);
    
            if nlat ~= size(field,1) || nlon ~= size(field,2)
                error('StaticGriddedData:SizeMismatch', ...
                    'size(field)=[%d %d], numel(lat)=%d, numel(lon)=%d', ...
                    size(field,1), size(field,2), nlat, nlon);
            end
    
            [LonGrid,LatGrid] = meshgrid(lon, lat);
            [X, Y] = m_ll2xy(LonGrid, LatGrid);
    
            h_env = pcolor(X, Y, field);
            set(h_env, 'EdgeColor', 'none');
    
            % Colormap
            cmap_here = s_resolve_cmap(gd.cmap, 256);
            if gd.invert_cmap
                cmap_here = flipud(cmap_here);
            end
            colormap(cmap_here);
            last_env_cmap = cmap_here;
    
            % CLim & colorbar
            if ~isempty(gd.cbar_limits)
                caxis(gd.cbar_limits);
            end
    
            if gd.show_colorbar
                env_cb = colorbar;
                env_cb.Units = 'normalized';
                env_cb.Position = [0.81 0.12 0.02 0.78];
            end
    
            freezeColors(map_ax);
            hold on;

    
        % Case B: time-varying field (legacy GriddedData)
        else
            gd = kwargs.gridded_data;

            if isempty(gd.time_index)
                gd.load_time_index;
            end

            % Find the nearest available environmental timestamp
            if isempty(gd.time_index)
                error('GriddedData:NoTimeIndex', ...
                    'No time index available for gridded data.');
            end

            times_before_frame = gd.time_index(gd.time_index <= frame_time);

            if isempty(times_before_frame)
                current_idx = 1;
            else
                [~, rel_idx] = min(abs(times_before_frame - frame_time));
                current_idx = rel_idx;
            end

            % Read one slice
            [lat, lon, ~, raw_slice] = unpack_netcdf( ...
                gd.filename, ...
                gd.latvar, ...
                gd.lonvar, ...
                gd.timevar, ...
                gd.var_of_interest, ...
                start=current_idx, count=1);

            % Reduce to 2-D
            raw_slice = squeeze(raw_slice);

            if ~isnumeric(raw_slice)
                error('GriddedData:SliceNotNumeric', ...
                    'Environmental slice must be numeric, got %s', class(raw_slice));
            end

            raw_slice = double(raw_slice);
            raw_slice(~isfinite(raw_slice)) = NaN;

            lat = double(lat(:));
            lon = double(lon(:));

            nlat = numel(lat);
            nlon = numel(lon);

            % Make slice match [nlat x nlon]
            if isequal(size(raw_slice), [nlat, nlon])
                slice2d = raw_slice;
            elseif isequal(size(raw_slice), [nlon, nlat])
                slice2d = raw_slice.';
            else
                error('GriddedData:SliceSizeMismatch', ...
                    'Dynamic slice size [%d %d] does not match lat/lon lengths [%d %d].', ...
                    size(raw_slice,1), size(raw_slice,2), nlat, nlon);
            end

            % Ensure latitude ascending
            if nlat > 1 && lat(1) > lat(end)
                lat = flipud(lat);
                slice2d = flipud(slice2d);
            end

            % Ensure longitude ascending if needed
            if nlon > 1 && lon(1) > lon(end)
                lon = flipud(lon);
                slice2d = fliplr(slice2d);
            end

            [LonGrid, LatGrid] = meshgrid(lon, lat);

            % Robust plotting for dynamic NC:
            % use m_pcolor instead of geoshow(texturemap)
            h_env = m_pcolor(LonGrid, LatGrid, slice2d);
            set(h_env, 'EdgeColor', 'none');
            shading flat

            % Colormap
            cmap_here = s_resolve_cmap(gd.cmap, 256);
            if gd.invert_cmap
                cmap_here = flipud(cmap_here);
            end
            colormap(cmap_here);
            last_env_cmap = cmap_here;

            % Robust CLim handling
            finite_vals = slice2d(isfinite(slice2d));
            if isempty(finite_vals)
                warning('GriddedData:AllNaN', ...
                    'Environmental slice for %s at frame %s contains no finite values.', ...
                    gd.var_of_interest, string(frame_time));
            else
                if ~isempty(gd.cbar_limits) && numel(gd.cbar_limits) == 2 && ...
                        all(isfinite(gd.cbar_limits)) && gd.cbar_limits(2) > gd.cbar_limits(1)
                    caxis(gd.cbar_limits);
                else
                    auto_clim = [min(finite_vals) max(finite_vals)];
                    if auto_clim(1) == auto_clim(2)
                        auto_clim = auto_clim + [-0.5 0.5];
                    end
                    caxis(auto_clim);
                end
            end

            if gd.show_colorbar
                env_cb = colorbar;
                env_cb.Units = 'normalized';
                env_cb.Position = [0.81 0.12 0.02 0.78];
            end

            freezeColors(map_ax);
            hold on;
        end
    end
    %% raster image
     %% Raster image (static GeoTIFF)
    if ~isempty(kwargs.raster_image) && isa(kwargs.raster_image, 'containers.Map') ...
            && isKey(kwargs.raster_image, 'raster_array_f') ...
            && isKey(kwargs.raster_image, 'raster_ref')

        raster_array_f = kwargs.raster_image('raster_array_f');
        raster_ref     = kwargs.raster_image('raster_ref');
        
        % m_image supports:
        %  - uint8 NxMx3 (truecolor),
        %  - double NxM (scalar field).
        %
        % If the raster is single-channel (2D), reduce it to double.
        if ndims(raster_array_f) == 2
            if ~isa(raster_array_f, 'double')
                raster_array_f = double(raster_array_f);
            end
        % If it is not 2D and not uint8 RGB - restrict:
        elseif ndims(raster_array_f) == 3 && ~isa(raster_array_f, 'uint8')
            % take the first channel and make it a scalar double:
            raster_array_f = double(raster_array_f(:,:,1));
        end

        % Colormap for raster (configurable in UI)
        if ~isempty(kwargs.raster_cmap)
            cmap_here = resolve_cmap(kwargs.raster_cmap, 256);

            % Inversion if specified in Map
            if isKey(kwargs.raster_image, 'invert_cmap') && kwargs.raster_image('invert_cmap')
                cmap_here = flipud(cmap_here);
            end

            colormap(cmap_here);
            last_env_cmap = cmap_here; %#ok<NASGU>
        end

        % Colorbar limits, if set
        if isKey(kwargs.raster_image, 'cbar_limits') && ~isempty(kwargs.raster_image('cbar_limits'))
            caxis(kwargs.raster_image('cbar_limits'));
        end

        % Show colorbar or not
        if isKey(kwargs.raster_image, 'show_colorbar') && kwargs.raster_image('show_colorbar')
            env_cb = colorbar;
            env_cb.Units = 'normalized';
            env_cb.Position = [0.81 0.12 0.02 0.78];
        end

        % Drawing GeoTIFF as a background
        r_img = m_image(raster_ref.LongitudeLimits, ...
                        raster_ref.LatitudeLimits, ...
                        raster_array_f);
        uistack(r_img, 'bottom');  %  under tracks and other layers
    end

    freezeColors(map_ax);
    hold on;

    %% Shapefiles
    if ~isempty(kwargs.shapefile_stack)
        for n_shp=1:length(kwargs.shapefile_stack)
            shp = kwargs.shapefile_stack{n_shp};
            shp.load_data();

            % Convert to m_map coordinates
            for i=1:length(shp.data)
                [shp.data(i).X, shp.data(i).Y] = m_ll2xy(shp.data(i).X, shp.data(i).Y, 'clip', 'off');
            end

            % Check geometry type and plot
            if shp.is_point()
                mapshow(shp.data, 'MarkerEdgeColor', shp.point_color, 'MarkerFaceColor', shp.point_color, ...
                    'Marker', shp.marker_style, 'MarkerSize', shp.marker_size);
            elseif shp.is_line()
                mapshow(shp.data, 'color', shp.line_color, 'LineWidth', shp.line_width);
            elseif shp.is_poly()
                mapshow(shp.data,'FaceColor', shp.face_color, ...
                    'EdgeColor', shp.edge_color, 'FaceAlpha', shp.face_alpha);
            end
        end
    end

    %% Contour data
    if ~isempty(kwargs.contour_data)
        % Load time slice of contour data
        contour_time_index=read_nc_timestamps(kwargs.contour_data('filename'), kwargs.contour_data('timevar'));
        times_before_frame = contour_time_index(contour_time_index <= frame_time);

        current_contour_time = find(min(abs(times_before_frame-frame_time))==abs(times_before_frame-frame_time));

        if ~isempty(current_contour_time)
            [contour_lat, contour_lon, contour_time, contour_var] = unpack_netcdf( ...
                kwargs.contour_data('filename'), kwargs.contour_data('latvar'), ...
                kwargs.contour_data('lonvar'), kwargs.contour_data('timevar'), ...
                kwargs.contour_data('var_of_interest'), start=current_contour_time, ...
                count=1);

            A = contour_var(:, :, contour_time == contour_time_index(current_contour_time));

            % make grid for lat/lon
            [LAT,LON] = meshgrid(contour_lat, contour_lon);

            % plot contours
            m_contour(LON, LAT, A, ...
                'ShowText',kwargs.contour_data('ShowText'), ...
                'LineWidth', kwargs.contour_data('LineWidth'), ...
                'LineColor', kwargs.contour_data('LineColor'))
        end
    end

    %% Quivers
    if ~isempty(kwargs.quiver_data)

        if isempty(kwargs.quiver_data.time_index)
            kwargs.quiver_data.load_time_index;
        end

        % Load new slice of data
        times_before_frame = kwargs.quiver_data.time_index(kwargs.quiver_data.time_index <= frame_time);

        current_quiver_time = find(min(abs(times_before_frame-frame_time))==abs(times_before_frame-frame_time));
    
        if ~isempty(current_quiver_time)
            % unpack u data
            [quiver_lat, quiver_long, quiver_time, quiver_u] = unpack_netcdf( ...
                    kwargs.quiver_data.filename, ...
                    kwargs.quiver_data.latvar, ...
                    kwargs.quiver_data.lonvar, ...
                    kwargs.quiver_data.timevar, ...
                    kwargs.quiver_data.u_var, ...
                    start=current_quiver_time, count=1);
            % unpack v data
            [quiver_lat, quiver_long, quiver_time, quiver_v] = unpack_netcdf( ...
                    kwargs.quiver_data.filename, ...
                    kwargs.quiver_data.latvar, ...
                    kwargs.quiver_data.lonvar, ...
                    kwargs.quiver_data.timevar, ...
                    kwargs.quiver_data.v_var, ...
                    start=current_quiver_time, count=1);

            U = quiver_u(:, :, quiver_time == kwargs.quiver_data.time_index(current_quiver_time));
            V = quiver_v(:, :, quiver_time == kwargs.quiver_data.time_index(current_quiver_time));

            if ~kwargs.quiver_data.use_simple_plot
                kwargs.quiver_data.move_particles(U, V);
                kwargs.quiver_data.plot();
            elseif kwargs.quiver_data.use_simple_plot
                % make grid for lat/lon
                [LAT,LON] = meshgrid(quiver_lat, quiver_long);
    
                % plot quivers
                [plot_lon, plot_lat] = m_ll2xy(LON, LAT);
                
                quiverh = quiver(plot_lon, plot_lat, U, V, 'color', kwargs.quiver_data.quiver_color);
            end
            
        end
    end
    %% Elevation
    if ~isempty(kwargs.elevation)
        m_etopo2('contour', floor(linspace(min(kwargs.elevation("elev"), [], 'all'), ...
            max(kwargs.elevation("elev"), [], 'all'), kwargs.elevation('nlevels'))), ...
            'LineColor', kwargs.elevation('LineColor'), ...
            'LineWidth', kwargs.elevation('LineWidth'), ...
            'ShowText', kwargs.elevation('ShowText'))
    end

    %% Labeled points
    if ~isempty(kwargs.labeled_points)
        kwargs.labeled_points.plot(frame_time);
    end


    % So the color bar will use the cmap for the env data
    if ~isempty(kwargs.gridded_data) && ~isempty(last_env_cmap)
        colormap(last_env_cmap);
    end


    %% Track / Presence data

    if strcmpi(tracks.visualization_mode, 'presence')
    
        
        % Presence mode
        
        data_now = tracks.data;
    
        % Location memory is interpreted in hours
        memory_duration = hours(tracks.track_memory);
    
        % Keep points that are still visible at current frame
        visible_mask = (data_now.timestamp <= frame_time) & ...
                       (data_now.timestamp > (frame_time - memory_duration));
    
        data_vis = data_now(visible_mask, :);
    
        legend_items = gobjects(0);
        legend_labels = {};
    
        if ~isempty(data_vis)
    
            
            % Mode 1: Use black markers only
            
            if tracks.use_black_markers_only
    
                if ismember(tracks.size_parameter, data_vis.Properties.VariableNames)
                    size_vals = data_vis.(tracks.size_parameter);
    
                    if isnumeric(size_vals) || islogical(size_vals)
                        data_vis = data_vis(size_vals ~= 0 & ~isnan(size_vals), :);
                    end
                end
    
                if ~isempty(data_vis)
                    s = m_scatter(data_vis.location_long, data_vis.location_lat, ...
                        100, 'k', tracks.marker_style, 'filled');
    
                    try
                        s.MarkerFaceAlpha = tracks.track_alpha;
                        s.MarkerEdgeAlpha = tracks.track_alpha;
                    catch
                    end
    
                    if kwargs.show_legend
                        presence_size_title = char(tracks.size_parameter);
                        presence_size_sizes = 100;
                        presence_size_labels = {'Visible presence'};
                    
                        presence_color_title = char(tracks.color_parameter);
                        presence_color_colors = [0 0 0];
                        presence_color_labels = {'Black markers only'};
                    end
                end
    
            else
    
                
                % Marker size from numeric variable
                
                if ismember(tracks.size_parameter, data_vis.Properties.VariableNames)
                    size_vals = data_vis.(tracks.size_parameter);
                else
                    size_vals = ones(height(data_vis), 1);
                end
    
                if ~(isnumeric(size_vals) || islogical(size_vals))
                    size_vals = ones(height(data_vis), 1);
                end
    
                size_vals = double(size_vals);
                valid_size = ~isnan(size_vals);
    
                % Default marker sizes
                marker_sizes = repmat(60, height(data_vis), 1);
    
                % Five quantile-based classes
                size_levels = [40 70 100 130 160];
    
                if any(valid_size)
                    if ~isempty(kwargs.global_size_q)
                        q = kwargs.global_size_q;
                    else
                        q = quantile(size_vals(valid_size), [0.2 0.4 0.6 0.8]);
                    end

                    marker_sizes(valid_size & size_vals <= q(1)) = size_levels(1);
                    marker_sizes(valid_size & size_vals >  q(1) & size_vals <= q(2)) = size_levels(2);
                    marker_sizes(valid_size & size_vals >  q(2) & size_vals <= q(3)) = size_levels(3);
                    marker_sizes(valid_size & size_vals >  q(3) & size_vals <= q(4)) = size_levels(4);
                    marker_sizes(valid_size & size_vals >  q(4)) = size_levels(5);
                end

                % custom legend logic
                if kwargs.show_legend
                    presence_size_title = char(tracks.size_parameter);
                
                    if any(valid_size)
                        presence_size_sizes = size_levels(:);
                
                        presence_size_labels = { ...
                            sprintf('<= %.3g', q(1)), ...
                            sprintf('%.3g - %.3g', q(1), q(2)), ...
                            sprintf('%.3g - %.3g', q(2), q(3)), ...
                            sprintf('%.3g - %.3g', q(3), q(4)), ...
                            sprintf('> %.3g', q(4)) ...
                        };
                    else
                        presence_size_sizes = 60;
                        presence_size_labels = {'No valid size values'};
                    end
                end
                
                % Color parameter
                
                if ismember(tracks.color_parameter, data_vis.Properties.VariableNames)
                    color_vals = data_vis.(tracks.color_parameter);
                else
                    color_vals = repmat("Presence", height(data_vis), 1);
                end
    
                
                % Numeric color parameter
                
                if isnumeric(color_vals) || islogical(color_vals)
                    color_vals = double(color_vals);
                    valid_color = ~isnan(color_vals);
    
                    % Use user-defined colors as a scale if available
                    if ~isempty(tracks.presence_colors)
                        base_colors = tracks.presence_colors;
                    else
                        base_colors = lines(5);
                    end
    
                    % Interpolate to smooth scale
                    if size(base_colors, 1) == 1
                        base_colors = [base_colors; base_colors];
                    end
                    n_base = size(base_colors, 1);
                    xi = linspace(0, 1, n_base);
                    xq = linspace(0, 1, 256);
    
                    cmap256 = [ ...
                        interp1(xi, base_colors(:,1), xq)', ...
                        interp1(xi, base_colors(:,2), xq)', ...
                        interp1(xi, base_colors(:,3), xq)' ];
    
                    point_colors = repmat([0 0 0], height(data_vis), 1);
    
                    if any(valid_color)
                        if ~isempty(kwargs.global_color_cmin) && ~isempty(kwargs.global_color_cmax)
                            cmin = kwargs.global_color_cmin;
                            cmax = kwargs.global_color_cmax;
                        else
                            cmin = min(color_vals(valid_color));
                            cmax = max(color_vals(valid_color));
                        end

                        if cmax > cmin
                            cidx = round(1 + (color_vals - cmin) .* 255 ./ (cmax - cmin));
                        else
                            cidx = repmat(256, size(color_vals));
                        end

                        cidx(~valid_color) = 1;
                        cidx = max(1, min(256, cidx));
                        point_colors = cmap256(cidx, :);
                    end

                    %Custom legend logic
                    if kwargs.show_legend
                        presence_color_title = char(tracks.color_parameter);
                    
                        if any(valid_color)
                            if ~isempty(kwargs.global_color_cmin) && ~isempty(kwargs.global_color_cmax)
                                cmin_leg = kwargs.global_color_cmin;
                                cmax_leg = kwargs.global_color_cmax;
                            else
                                cmin_leg = min(color_vals(valid_color));
                                cmax_leg = max(color_vals(valid_color));
                            end
                    
                            if cmax_leg > cmin_leg
                                if ~isempty(kwargs.global_color_breaks)
                                    color_breaks = kwargs.global_color_breaks;
                                else
                                    color_breaks = linspace(cmin_leg, cmax_leg, 6);
                                end
                                color_mids = (color_breaks(1:end-1) + color_breaks(2:end)) / 2;
                    
                                cidx_leg = round(1 + (color_mids - cmin) .* 255 ./ (cmax - cmin));
                                cidx_leg = max(1, min(256, cidx_leg));
                    
                                presence_color_colors = cmap256(cidx_leg, :);
                                presence_color_labels = { ...
                                    sprintf('%.3g - %.3g', color_breaks(1), color_breaks(2)), ...
                                    sprintf('%.3g - %.3g', color_breaks(2), color_breaks(3)), ...
                                    sprintf('%.3g - %.3g', color_breaks(3), color_breaks(4)), ...
                                    sprintf('%.3g - %.3g', color_breaks(4), color_breaks(5)), ...
                                    sprintf('%.3g - %.3g', color_breaks(5), color_breaks(6)) ...
                                };
                            else
                                presence_color_colors = cmap256(256, :);
                                presence_color_labels = {sprintf('%.3g', cmin_leg)};
                            end
                        else
                            presence_color_colors = [0 0 0];
                            presence_color_labels = {'No valid color values'};
                        end
                    end
    
                    for ii = 1:height(data_vis)
                        s = m_scatter(data_vis.location_long(ii), data_vis.location_lat(ii), ...
                            marker_sizes(ii), point_colors(ii,:), tracks.marker_style, 'filled');
    
                        try
                            s.MarkerFaceAlpha = tracks.track_alpha;
                            s.MarkerEdgeAlpha = tracks.track_alpha;
                        catch
                        end
                    end
    
                else
    
                    
                    % Categorical color parameter
                    
                    cats = string(color_vals);
                    [ucat, ~, ic] = unique(cats, 'stable');
    
                    if ~isempty(tracks.presence_colors)
                        cat_colors = repmat(tracks.presence_colors, ...
                            ceil(numel(ucat) / size(tracks.presence_colors, 1)), 1);
                    else
                        cat_colors = repmat(lines(max(numel(ucat), 1)), ...
                            ceil(numel(ucat) / max(numel(ucat), 1)), 1);
                    end
    
                    cat_colors = cat_colors(1:numel(ucat), :);
    
                    for kk = 1:numel(ucat)
                        idx = (ic == kk);
    
                        s = m_scatter(data_vis.location_long(idx), data_vis.location_lat(idx), ...
                            marker_sizes(idx), cat_colors(kk,:), tracks.marker_style, 'filled');
    
                        try
                            s.MarkerFaceAlpha = tracks.track_alpha;
                            s.MarkerEdgeAlpha = tracks.track_alpha;
                        catch
                        end
                    end
    
                    if kwargs.show_legend
                        presence_color_title = char(tracks.color_parameter);
                    
                        n_show = min(numel(ucat), 10);
                        presence_color_colors = cat_colors(1:n_show, :);
                        presence_color_labels = cellstr(ucat(1:n_show));
                    
                        if numel(ucat) > n_show
                            presence_color_colors(end+1, :) = [0.5 0.5 0.5];
                            presence_color_labels{end+1} = sprintf('... +%d more', numel(ucat) - n_show);
                        end
                    end
                end
            end
        end
    
    else
    
       
        % Original track logic
        
        group_labels = tracks.track_groups.keys;
    
        track_colors = repmat(tracks.track_cmap, ...
            ceil(length(group_labels) / length(tracks.track_cmap)), 1);
    
        % Create legend items for each group
        if kwargs.show_legend
            legend_items = gobjects(length(group_labels),1);
            for l = 1:length(legend_items)
                legend_items(l) = scatter(map_ax, nan, nan, 150, ...
                    track_colors(l, :), tracks.marker_style, 'filled');
            end
        end
    
        % Loop for attribute groups
        for j = 1:length(tracks.track_groups)
    
            track_color = track_colors(j, :);
            group = tracks.track_groups(group_labels{j});
            inds = group.keys;
    
            % Plot each individual in the group
            for i = 1:length(inds)
                data_ind = group(inds{i});
    
                if height(data_ind(timerange(kwargs.start_time, frame_time, 'closed'), :)) < tracks.track_memory
                    oldest_point = kwargs.start_time;
                else
                    oldest_point = data_ind.timestamp(find(data_ind.timestamp == frame_time) - tracks.track_memory + 1);
                end
    
                x = data_ind.location_long(oldest_point:tracks.frequency:frame_time);
                y = data_ind.location_lat(oldest_point:tracks.frequency:frame_time);
    
                if ~isempty(x)
                    xseg = [x(1:end-1), x(2:end)];
                    yseg = [y(1:end-1), y(2:end)];
    
                    trace_colors = repmat(track_color, size(xseg,1), 1);
                    segColors = trace_colors;
    
                    if isnan(tracks.marker_color)
                        scatterColor = track_color;
                    else
                        scatterColor = tracks.marker_color;
                    end
    
                    if tracks.fade_tracks
                        seg_amap = logspace(0,1,size(xseg,1));
                        seg_amap = seg_amap / max(seg_amap);
                    else
                        seg_amap = repmat(tracks.track_alpha, size(xseg,1), 1);
                    end
    
                    segColors(:,4) = seg_amap;
    
                    h = m_plot(xseg', yseg', 'LineWidth', tracks.track_width);
    
                    x_point = data_ind.location_long(frame_time);
                    y_point = data_ind.location_lat(frame_time);
    
                    if ~isempty(data_ind(frame_time,:))
                        s = m_scatter(x_point, y_point, tracks.marker_size, ...
                            scatterColor, tracks.marker_style, 'filled');
                    end
    
                    set(h, {'Color'}, mat2cell(segColors, ones(size(xseg,1),1), 4))
                end
            end
        end
    end

    % Draw axis grid at the end to make sure it isn't covered by
    % anything
    m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 3);

    % Add timestamp label
    if mod(tracks.frequency, hours(24)) == 0
        time_label = string(frame_time, 'dd-MMM-yyy');
    else
        time_label = string(frame_time, "dd-MMM-uuuu HH:mm");
    end
    title(time_label)

    % Add custom legend
    if kwargs.show_legend
        if strcmpi(tracks.visualization_mode, 'presence')
            add_presence_dual_legend( ...
                fig, ...
                tracks, ...
                presence_size_title, presence_size_sizes, presence_size_labels, ...
                presence_color_title, presence_color_colors, presence_color_labels);
        else
            if exist('legend_items', 'var') && ~isempty(legend_items)
                lgd = legend(map_ax, legend_items, group_labels);
                lgd.Units = 'normalized';
                lgd.Position = [0.78 0.88 0.20 0.06];
                lgd.AutoUpdate = 'off';
            end
        end
    end
    
    drawnow limitrate nocallbacks

    % Save image of each frame
    outputBaseFileName = sprintf('Frame%s.png', num2str(kwargs.frame_number));
    outputFullFileName = fullfile(kwargs.output_directory, outputBaseFileName);
    exportgraphics(fig, outputFullFileName, 'Resolution', kwargs.frame_resolution);
    
    % Delete variables
    if exist('grd', 'var'); clear grd; end
    if exist('h', 'var'); clear h; end
    if exist('s', 'var'); clear s; end
    if exist('r_img', 'var'); clear r_img; end
    if exist('quiverh', 'var'); clear quiverh; end
    if ~isempty(kwargs.quiver_data)
        if ~isempty(kwargs.quiver_data.quiverh)
            clear kwargs.quiver_data.quiverh;
        end
    end
    
    % Close only this off-screen figure
    if isgraphics(fig)
        close(fig);
    end
    
    % Restore MATLAB default figure visibility
    set(groot, 'DefaultFigureVisible', oldDefaultFigureVisible);
end

function add_presence_dual_legend( ...
    fig, ...
    tracks, ...
    size_title, size_sizes, size_labels, ...
    color_title, color_colors, color_labels)

   % 2026a fig = gcf;

    legend_ax = axes( ...
        'Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [0.85 0.14 0.13 0.72], ...
        'Color', 'none', ...
        'XColor', 'none', ...
        'YColor', 'none', ...
        'XTick', [], ...
        'YTick', [], ...
        'Box', 'off');

    hold(legend_ax, 'on');
    xlim(legend_ax, [0 1]);
    ylim(legend_ax, [0 1]);

    y = 0.96;

    % ----------------------------
    % Size legend
    % ----------------------------
    if ~isempty(size_sizes) && ~isempty(size_labels)
        text(legend_ax, 0.02, y, sprintf('%s', size_title), ...
            'FontWeight', 'bold', ...
            'FontSize', 10, ...
            'Interpreter', 'none', ...
            'VerticalAlignment', 'top');

        y = y - 0.08;

        for k = 1:numel(size_sizes)
            scatter(legend_ax, 0.16, y, size_sizes(k), ...
                [0.25 0.25 0.25], tracks.marker_style, 'filled', ...
                'MarkerEdgeColor', [0 0 0], ...
                'LineWidth', 0.5);

            text(legend_ax, 0.32, y, size_labels{k}, ...
                'FontSize', 9, ...
                'Interpreter', 'none', ...
                'VerticalAlignment', 'middle');

            y = y - 0.08;
        end

        y = y - 0.05;
    end

    % ----------------------------
    % Color legend
    % ----------------------------
    if ~isempty(color_colors) && ~isempty(color_labels)
        text(legend_ax, 0.02, y, sprintf('%s', color_title), ...
            'FontWeight', 'bold', ...
            'FontSize', 10, ...
            'Interpreter', 'none', ...
            'VerticalAlignment', 'top');

        y = y - 0.08;

        legend_marker_size = 90;

        n_items = min(numel(color_labels), size(color_colors, 1));

        for k = 1:n_items
            scatter(legend_ax, 0.16, y, legend_marker_size, ...
                color_colors(k,:), tracks.marker_style, 'filled', ...
                'MarkerEdgeColor', [0 0 0], ...
                'LineWidth', 0.5);

            text(legend_ax, 0.32, y, color_labels{k}, ...
                'FontSize', 9, ...
                'Interpreter', 'none', ...
                'VerticalAlignment', 'middle');

            y = y - 0.08;
        end
    end

    hold(legend_ax, 'off');
end
