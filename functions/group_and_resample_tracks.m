function track_groups = group_and_resample_tracks(track_data, group_var, resample_interval)

    % Group by attribute
    track_groups = group_tracks_by_attribute(track_data, group_var);
    labels = track_groups.keys;
    
    % Group by individual and resample
    for i=1:length(labels)
        track_groups(labels{i}) = group_by_individual_and_resample(track_groups(labels{i}), resample_interval);
    end