function data_subset = select_bbox(data, lat_label, lon_label, latmin, latmax, lonmin, lonmax)
    % Subset data inside a bounding box 
    data_subset = data((data.(lon_label)>=lonmin) & (data.(lon_label) <=lonmax) & ...
        (data.(lat_label)>=latmin) & (data.(lat_label) <= latmax),:);
end