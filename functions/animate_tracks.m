function animate_tracks(tracks, kwargs)
    arguments
        tracks
        kwargs.gridded_data = containers.Map() % Map of filename, and variable labels 
        kwargs.contour_data = containers.Map()
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
        kwargs.chunk_size = 10
        kwargs.last_frame_only = false
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
    tracks.group_and_resample();
    
    % Gridded timeseries data
    if ~isempty(kwargs.gridded_data)
        nc_time_index = read_nc_timestamps(kwargs.gridded_data('filename'), 'time');
%         kwargs.gridded_data("nc_time_index") = nc_time_index;
%         nc_start = 1;
%         [nc_lat, nc_long, nc_time, nc_var] = unpack_netcdf(kwargs.gridded_data('filename'), ...
%             kwargs.gridded_data('latvar'), kwargs.gridded_data('lonvar'), ...
%             kwargs.gridded_data('timevar'), ...
%             kwargs.gridded_data('var_of_interest'), ...
%             start=nc_start, count=kwargs.chunk_size);
%         chunk_tmax = max(nc_time);
        % Initialize current nc data to the earliest array in the timeseries
%         current_nc_time=min(nc_time);
%         current_nc_frame= nc_var(:, :, 1)';

    end

    % Contour data 
    if ~isempty(kwargs.contour_data)
        [contour_lat, contour_lon, contour_time, contour_var] = unpack_netcdf( ...
            kwargs.contour_data('filename'), kwargs.contour_data('latvar'), ...
            kwargs.contour_data('lonvar'), kwargs.contour_data('timevar'), ...
            kwargs.contour_data('var_of_interest'));
        
    end

    % Elevation data 
    if ~isempty(kwargs.elevation)
        [elev,elev_long,elev_lat]=m_etopo2([lonlim(1) lonlim(2) latlim(1) latlim(2)]);
        kwargs.elevation("elev") = elev;
        kwargs.elevation("elev_long") = elev_long;
        kwargs.elevation("elev_lat") = elev_lat;
    end

    % Raster image 
    if ~isnan(kwargs.raster_image)
        [raster_array,raster_ref] = readgeoraster(kwargs.raster_image);
        % correct the issue with readgeoraster turning the array upside-down
        raster_array_f = flipud(raster_array);
        kwargs.raster_image("raster_array_f") = raster_array_f;
    end

    % Labeled points
    if ~isempty(kwargs.labeled_points)
        labeled_pts = prepare_labels(kwargs.labeled_points('filename'), ...
            kwargs.start_time, kwargs.end_time); 
        labeled_pts = select_bbox(labeled_pts, 'latitude', 'longitude', ...
            latlim(1), latlim(2), lonlim(1), lonlim(2));
        kwargs.labeled_points('data') = labeled_pts;
    end
    
    
    %% plotting
    frame_number = 0;

    if kwargs.last_frame_only
        generate_frame(tracks, kwargs.end_time, latlim=latlim, lonlim=lonlim, ...
            start_time=kwargs.start_time, end_time=kwargs.end_time, frame_number=frame_number, ...
            output_directory=kwargs.output_directory, frame_resolution=kwargs.frame_resolution, ...
            labeled_points=kwargs.labeled_points, raster_image=kwargs.raster_image, ...
            raster_cmap=kwargs.raster_cmap, shapefile_stack = kwargs.shapefile_stack, ...
            elevation=kwargs.elevation, gridded_data=kwargs.gridded_data, ...
            contour_data=kwargs.contour_data, ...
            show_legend=kwargs.show_legend)
    else
        for k=kwargs.start_time:kwargs.track_frequency:kwargs.end_time
            generate_frame(tracks, k, latlim=latlim, lonlim=lonlim, ...
                start_time=kwargs.start_time, end_time=kwargs.end_time, frame_number=frame_number, ...
                output_directory=kwargs.output_directory, frame_resolution=kwargs.frame_resolution, ...
                labeled_points=kwargs.labeled_points, raster_image=kwargs.raster_image, ...
                raster_cmap=kwargs.raster_cmap, shapefile_stack = kwargs.shapefile_stack, ...
                elevation=kwargs.elevation, gridded_data=kwargs.gridded_data, ...
                contour_data=kwargs.contour_data, ...
                show_legend=kwargs.show_legend)
        end
    end
end
