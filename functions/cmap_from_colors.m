function color_map = cmap_from_colors(colors)

% Create a 256x3 colormap array from an nx3 array of n colors

    ncolors = height(colors);
    color_map = repmat(colors, ceil(256/ncolors), 1);
    color_map = color_map(1:256, :);
end