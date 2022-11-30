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

