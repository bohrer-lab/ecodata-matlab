function animate_tracks(tracks, kwargs)
    arguments
        tracks
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
        kwargs.latmin = NaN
        kwargs.latmax = NaN
        kwargs.lonmin = NaN
        kwargs.lonmax = NaN
        kwargs.last_frame_only = false
        kwargs.global_size_q = []
        kwargs.global_color_breaks = []
        kwargs.show_legend = true;
    end

    close all
    
    
    % Read and prepare input datasets

    % Get geolimits for map and datasets 
    if any(isnan([kwargs.latmin kwargs.latmax kwargs.lonmin kwargs.lonmax]))
        [latlim, lonlim] = get_geolimits(tracks.data, .10);
    else 
        latlim = [kwargs.latmin kwargs.latmax];
        lonlim = [kwargs.lonmin kwargs.lonmax];
    end


    %% Prepare track data

    % Select bbox
    tracks.select_bbox(latlim(1), latlim(2), lonlim(1), lonlim(2));

    % Filter time range 
    tracks.select_timerange(kwargs.start_time, kwargs.end_time);
    
    % Attribute groupings for track data
    if strcmpi(tracks.visualization_mode, 'track')
        tracks.group_and_resample();
    else
        tracks.track_groups = containers.Map();
    end


    % Elevation data 
    if ~isempty(kwargs.elevation)
        [elev,elev_long,elev_lat]=m_etopo2([lonlim(1) lonlim(2) latlim(1) latlim(2)]);
        kwargs.elevation("elev") = elev;
        kwargs.elevation("elev_long") = elev_long;
        kwargs.elevation("elev_lat") = elev_lat;
    end

    % Raster image 
     if ~isempty(kwargs.raster_image) && isa(kwargs.raster_image, 'containers.Map')

        % Expected: map to have a key 'filename'
        if isKey(kwargs.raster_image, 'filename')
            geoTiffFile = kwargs.raster_image('filename');

            % read GeoTIFF 
            [raster_array, raster_ref] = readgeoraster(geoTiffFile);

            % Flip vertically
            raster_array_f = flipud(raster_array);

            % Save inside Map (so that generate_frame doesn't read the file again)
            kwargs.raster_image('raster_array_f') = raster_array_f;
            kwargs.raster_image('raster_ref')     = raster_ref;
        end
    end

    % Labeled points
    if ~isempty(kwargs.labeled_points)
        labeled_pts = prepare_labels(kwargs.labeled_points('filename'), ...
            kwargs.start_time, kwargs.end_time); 
        labeled_pts = select_bbox(labeled_pts, 'latitude', 'longitude', ...
            latlim(1), latlim(2), lonlim(1), lonlim(2));
        kwargs.labeled_points('data') = labeled_pts;
    end
    
    % quivers
    if ~isempty(kwargs.quiver_data)
        kwargs.quiver_data.update_bbox(latlim, lonlim);
        kwargs.quiver_data.load_time_index();
        kwargs.quiver_data.calc_quiver_grid();
    end
    
    %% Pre-compute global quantiles for presence mode
    global_size_q = [];
    global_color_breaks = [];
    global_color_cmin = [];
    global_color_cmax = [];

    if strcmpi(tracks.visualization_mode, 'presence')
        all_data = tracks.data;

        if ismember(tracks.size_parameter, all_data.Properties.VariableNames)
            size_vals_all = double(all_data.(tracks.size_parameter));
            valid_all = isfinite(size_vals_all) & size_vals_all ~= 0;
            if any(valid_all)
                global_size_q = quantile(size_vals_all(valid_all), [0.2 0.4 0.6 0.8]);
            end
        end

        if ismember(tracks.color_parameter, all_data.Properties.VariableNames)
            color_vals_all = all_data.(tracks.color_parameter);
            if isnumeric(color_vals_all) || islogical(color_vals_all)
                color_vals_all = double(color_vals_all);
                valid_c = isfinite(color_vals_all);
                if any(valid_c)
                    cmin_all = min(color_vals_all(valid_c));
                    cmax_all = max(color_vals_all(valid_c));
                    if cmax_all > cmin_all
                        global_color_breaks = linspace(cmin_all, cmax_all, 6);
                        global_color_cmin = cmin_all;
                        global_color_cmax = cmax_all;
                    end
                end
            end
        end
    end

    %% plotting

    if kwargs.last_frame_only
        generate_frame(tracks, kwargs.end_time, latlim=latlim, lonlim=lonlim, ...
            start_time=kwargs.start_time, end_time=kwargs.end_time, ...
            output_directory=kwargs.output_directory, frame_resolution=kwargs.frame_resolution, ...
            labeled_points=kwargs.labeled_points, raster_image=kwargs.raster_image, ...
            raster_cmap=kwargs.raster_cmap, shapefile_stack = kwargs.shapefile_stack, ...
            elevation=kwargs.elevation, gridded_data=kwargs.gridded_data, ...
            contour_data=kwargs.contour_data, quiver_data=kwargs.quiver_data, ...
            global_size_q=global_size_q, global_color_breaks=global_color_breaks, ...
            global_color_cmin=global_color_cmin, global_color_cmax=global_color_cmax, ...
            show_legend=kwargs.show_legend)
    else
        frame_number = 0;
        for k=kwargs.start_time:tracks.frequency:kwargs.end_time
            generate_frame(tracks, k, latlim=latlim, lonlim=lonlim, ...
                start_time=kwargs.start_time, end_time=kwargs.end_time, frame_number=frame_number, ...
                output_directory=kwargs.output_directory, frame_resolution=kwargs.frame_resolution, ...
                labeled_points=kwargs.labeled_points, raster_image=kwargs.raster_image, ...
                raster_cmap=kwargs.raster_cmap, shapefile_stack = kwargs.shapefile_stack, ...
                elevation=kwargs.elevation, gridded_data=kwargs.gridded_data, ...
                contour_data=kwargs.contour_data, quiver_data=kwargs.quiver_data, ...
                global_size_q=global_size_q, global_color_breaks=global_color_breaks, ...
                global_color_cmin=global_color_cmin, global_color_cmax=global_color_cmax, ...
                show_legend=kwargs.show_legend)
            frame_number = frame_number + 1;
        end
    end
end
