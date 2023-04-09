classdef Shapefile < handle
    properties
        filename
        geometry_type
        data
        point_color % For point geometry
        marker_style % For point geometry
        marker_size % For point geometry
        line_color % For line geometry
        line_width % For line geometry
        edge_color % For polygon geometry
        face_color % For polygon geometry
        face_alpha % For polygon geometry
    end 

    methods
        function obj = Shapefile(filein, kwargs)
            arguments
                filein
                kwargs.point_color = NaN
                kwargs.marker_style = NaN
                kwargs.marker_size = NaN
                kwargs.line_color = NaN
                kwargs.line_width = NaN
                kwargs.edge_color = NaN
                kwargs.face_color = NaN
                kwargs.face_alpha = NaN
            end
            % Constructor
            if nargin > 0
                obj.filename = filein;
                % Get geometry of shapefile 
                obj.geometry_type = lower(shaperead(filein, 'RecordNumbers', 1).Geometry);

                obj.point_color = kwargs.point_color;
                obj.marker_style = kwargs.marker_style;
                obj.marker_size = kwargs.marker_size;
                obj.line_color = kwargs.line_color;
                obj.line_width = kwargs.line_width;
                obj.edge_color = kwargs.edge_color;
                obj.face_color = kwargs.face_color;
                obj.face_alpha = kwargs.face_alpha;
            end
        end

        function obj = load_data(obj)
            obj.data = shaperead(obj.filename);
        end

        function result = is_point(obj)
            result = contains(obj.geometry_type, 'point');
        end

        function result = is_line(obj)
            result = strcmp(obj.geometry_type, 'line');
        end

        function result = is_poly(obj)
            result = strcmp(obj.geometry_type, 'polygon');
        end

    end

end
            


