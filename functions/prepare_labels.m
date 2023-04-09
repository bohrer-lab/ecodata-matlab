function labels = prepare_labels(labelfile, start_time, end_time)

    labels = readtable(labelfile);
    
    vars = labels.Properties.VariableNames;
    
    % Add start and end times if not in file 
    if ~any(strcmp(vars,'start_time'))
        labels.('start_time') = repmat(start_time, height(labels),1);
    end
    
    if ~any(strcmp(vars,'end_time'))
        labels.('end_time') = repmat(end_time, height(labels),1);
    end
    
    % Set start and end times for rows where it is missing 
    labels.start_time = fillmissing(labels.start_time, 'constant', start_time);
    labels.end_time = fillmissing(labels.end_time, 'constant', end_time);

    % Set label locations if they aren't specified
    if ~any(strcmp(vars, 'label_longitude'))
        labels.('label_longitude') = labels.longitude;
    end
    if ~any(strcmp(vars, 'label_latitude'))
        labels.('label_latitude') = labels.latitude;
    end
    labels.label_longitude(ismissing(labels.label_longitude)) = labels.longitude(ismissing(labels.label_longitude));
    labels.label_latitude(ismissing(labels.label_latitude)) = labels.latitude(ismissing(labels.label_latitude));



    % Set horizontal alignment if not defined
    if ~any(strcmp(vars, 'horizontal_alignment'))
        labels.('horizontal_alignment') = repmat({''}, height(labels), 1);
    end
    labels.horizontal_alignment = fillmissing(labels.horizontal_alignment, 'constant', {'left'});



