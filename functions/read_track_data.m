function data = read_track_data(filename)
    % Read Movebank data that has already been saved locally as a csv
    %
    % Args:
    %     filename (str): Saved csv with Movebank data
    %
    % Returns:
    %     timetable: Matlab timetable of the Movebank data

    opts = detectImportOptions(filename);
    opts = setvartype(opts, {'individual_local_identifier'}, {'char'});

    data = readtimetable(filename, opts, 'RowTimes', 'timestamp');

   
