function animate_gridded_ndvi(track_data, kwargs)
    arguments
        track_data
        kwargs.gridded_data = containers.Map() % Map of filename, and variable labels 
        kwargs.contour_data = containers.Map()
        kwargs.shapefile_stack = {}
        kwargs.raster_image = NaN
        kwargs.raster_cmap = NaN
        kwargs.labeled_points = containers.Map()
        kwargs.output_directory
        kwargs.start_time
        kwargs.end_time 
        kwargs.track_memory = 20
        kwargs.frame_resolution = 600
        kwargs.latmin = NaN
        kwargs.latmax = NaN
        kwargs.lonmin = NaN
        kwargs.lonmax = NaN
        kwargs.group_by = 'individual_local_identifier'
        kwargs.marker_style = 'hexagram'
        kwargs.track_width = 1
        kwargs.elevation = containers.Map()
    end

    close all
    
    
    % Read and prepare input datasets

    % Get geolimits for map and datasets 
    if any(isnan([kwargs.latmin kwargs.latmax kwargs.lonmin kwargs.lonmax]))
        [latlim, lonlim] = get_geolimits(track_data, .10);
    else 
        latlim = [kwargs.latmin kwargs.latmax];
        lonlim = [kwargs.lonmin kwargs.lonmax];
    end

    %% Prepare track data

    % Select bbox 
    data = select_bbox(track_data, 'location_lat', 'location_long', ...
        latlim(1), latlim(2), lonlim(1), lonlim(2));

    % Filter time range 
    data = select_timerange_tracks(data, kwargs.start_time, kwargs.end_time);
    
    % Attribute groupings for track data
    track_groups = group_and_resample_tracks(data, kwargs.group_by, days(1));
    
    % Gridded timeseries data
    if ~isempty(kwargs.gridded_data)
        [nc_lat, nc_long, nc_time, nc_var] = unpack_netcdf(kwargs.gridded_data('filename'), ...
            kwargs.gridded_data('latvar'), kwargs.gridded_data('lonvar'), kwargs.gridded_data('timevar'), ...
            kwargs.gridded_data('var_of_interest'));
    
        
        % adjust the start time for the plot so it doesn't start before there is
        % MODIS data available
        if kwargs.start_time < min(nc_time); kwargs.start_time = min(nc_time); end
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
    end

    % Raster image 
    if ~isnan(kwargs.raster_image)
        [raster_array,raster_ref] = readgeoraster(kwargs.raster_image);
        % correct the issue with readgeoraster turning the array upside-down
        raster_array_f = flipud(raster_array);
    end

    % Labeled points
    if ~isempty(kwargs.labeled_points)
        labeled_pts = readtable(kwargs.labeled_points('filename')); 
        labeled_pts = select_bbox(labeled_pts, 'latitude', 'longitude', ...
            latlim(1), latlim(2), lonlim(1), lonlim(2));
    end
    
    
    %% plotting
    frame_number = 0;
    for k=kwargs.start_time:kwargs.end_time

        %% Set up for map
    
        figure(Visible='off');
        
        % Map projection
        m_proj('Cylindrical Equal-Area','lat',latlim,'long',lonlim)
    
        hold on
    
        % Plot gridded env data
        if ~isempty(kwargs.gridded_data)

            % Color map for gridded data
            if kwargs.gridded_data('invert_cmap')
                gridded_cmap = flipud(m_colmap(kwargs.gridded_data('cmap')));
            else 
                gridded_cmap = m_colmap(kwargs.gridded_data('cmap'));
            end
    %         dates = withtol(kwargs.start_time,days(14));
    %         first_date = dates(1);
    %         current_data = nc_var(:, :, nc_time == first_date)';
            if ismember(k, nc_time)
                A = nc_var(:, :, nc_time == k)';
                grd = m_image(nc_long,nc_lat, A);
    %             current_data = A;
    %     %         alpha 0.2;
    %         else
    %             grd = m_image(nc_long,nc_lat, current_data);
    
            end
            colormap(gridded_cmap)
    
            caxis([-0.1 1])
                cb = colorbar;
                ylabel(cb,strrep(kwargs.gridded_data('var_of_interest'), '_', ' '),'FontSize',12);
            
            hold on
    
            freezeColors
        end

    
        % raster image
        if ~isnan(kwargs.raster_image)

            % color map for the raster. Here using just a single color  
            colormap(kwargs.raster_cmap);
            r_img = m_image(raster_ref.LongitudeLimits, raster_ref.LatitudeLimits, raster_array_f);
        end
        freezeColors
        hold on

        % Shapefiles 
        if ~isempty(kwargs.shapefile_stack) 
            for n_shp=1:length(kwargs.shapefile_stack)
                shp_layer = kwargs.shapefile_stack{n_shp};
                shp = shaperead(shp_layer('filename'));
                 
                % Convert to m_map coordinates
                for i=1:length(shp)
                    [shp(i).X, shp(i).Y] = m_ll2xy(shp(i).X, shp(i).Y, 'clip', 'off');
                end
                
                % Check geometry type and plot
                if strcmp(shp(1).Geometry, 'Line')
                    mapshow(shp, 'color', shp_layer('LineColor'), 'LineWidth', shp_layer('LineWidth')); 
                elseif strcmp(shp(1).Geometry, 'Polygon')
                    mapshow(shp,'FaceColor', shp_layer('FaceColor'), ...
                        'EdgeColor', shp_layer('EdgeColor'), 'FaceAlpha', shp_layer('FaceAlpha'));
                end
            end
        end

        % Contour data 
        if ~isempty(kwargs.contour_data)
            % make grid for lat/lon 
            [LAT,LON] = meshgrid(contour_lat, contour_lon);
            m_contour(LON, LAT, contour_var(:,:,contour_time==k), ...
                'ShowText',kwargs.contour_data('ShowText'), ...
                'LineWidth', kwargs.contour_data('LineWidth'), ...
                'LineColor', kwargs.contour_data('LineColor'))
        end

        % Elevation 
        if ~isempty(kwargs.elevation)
            m_etopo2('contour', floor(linspace(min(elev, [], 'all'), ...
                max(elev, [], 'all'), kwargs.elevation('nlevels'))), ...
                'LineColor', kwargs.elevation('LineColor'), ...
                'LineWidth', kwargs.elevation('LineWidth'), ...
                'ShowText', kwargs.elevation('ShowText'))
        end

        %labeled points 
        if ~isempty(kwargs.labeled_points)
            m_scatter(labeled_pts.longitude, labeled_pts.latitude, ...
                kwargs.labeled_points("marker_size"), kwargs.labeled_points("marker_color"), 'filled')
    
            for i=1:height(labeled_pts)
                m_text(labeled_pts.longitude(i),labeled_pts.latitude(i), ...
                    labeled_pts.label{i}, 'horizontal', 'left', 'FontSize', 8)
            end
        end


        % So the color bar will use the cmap for the env data
        if ~isempty(kwargs.gridded_data)
            colormap(gridded_cmap)
        end


        % Track data

        % Attribute grouping 
        group_labels = track_groups.keys;
        track_colors = lines(length(group_labels));

        % Create legend items for each group
        legend_items = gobjects(length(group_labels),1);
        for l=1:length(legend_items)
            legend_items(l) = scatter(nan, nan, 150, track_colors(l, :), kwargs.marker_style,'filled');
        end
        
        % Loop for attribute groups
        for j=1:length(track_groups)
            
            track_color = track_colors(j, :);
            group = track_groups(group_labels{j});
            inds = group.keys;

            % Plot each individual in the group
            h_cells = cell(1,length(inds));
            s_cells = cell(1,length(inds));
    
            for i=1:length(inds)
                data_ind = group(inds{i});
        
                if max(data_ind.timestamp) >= k
        
                    if height(data_ind(timerange(kwargs.start_time,k), :)) < kwargs.track_memory
        
                        oldest_point = kwargs.start_time;
                    else
        
                        oldest_point = data_ind.timestamp(find(data_ind.timestamp == k) - kwargs.track_memory + 1);
                    end
        
                    x = data_ind.location_long(oldest_point:k);
                    y = data_ind.location_lat(oldest_point:k);
        
                    if ~isempty(x)
                        xseg = [x(1:end-1),x(2:end)];
                        yseg = [y(1:end-1),y(2:end)];
        
            %             scatterColors = flipud(hot(size(x,1)));
    %                     zeds = zeros(size(xseg,1), 1);
    %                     trace_colors = [zeds zeds zeds];
    
                        trace_colors = repmat(track_color, size(xseg,1), 1);
                        segColors = trace_colors;
        %                 segColors = flipud(spring(size(xseg,1))); % Choose a colormap
                        scatterColor = track_color;%[101/255 67/255 33/255];
    %                     seg_amap = logspace(0,1,size(xseg,1));
    %                     seg_amap = seg_amap/max(seg_amap);
    
                        seg_amap = repmat(0.5, size(xseg,1), 1);
        
            %             sc_amap = logspace(0,1,size(x,1));
            %             sc_amap = sc_amap/max(sc_amap);
        
                        segColors(:,4) = seg_amap;
        
                        h = m_plot(xseg',yseg','LineWidth',kwargs.track_width);
                        s = m_scatter(x(end),y(end),150,scatterColor,kwargs.marker_style,'filled');
                        
                        
                        h_cells{i} = h;
                        s_cells{i} = s;
                        set(h, {'Color'}, mat2cell(segColors,ones(size(xseg,1),1),4))
        %             set(s, 'AlphaData', sc_amap)
                    end
        
                end
            end
        end

        % Draw axis grid at the end to make sure it isn't covered by
        % anything
        m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 3);
      
        title(datestr(k))
        legend(legend_items, group_labels, 'Location', 'northeastoutside')
        drawnow
    
        %save image of each frame
        % Construct an output image file name.
        outputBaseFileName = sprintf('Frame%s.png', num2str(frame_number));
        outputFullFileName = fullfile(kwargs.output_directory, outputBaseFileName);
        exportgraphics(gcf,outputFullFileName,'Resolution', kwargs.frame_resolution)
        frame_number = frame_number + 1;

        % Delete variables 
        for i=1:length(h_cells); delete(h_cells{i}); end
        for i=1:length(s_cells); delete(s_cells{i}); end
        if exist('grd', 'var'); clear grd; end
        if exist('h', 'var'); clear h; end
        if exist('s', 'var'); clear s; end
        if exist('r_img', 'var'); clear r_img; end


        % Make sure no figure objects stay in memory
        clf
        close all
    end
end