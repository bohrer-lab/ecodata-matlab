%% options
trackfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/small_datasets/caribou_data.csv';
modisncfile = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/data/user_datasets/MOD13A1.006_500m_aid0001_all.nc';

output_directory = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/output';
output_fname = 'test_animation.avi';

start_time = datetime('2002-06-26 00:00:00');
% end_time = datetime('2004-09-30 00:00:00');
end_time = datetime('2002-07-26 00:00:00');

npoints = 400; % track memory
frame_rate = 14;


latmin = 54.5;
latmax = 55.5;
lonmin = -122.5;
lonmax = -121.5;
track_data = read_downloaded_data(trackfile);

output_file = fullfile(output_directory, output_fname);

animate_gridded_ndvi(track_data, modisncfile, '_500m_16_days_NDVI', ...
    start_time=start_time, end_time=end_time, track_memory=npoints, ...
    output_file = output_file, frame_rate=frame_rate, latmin=latmin, ...
    latmax = latmax, lonmin=lonmin, lonmax=lonmax)