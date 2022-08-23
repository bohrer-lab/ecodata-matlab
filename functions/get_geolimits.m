function [latlim, lonlim] = get_geolimits(data, buffer_size)

    buffer = buffer_size * (max([(max(data.location_lat)-(min(data.location_lat))) (max(data.location_long)-(min(data.location_long)))]));
    latlim = [(min(data.location_lat) - buffer) (max(data.location_lat) + buffer)];
    lonlim = [(min(data.location_long) - buffer) (max(data.location_long) + buffer)];
