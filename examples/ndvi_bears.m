%% options
trackfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT-ENR_Laval University Black Bear Monitoring.csv';
ncfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/NDVI_bears_daily.nc';
shapefile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT_bear_roads.shp/GNWT_bear_roads.shp';
rasterfile = '/Users/jmissik/Desktop/repos.nosync/pymovebank/pymovebank/datasets/user_datasets/GNWT_local_lakes.tif';
labeled_pointsf = '/Users/jmissik/Desktop/Postdoc/Animal movement/GNWT_data/communities_location_labels.csv';

output_directory = '/Users/jmissik/Desktop/repos.nosync/movebank_vis/output/bears_short';

start_time = datetime('2022-04-01 00:00:00');
end_time = datetime('2022-10-10 00:00:00');

raster_color = [0.1294    0.6745    0.8706]; %light blue

npoints = 500; % track memory
frame_rate = 14;


latmin = 60.7;
latmax = 63.7;
lonmin = -118;
lonmax = -113.7;
track_data = read_downloaded_data(trackfile);


animate_gridded_ndvi(track_data, ncfile, '_500_m_16_days_EVI', shapefile = shapefile, raster_image=rasterfile, ...
    raster_cmap = raster_color, labeled_pointsf=labeled_pointsf, ...
    start_time=start_time, end_time=end_time, track_memory=npoints, ...
    output_directory = output_directory, frame_rate=frame_rate, latmin=latmin, ...
    latmax = latmax, lonmin=lonmin, lonmax=lonmax, cmap='green', invert_cmap=1, save_frames=true)