function filtered_tracks = select_timerange_tracks(track_data, start_time, end_time)

    filtered_tracks = track_data((track_data.timestamp >= start_time) & (track_data.timestamp <= end_time), :);
end