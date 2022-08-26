function individual_data = select_individual(data, individual_ID)
    % Select track data for a certain individual  
    %
    % Args:
    %     data (timetable): Movebank dataset
    %     individual_ID (char): the invididual_local_identifier
    %
    % Returns:
    %     individual_data: Subset of the original dataset containing just
    %     data for the selected individual

    individual_data = data(strcmp(data.individual_local_identifier, individual_ID), :);
