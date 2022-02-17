function fig = animate_track_annotated(data, var, output_file)
    % Create an animation of track data annotated with an environmental variable
    %
    % Args:
    %     data (timetable): Movebank dataset annotated with environmental data
    %     var (char): variable name of the column for the environmental data to use
    %     output_file (char): filename where the animation will be saved
    %
    % Returns:
    %     Figure: Animation of the animal track annotated with the environmental data

    fig = figure();

    %options
    track_color = 'y';
    % sz = 100;

    c = gradient(data.(var));

    gx = geoaxes;
    buffer = 0.10 * (max([(max(data.location_lat)-(min(data.location_lat))) (max(data.location_long)-(min(data.location_long)))]));
    geolimits(gx, [(min(data.location_lat) - buffer) (max(data.location_lat) + buffer)],[(min(data.location_long)-buffer) (max(data.location_long)+buffer)])
    geobasemap(gx,'satellite')

    v = VideoWriter(output_file, 'Uncompressed AVI');

    open(v);
    hold on;

    %fake points to get color bar ready
    scatter(gx, data.location_lat(1), data.location_long(1), 1, max(c),'MarkerFaceAlpha',0,'MarkerEdgeAlpha',0)
    scatter(gx, data.location_lat(1), data.location_long(1), 1, min(c),'MarkerFaceAlpha',0,'MarkerEdgeAlpha',0)
    colormap(gx, "winter")
    bar = colorbar(gx);
    bar.Label.String = var;


    an = animatedline(gx, 'Color', track_color);
    for k=1:length(data.location_lat)
        addpoints(an, data.location_lat(k), data.location_long(k));
        scatter(gx, data.location_lat(k), data.location_long(k), 100, c(k), 'filled')

        drawnow
        frame = getframe(gcf);
        writeVideo(v, frame)
    end
    close(v)