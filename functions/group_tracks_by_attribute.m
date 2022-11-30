function groups = group_tracks_by_attribute(track_data, var)
    % Group track data by a specified attribure 
    %
    % Args:
    %     data (timetable): Movebank dataset
    %     var (char): The attribute to use for grouping
    %
    % Returns:
    %     groups (Map): Map containing unique values of the attribute as
    %     keys and the corresponding tables of track data 

    group_labels = unique(track_data.(var));
    groups = containers.Map();
    
    if isnumeric(group_labels)
        for i = 1:length(group_labels)
            groups(num2str(group_labels(i))) = track_data(track_data.(var) == group_labels(i), :); 
        end
        
    else
        for i = 1:length(group_labels)
            groups(group_labels{i}) = track_data(strcmp(track_data.(var), group_labels{i}), :);
        end
    end
