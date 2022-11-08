function animate_gridded_ndvi(track_data, kwargs)
    arguments
        track_data
        kwargs.gridded_data
        kwargs.gridded_varname
        kwargs.shapefile = NaN
        kwargs.raster_image = NaN
        kwargs.raster_cmap = NaN
        kwargs.labeled_pointsf = NaN
        kwargs.output_directory
        kwargs.individuals = []
        kwargs.start_time
        kwargs.end_time 
        kwargs.track_memory
        kwargs.frame_resolution = 600
        kwargs.latmin = NaN
        kwargs.latmax = NaN
        kwargs.lonmin = NaN
        kwargs.lonmax = NaN
        kwargs.cmap = 'green'
        kwargs.invert_cmap = true 
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
    
    % split to separate tt for each individual animal,
    % and interpolate to daily
    [inds, c] = group_by_individual_and_resample(data, days(1));

    for i=1:length(c)
        % filter to time of interest
        d =  c{1,i}{2};
        c{1,i}{2} = d((d.timestamp >= kwargs.start_time) & (d.timestamp <= kwargs.end_time), :);
    end
    
    
    % unpack MODIS netcdf data
    nc_lat = ncread(kwargs.gridded_data, 'lat');
    nc_long = ncread(kwargs.gridded_data, 'lon');
    nc_var= ncread(kwargs.gridded_data, kwargs.gridded_varname);
    nc_time = ncread(kwargs.gridded_data, 'time');
    
    %TODO 
    % Time in the MODIS netcdf if stored as days since 2000-01-01. Convert to
    % regular timestamp
    nctimestamp = datetime(datevec(double(nc_time + datenum('2000-01-01 00:00:00'))));
    
    % adjust the start time for the plot so it doesn't start before there is
    % MODIS data available
    if kwargs.start_time < min(nctimestamp); kwargs.start_time = min(nctimestamp); end


    [raster_array,raster_ref] = readgeoraster(kwargs.raster_image);
    % correct the issue with readgeoraster turning the array upside-down
    raster_array_f = flipud(raster_array);
    
    figure(Visible='off');
    if kwargs.invert_cmap
        gridded_cmap = flipud(m_colmap(kwargs.cmap));
    else 
        gridded_cmap = m_colmap(kwargs.cmap);
    end

    % Labeled points
    if ~isnan(kwargs.labeled_pointsf)
        labeled_pts = readtable(kwargs.labeled_pointsf); 
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
%         dates = withtol(kwargs.start_time,days(14));
%         first_date = dates(1);
%         current_data = nc_var(:, :, nctimestamp == first_date)';
        if ismember(k, nctimestamp)
            A = nc_var(:, :, nctimestamp == k)';
            grd = m_image(nc_long,nc_lat, A);
            current_data = A;
    %         alpha 0.2;
        else
            grd = m_image(nc_long,nc_lat, current_data);

        end
        colormap(gridded_cmap)

        caxis([-0.1 1])
            cb = colorbar;
            ylabel(cb,strrep(kwargs.gridded_varname, '_', ' '),'FontSize',12);
        
        hold on

        freezeColors

    
        % raster image
        if ~isnan(kwargs.raster_image)

            % color map for the raster. Here using just a single color  
            colormap(kwargs.raster_cmap);
            r_img = m_image(raster_ref.LongitudeLimits, raster_ref.LatitudeLimits, raster_array_f);
        end
        freezeColors
        hold on

                %shapefile 
        if ~isnan(kwargs.shapefile)
            shp = shaperead(kwargs.shapefile);
        
            for i=1:length(shp)
                [shp(i).X, shp(i).Y] = m_ll2xy(shp(i).X, shp(i).Y, 'clip', 'off');
            end
            shapes =  mapshow(shp, 'color', 'k', 'LineWidth', 1.05); %'FaceColor', [.678 .847 .902]  'EdgeColor', [1 1 1]
        end

        %labeled points 
    if ~isnan(kwargs.labeled_pointsf)
        m_scatter(labeled_pts.longitude, labeled_pts.latitude, 30, 'r', 'filled')

        for i=1:height(labeled_pts)
            m_text(labeled_pts.label_longitude(i),labeled_pts.label_latitude(i), labeled_pts.label{i}, 'horizontal', labeled_pts.label_loc{i},'FontSize', 8)
        end
    end


        % So the color bar will use the cmap for the env data, not the
        % raster image 
        colormap(gridded_cmap)


        % Track data
    
        h_cells = cell(1,length(inds));
        s_cells = cell(1,length(inds));
%         track_colors = linspecer(length(inds));
        track_colors = lines(length(inds));
    
        for i=1:length(inds)
            data_ind = c{1,i}{2};
            track_color = track_colors(i, :);
    
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
    
                    h = m_plot(xseg',yseg','LineWidth',1);
                    s = m_scatter(x(end),y(end),150,scatterColor,'h','filled');
                    h_cells{i} = h;
                    s_cells{i} = s;
                    set(h, {'Color'}, mat2cell(segColors,ones(size(xseg,1),1),4))
    %             set(s, 'AlphaData', sc_amap)
                end
    
            end
        end

        % Draw axis grid at the end to make sure it isn't covered by
        % anything
        m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 3);
      
        title(datestr(k))
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