function fig = animate_track(data, output_animation)
    % Create an animation of Movebank track data
    %
    % Args:
    %     data (timetable): Movebank dataset
    %     var (char): variable name of the column for the environmental data to use
    %     output_file (char): filename where the animation will be saved
    %
    % Returns:
    %     Figure: Animation of the animal track annotated with the environmental data

    fig = figure(1);

    %display options
    track_color = 'c';
    track_marker = 'o';

    %set up geo axes and basemap
    gx = geoaxes;
    buffer = 0.10 * (max([(max(data.location_lat)-(min(data.location_lat))) (max(data.location_long)-(min(data.location_long)))]));
    geolimits(gx, [(min(data.location_lat) - buffer) (max(data.location_lat) + buffer)],[(min(data.location_long)-buffer) (max(data.location_long)+buffer)])
    geobasemap(gx,'satellite')

    %initialize video writer and animated line
    v = VideoWriter(output_animation, 'Uncompressed AVI');
    open(v);
    hold on;
    an = animatedline(gx, Color=track_color, Marker=track_marker);

    %loop through data points and save frames
    for k=1:length(data.location_lat)
        addpoints(an, data.location_lat(k), data.location_long(k));
        drawnow
        frame = getframe(gcf);
        writeVideo(v, frame)
    end
    close(v)