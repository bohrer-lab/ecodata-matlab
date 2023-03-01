function generate_frame(tracks, frame_time, kwargs)
    arguments
        tracks
        frame_time
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
        kwargs.latlim = NaN;
        kwargs.lonlim = Nan;
        kwargs.frame_number = 1;
        kwargs.show_legend=true;
    end



    %% Set up for map

    figure(Visible='off');
    
    % Map projection
    m_proj('Cylindrical Equal-Area','lat', kwargs.latlim,'long', kwargs.lonlim)

    hold on

    % Plot gridded env data
    if ~isempty(kwargs.gridded_data)

        % Load new chunk of gridded data
        nc_time_index=read_nc_timestamps(kwargs.gridded_data('filename'), 'time');;
        times_before_frame = nc_time_index(nc_time_index <= frame_time);
        current_nc_time = find(min(abs(times_before_frame-frame_time))==abs(times_before_frame-frame_time));

        [nc_lat, nc_long, nc_time, nc_var] = unpack_netcdf( ...
                kwargs.gridded_data('filename'), ...
                kwargs.gridded_data('latvar'), ...
                kwargs.gridded_data('lonvar'), ...
                kwargs.gridded_data('timevar'), ...
                kwargs.gridded_data('var_of_interest'), ...
                start=current_nc_time, count=1);
%         while chunk_tmax < frame_time
%             nc_start = nc_start + kwargs.chunk_size;
%             [nc_lat, nc_long, nc_time, nc_var] = unpack_netcdf( ...
%                 kwargs.gridded_data('filename'), ...
%                 kwargs.gridded_data('latvar'), ...
%                 kwargs.gridded_data('lonvar'), ...
%                 kwargs.gridded_data('timevar'), ...
%                 kwargs.gridded_data('var_of_interest'), ...
%                 start=nc_start, count=1);
%             
% %                 chunk_tmax = max(nc_time);
%         end


        % Color map for gridded data
        if kwargs.gridded_data('invert_cmap')
            gridded_cmap = flipud(m_colmap(kwargs.gridded_data('cmap')));
        else 
            gridded_cmap = m_colmap(kwargs.gridded_data('cmap'));
        end

        if ismember(frame_time, nc_time)
            A = nc_var(:, :, nc_time == frame_time)';
            grd = m_image(nc_long,nc_lat, A);
%             current_nc_time = frame_time;
%             current_nc_frame = A;
        % In case gridded dataset starts later than tracks
%         elseif current_nc_time < frame_time
%             % Use last timestep that had data 
%             grd = m_image(nc_long, nc_lat, current_nc_frame);
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
        m_contour(LON, LAT, contour_var(:,:,contour_time==frame_time), ...
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
        labeled_pts = kwargs.labeled_points("data");
        labels_filtered = labeled_pts(frame_time>=labeled_pts.start_time & frame_time<=labeled_pts.end_time,:);

        m_scatter(labels_filtered.longitude, labels_filtered.latitude, ...
            kwargs.labeled_points("marker_size"), kwargs.labeled_points("marker_color"), 'filled')

        for i=1:height(labels_filtered)
            m_text(labels_filtered.longitude(i),labels_filtered.latitude(i), ...
                labels_filtered.label{i}, 'horizontal', 'left', 'FontSize', 8)
        end
    end


    % So the color bar will use the cmap for the env data
    if ~isempty(kwargs.gridded_data)
        colormap(gridded_cmap)
    end


    % Track data

    % Attribute grouping 
    group_labels = tracks.track_groups.keys;
    track_colors = tracks.track_cmap(1:length(group_labels),:);

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
  
    title(datestr(frame_time))
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
%         for i=1:length(h_cells); delete(h_cells{i}); end
%         for i=1:length(s_cells); delete(s_cells{i}); end
    if exist('grd', 'var'); clear grd; end
    if exist('h', 'var'); clear h; end
    if exist('s', 'var'); clear s; end
    if exist('r_img', 'var'); clear r_img; end


    % Make sure no figure objects stay in memory
    clf
    close all
end