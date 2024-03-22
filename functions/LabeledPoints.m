classdef LabeledPoints < handle
    properties
        filepath
        data
        marker_size
        marker_color
        text_size
        text_color
        show_text
        
    end

    methods

        function obj = LabeledPoints(filepath, kwargs)
            % Constructor
            arguments
                filepath
                kwargs.marker_size = 10
                kwargs.marker_color = 'k'
                kwargs.text_size = 8
                kwargs.text_color = 'k'
                kwargs.show_text = true
            end

            if nargin > 0
                obj.filepath = filepath;
                obj.marker_size = kwargs.marker_size;
                obj.marker_color = kwargs.marker_color;
                obj.text_size = kwargs.text_size;
                obj.text_color = kwargs.text_color;
                obj.show_text = kwargs.show_text;

                obj.data = LabeledPoints.prepare_labels(filepath);
            end
        end

        function obj = update_start_end_times(obj, start_time, end_time)
            % Set start and end times to start and end times of animation for rows where it is missing
            % If start and end times were missing, the point should show
            % the whole time 

            vars = obj.data.Properties.VariableNames;

            % Add start and end times if not in file
            if ~any(strcmp(vars,'start_time'))
                obj.data.('start_time') = repmat(start_time, height(obj.data),1);
            end
        
            if ~any(strcmp(vars,'end_time'))
                obj.data.('end_time') = repmat(end_time, height(obj.data),1);
            end

            obj.data.start_time = fillmissing(obj.data.start_time, 'constant', start_time);
            obj.data.end_time = fillmissing(obj.data.end_time, 'constant', end_time);
        end

        function obj = plot(obj, frame_time)
            % Plot the labeled points

            % Select only the point that should be visible at the frame time step
            labels_filtered = obj.data(frame_time>=obj.data.start_time & frame_time<=obj.data.end_time,:);

            % Plot the points
            m_scatter(labels_filtered.longitude, labels_filtered.latitude, ...
                obj.marker_size, obj.marker_color, 'filled')

            % Add labels
            if obj.show_text
                for i=1:height(labels_filtered)
                    m_text(labels_filtered.label_longitude(i),labels_filtered.label_latitude(i), ...
                        labels_filtered.label{i}, 'horizontal', labels_filtered.horizontal_alignment{i}, ...
                        'FontSize', obj.text_size, 'Color', obj.text_color)
                end
            end
        end
    end

    methods(Static)
        function labels = prepare_labels(filepath)

            opts = detectImportOptions(filepath);
            opts = setvartype(opts, {'label'}, {'char'});
        
            labels = readtable(filepath, opts);
        
            vars = labels.Properties.VariableNames;
        
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
        end

    end 
end