function resampled_data = resample_track_data(data, dt)
    % Resample movebank track data
    %
    % Args:
    %     data (timetable): Movebank dataset
    %     dt (duration): time frequency, e.g. days(2) or minutes(30)
    %
    % Returns:
    %     resampled_data: resampled data 

    resampled_data = retime(data,'regular','linear','TimeStep',dt);