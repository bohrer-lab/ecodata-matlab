function fig = plot_annotated_track(data, var, output_figure)
    % Create a static plot of track data annotated with an environmental variable
    %
    % Args:
    %     data (timetable): Movebank dataset annotated with environmental data
    %     var (char): variable name of the column for the environmental data to use
    %     output_file (char): filename where the figure will be saved
    %
    % Returns:
    %     Figure: Plot of the animal track annotated with the environmental data

    %options
    track_color = 'y';
    % sz = 100;

    c = gradient(data.(var));

    fig = figure();

    gx = geoaxes;

    % Set plot boundaries with 10% buffer
    buffer = 0.10 * (max([(max(data.location_lat)-(min(data.location_lat))) (max(data.location_long)-(min(data.location_long)))]));
    geolimits(gx, [(min(data.location_lat) - buffer) (max(data.location_lat) + buffer)],[(min(data.location_long)-buffer) (max(data.location_long)+buffer)])

    % Use satellite basemap
    geobasemap(gx,'satellite')

    hold on;
    geoplot(gx, data.location_lat, data.location_long, track_color)

    scatter(gx, data.location_lat, data.location_long, 100, c, 'filled')
    geoplot(gx, data.location_lat, data.location_long, track_color)
    colormap(gx, "winter")
    bar = colorbar(gx);
    bar.Label.String = var;

    saveas(fig, output_figure, 'png')
end