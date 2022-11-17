function fullpath = get_fullpath(filename)
    % Get full resolved filepath for files that are on the MATLAB path
    % already
    
    [dir, fname, ext] = fileparts(which(filename));
    fullpath = fullfile(dir, [fname ext]);