function data = read_downloaded_data(filename)
    % Read Movebank data that has already been saved locally as a csv 
    %
    % Args: 
    %     filename (str): Saved csv with Movebank data
    % 
    % Returns: 
    %     Matlab timetable of the Movebank data

    data = readtimetable(filename, 'RowTimes', 'timestamp');
