function animate_gridded_ndvi(track_data, gridded_data, gridded_varname, kwargs)
    arguments
        track_data
        gridded_data
        gridded_varname
        kwargs.output_directory
        kwargs.output_file
%         kwargs.output_fname
        kwargs.individuals = []
        kwargs.start_time
        kwargs.end_time 
        kwargs.track_memory
        kwargs.frame_rate 
        kwargs.save_frames = false
        kwargs.frame_resolution = 600
        kwargs.latmin
        kwargs.latmax
        kwargs.lonmin
        kwargs.lonmax
        kwargs.cmap = 'green'
        kwargs.invert_cmap = true 
    end

    close all
    
    
    %% read and prepare data
    data = track_data;

    % Select bbox 
    data = data((data.location_long>=kwargs.lonmin) & (data.location_long <=kwargs.lonmax) & ...
        (data.location_lat>=kwargs.latmin) & (data.location_lat <= kwargs.latmax),:);
    
    % filter to time of interest
    data = data((data.timestamp >= kwargs.start_time) & (data.timestamp <= kwargs.end_time), :);
    
    % split to separate tt for each individual animal,
    % and interpolate to daily
    [inds, c] = group_by_individual_and_resample(data, days(1));
    
    
    % unpack MODIS netcdf data
    nc_lat = ncread(gridded_data, 'lat');
    nc_long = ncread(gridded_data, 'lon');
    nc_var= ncread(gridded_data, gridded_varname);
    nc_time = ncread(gridded_data, 'time');
    
    %TODO 
    % Time in the MODIS netcdf if stored as days since 2000-01-01. Convert to
    % regular timestamp
    nctimestamp = datetime(datevec(double(nc_time + datenum('2000-01-01 00:00:00'))));
    
    % adjust the start time for the plot so it doesn't start before there is
    % MODIS data available
    if kwargs.start_time < min(nctimestamp); kwargs.start_time = min(nctimestamp); end
    
    %% Set up for map and animation
    
    
    % Set up video writer
%     videoFilename = fullfile(kwargs.output_directory, kwargs.output_fname);
%     videoFilename = kwargs.output_file;
% 
%     if exist(videoFilename,'file')
%         delete(videoFilename)
%     end
%     writer = VideoWriter(videoFilename);
%     writer.FrameRate = kwargs.frame_rate;
%     writer.Quality = 100;
%     open(writer)
%     
%     % get geolimits for map
%     f = figure(Visible='off');
%     buffer = 0.10 * (max([(max(data.location_lat)-(min(data.location_lat))) (max(data.location_long)-(min(data.location_long)))]));
%     [latlim, lonlim] = get_geolimits(data, .10);
%     
%     % Projection
%     m_proj('lambert','lon',lonlim,'lat',latlim);
%     m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 3);
%     % set(gcf,'color','w');   % Set background colour before m_image call
%     
% %     fig = gcf;
% %     fig.WindowState = 'maximized';
%     
%     
%     hold on
    
    
    
    
    
    
    %% plotting
    frame_number = 0;
    for k=kwargs.start_time:kwargs.end_time

            % get geolimits for map
        f = figure(Visible='off');
        buffer = 0.10 * (max([(max(data.location_lat)-(min(data.location_lat))) (max(data.location_long)-(min(data.location_long)))]));
        [latlim, lonlim] = get_geolimits(data, .10);
        
        % Projection
        m_proj('lambert','lon',lonlim,'lat',latlim);
        m_grid('linestyle', 'none', 'tickdir', 'out', 'linewidth', 3);
        % set(gcf,'color','w');   % Set background colour before m_image call
        
    %     fig = gcf;
    %     fig.WindowState = 'maximized';
        
        
        hold on
    
        if ismember(k, nctimestamp)
            A = nc_var(:, :, nctimestamp == k)';
            if kwargs.invert_cmap
                colormap(flipud(m_colmap(kwargs.cmap)));
            else 
                colormap(m_colmap(kwargs.cmap))
            end
            m_image(nc_long,nc_lat, A);
    %         alpha 0.2;
            caxis([-0.1 1])
            cb = colorbar;
            ylabel(cb,strrep(gridded_varname, '_', ' '),'FontSize',12);
        end
    
        hold on
    
        h_cells = cell(1,length(inds));
        s_cells = cell(1,length(inds));
    
        for i=1:length(inds)
            data_ind = c{1,i}{2};
    
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
                    zeds = zeros(size(xseg,1), 1);
                    blk = [zeds zeds zeds];
                    segColors = blk;
    %                 segColors = flipud(spring(size(xseg,1))); % Choose a colormap
                    scatterColor = [101/255 67/255 33/255];
                    seg_amap = logspace(0,1,size(xseg,1));
                    seg_amap = seg_amap/max(seg_amap);
    
        %             sc_amap = logspace(0,1,size(x,1));
        %             sc_amap = sc_amap/max(sc_amap);
    
                    segColors(:,4) = seg_amap;
    
                    h = m_plot(xseg',yseg','LineWidth',3);
                    s = m_scatter(x(end),y(end),150,scatterColor,'h','filled');
                    h_cells{i} = h;
                    s_cells{i} = s;
                    set(h, {'Color'}, mat2cell(segColors,ones(size(xseg,1),1),4))
    %             set(s, 'AlphaData', sc_amap)
                end
    
            end
    
    
        end
    
    %     addpoints(an, data.location_lat(k), data.location_long(k));
            title(datestr(k))
    
            drawnow
    
            % Save the current frame as an RGB image.
    %         gcf.WindowState = 'maximized';      % Maximize the figure to your whole screen.
%             frame = getframe(gcf);
    
    
            if kwargs.save_frames
                %save image of each frame
                % Construct an output image file name.
                outputBaseFileName = sprintf('Frame%s.png', num2str(frame_number));
                outputFullFileName = fullfile(kwargs.output_directory, outputBaseFileName);
                exportgraphics(gcf,outputFullFileName,'Resolution', kwargs.frame_resolution)
                frame_number = frame_number + 1;
                close(f)
            end

    
    
%         writeVideo(writer,frame);
        for i=1:length(h_cells); delete(h_cells{i}); end
        for i=1:length(s_cells); delete(s_cells{i}); end
    %     delete(CH)
    
    %     delete(gs);
    %     clf
    end
%     close(writer)
    close all