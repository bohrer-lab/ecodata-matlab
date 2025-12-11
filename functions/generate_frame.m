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
    end



    %% Set up for map

    figure(Visible='off');
    
    % Map projection
    m_proj('Cylindrical Equal-Area','lat', kwargs.latlim,'long', kwargs.lonlim)

    hold on
    last_env_cmap = [];
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
                colorbar;
            end
    
            freezeColors;
            hold on;

    
        % Case B: time-varying field (legacy GriddedData)
        else
            % The original logic (nearest timestamp to frame_time)
            if isempty(kwargs.gridded_data.time_index)
                kwargs.gridded_data.load_time_index;
            end
    
            times_before_frame = kwargs.gridded_data.time_index( ...
                kwargs.gridded_data.time_index <= frame_time);
    
            % If there is no time <= frame_time, fall back to the earliest
            if isempty(times_before_frame)
                current_idx = 1;
            else
                [~, current_idx] = min(abs(times_before_frame - frame_time));
            end
    
            % Read one slice
            [lat, lon, ~, slice] = unpack_netcdf( ...
                kwargs.gridded_data.filename, ...
                kwargs.gridded_data.latvar, ...
                kwargs.gridded_data.lonvar, ...
                kwargs.gridded_data.timevar, ...
                kwargs.gridded_data.var_of_interest, ...
                start = current_idx, count = 1);
    
            % Ensure ascending latitude for consistent plotting
            if numel(lat) > 1 && lat(1) > lat(end)
                lat   = flipud(lat);
                slice = flipud(slice(:,:,1));
            else
                slice = slice(:,:,1);
            end
    
            [LonGrid,LatGrid] = meshgrid(lon, lat);
            geoshow(LatGrid, LonGrid, slice, 'DisplayType','texturemap');
    
            % Colormap / colorbar
            % gd.cmap is already Nx3, or a row with a name – s_resolve_cmap
            cmap_here = s_resolve_cmap(gd.cmap, 256);
            if gd.invert_cmap
                cmap_here = flipud(cmap_here);
            end
        
            colormap(cmap_here);
            last_env_cmap = cmap_here;
        
            if ~isempty(gd.cbar_limits)
                caxis(gd.cbar_limits);
            end
        
            if gd.show_colorbar
                colorbar;
            end
        
            freezeColors;
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
            colorbar;
        end

        % Drawing GeoTIFF as a background
        r_img = m_image(raster_ref.LongitudeLimits, ...
                        raster_ref.LatitudeLimits, ...
                        raster_array_f);
        uistack(r_img, 'bottom');  %  under tracks and other layers
    end

    freezeColors;
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
        labeled_pts = kwargs.labeled_points("data");
        labels_filtered = labeled_pts(frame_time>=labeled_pts.start_time & frame_time<=labeled_pts.end_time,:);

        m_scatter(labels_filtered.longitude, labels_filtered.latitude, ...
            kwargs.labeled_points("marker_size"), kwargs.labeled_points("marker_color"), 'filled')

        for i=1:height(labels_filtered)
            m_text(labels_filtered.label_longitude(i),labels_filtered.label_latitude(i), ...
                labels_filtered.label{i}, 'horizontal', labels_filtered.horizontal_alignment{i}, ...
                'FontSize', 8)
        end
    end


    % So the color bar will use the cmap for the env data
    if ~isempty(kwargs.gridded_data) && ~isempty(last_env_cmap)
        colormap(last_env_cmap);
    end


    %% Track data

    % Attribute grouping
    group_labels = tracks.track_groups.keys;

    track_colors = repmat(tracks.track_cmap, ceil(length(group_labels)/length(tracks.track_cmap)),1);


    % Create legend items for each group
    if kwargs.show_legend
        legend_items = gobjects(length(group_labels),1);
        for l=1:length(legend_items)
            legend_items(l) = scatter(nan, nan, 150, track_colors(l, :), tracks.marker_style,'filled');
        end
    end

    % Loop for attribute groups
    for j=1:length(tracks.track_groups)

        track_color = track_colors(j, :);
        group = tracks.track_groups(group_labels{j});
        inds = group.keys;

        % Plot each individual in the group
        for i=1:length(inds)
            data_ind = group(inds{i});

            if height(data_ind(timerange(kwargs.start_time, frame_time, 'closed'), :)) < tracks.track_memory
                oldest_point = kwargs.start_time;
            else
                oldest_point = data_ind.timestamp(find(data_ind.timestamp == frame_time) - tracks.track_memory + 1);
            end

            x = data_ind.location_long(oldest_point:tracks.frequency:frame_time);
            y = data_ind.location_lat(oldest_point:tracks.frequency:frame_time);

            if ~isempty(x)
                xseg = [x(1:end-1),x(2:end)];
                yseg = [y(1:end-1),y(2:end)];

                trace_colors = repmat(track_color, size(xseg,1), 1);
                segColors = trace_colors;

                if isnan(tracks.marker_color)
                    scatterColor = track_color;
                else
                    scatterColor = tracks.marker_color;
                end

                if tracks.fade_tracks
                    seg_amap = logspace(0,1,size(xseg,1));
                    seg_amap = seg_amap/max(seg_amap);
                else
                    seg_amap = repmat(tracks.track_alpha, size(xseg,1), 1);
                end

                segColors(:,4) = seg_amap;

                h = m_plot(xseg',yseg','LineWidth',tracks.track_width);

                x_point = data_ind.location_long(frame_time);
                y_point = data_ind.location_lat(frame_time);

                if ~isempty(data_ind(frame_time,:))
                    s = m_scatter(x_point,y_point,tracks.marker_size, ...
                        scatterColor,tracks.marker_style,'filled');
                end

                set(h, {'Color'}, mat2cell(segColors,ones(size(xseg,1),1),4))
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

    % Add legend
    if kwargs.show_legend
        legend(legend_items, group_labels, 'Location', 'northeastoutside')
    end

    drawnow

    %save image of each frame
    % Construct an output image file name.
    outputBaseFileName = sprintf('Frame%s.png', num2str(kwargs.frame_number));
    outputFullFileName = fullfile(kwargs.output_directory, outputBaseFileName);
    exportgraphics(gcf,outputFullFileName,'Resolution', kwargs.frame_resolution)

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


    % Make sure no figure objects stay in memory
    clf
    close all
end