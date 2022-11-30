function selected_data = select_individuals(data, individual_identifiers)
    % Select track data for a certain individual  
    %
    % Args:
    %     data (timetable): Movebank dataset
    %     individual_identifiers (cell array): the
    %     invididual_local_identifiers to include in the output dataset 
    %
    % Returns:
    %     filtered_data: Subset of the original dataset containing just
    %     data for the selected individual

    selected_data = data(ismember(data.individual_local_identifier, individual_identifiers),:);
