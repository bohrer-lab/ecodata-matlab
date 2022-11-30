%% options
trackfile = '/Users/jmissik/Desktop/Postdoc/Animal movement/GNWT_data/allcaribou_2017.csv';
ncfile = '/Users/jmissik/Desktop/Postdoc/Animal movement/GNWT_data/env/EVI_caribou/VNP13A1.001_500m_aid0001-2.nc';
shapefile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT_caribou_roads.shp/GNWT_caribou_roads.shp';
rasterfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT_local_lakes_caribou.tif';
labeled_points_file = '/Users/jmissik/Desktop/Postdoc/Animal movement/GNWT_data/communities_location_labels.csv';

output_directory = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/output/caribou_test';

start_time = datetime('2017-01-01 00:00:00');
end_time = datetime('2022-03-30 00:00:00');

raster_color = [0.1294    0.6745    0.8706]; %light blue
npoints = 500; % track memory
frame_rate = 14;


latmin = 61;
latmax = 64;
lonmin = -121.7;
lonmax = -113.7;
track_data = read_downloaded_data(trackfile);


animate_gridded_ndvi(track_data, ncfile, '_500_m_16_days_EVI', shapefile = shapefile, raster_image=rasterfile, ...
    raster_cmap = raster_color, labeled_pointsf=labeled_points_file, ...
    start_time=start_time, end_time=end_time, track_memory=npoints, ...
    output_directory = output_directory, frame_rate=frame_rate, latmin=latmin, ...
    latmax = latmax, lonmin=lonmin, lonmax=lonmax, cmap='green', invert_cmap=1, save_frames=true)