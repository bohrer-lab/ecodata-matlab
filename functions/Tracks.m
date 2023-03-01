classdef Tracks < handle
    properties
        filepath
        lat_label
        lon_label
        frequency 
        track_memory
        marker_style
        marker_size
        marker_color
        track_width
        track_cmap
        fade_tracks
        track_alpha 
        group_by
        data
        track_groups

    end

    methods

        function obj = Tracks(filepath, kwargs)
            % Constructor
            arguments
                filepath
                kwargs.lat_label = "location_lat"
                kwargs.lon_label = "location_long"
                kwargs.frequency = days(1)
                kwargs.track_memory = 20
                kwargs.marker_style = 'hexagram'
                kwargs.marker_size = 150
                kwargs.marker_color = NaN
                kwargs.track_width = 1
                kwargs.track_cmap = lines
                kwargs.fade_tracks = false
                kwargs.track_alpha= 0.6
                kwargs.group_by = 'individual_local_identifier'


            end
            if nargin > 0
                obj.filepath = filepath; 
                obj.lat_label = kwargs.lat_label;
                obj.lon_label = kwargs.lon_label;
                obj.data = read_track_data(filepath);

                obj.lat_label = kwargs.lat_label;
                obj.lon_label = kwargs.lon_label;
                obj.frequency = kwargs.frequency;
                obj.track_memory = kwargs.track_memory;
                obj.marker_style = kwargs.marker_style;
                obj.marker_size = kwargs.marker_size;
                obj.marker_color = kwargs.marker_color;
                obj.track_width = kwargs.track_width;
                obj.track_cmap = kwargs.track_cmap;
                obj.fade_tracks = kwargs.fade_tracks;
                obj.track_alpha = kwargs.track_alpha;
                obj.group_by = kwargs.group_by;
            end
        end

        function obj = select_bbox(obj, latmin, latmax, lonmin, lonmax)
            % Subset data inside a bounding box 
            obj.data = obj.data((obj.data.(obj.lon_label)>=lonmin) & (obj.data.(obj.lon_label) <=lonmax) & ...
                (obj.data.(obj.lat_label)>=latmin) & (obj.data.(obj.lat_label) <= latmax),:);
        end

        function obj = select_timerange(obj, start_time, end_time)

            filtered_data = obj.data((obj.data.timestamp >= start_time) & (obj.data.timestamp <= end_time), :);
            obj.data = filtered_data;
        end

        function obj = select_individuals(obj, individual_identifiers)
            % Select track data for certain individuals  
            %
            % Args:
            %     individual_identifiers (cell array): the
            %     invididual_local_identifiers to include in the output dataset 

            obj.data = obj.data(ismember(obj.data.individual_local_identifier, individual_identifiers),:);
        end

        function obj = group_and_resample(obj)
            obj.track_groups = group_and_resample_tracks(obj.data, obj.group_by, obj.frequency);
        end


    end
end


