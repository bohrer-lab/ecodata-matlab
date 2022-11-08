function [inds,c] = group_by_individual_and_resample(data, resample_interval)
    % Group track data by individual_local_identifier and resample to a specified time frequency  
    %
    % Args:
    %     data (timetable): Movebank dataset
    %     resample_interval (duration): The time frequency to resample the
    %     track data to. e.g. days(1), hours(4)
    %
    % Returns:
    %     inds: List of individual_local_identifiers in the dataset
    %     c: cell containing the resampled track data for each individual

    data2 = data(:, {'location_lat', 'location_long', 'individual_local_identifier'});
    inds = unique(data2.individual_local_identifier);

    c = cell(1,length(inds));
    for i = 1:length(c), c{1,i} = {inds{i},data2(strcmp(data2.individual_local_identifier, inds{i}), :)}; end

    %resample
    for i = 1:length(c)
        c{1,i}{2} = sortrows(c{1,i}{2}, 'timestamp');
        c{1,i}{2} = resample_track_data(c{1,i}{2}(:, {'location_lat', 'location_long'}), resample_interval); 
    end

end