% Wind animation - eagles 

% Files 
trackfile = '/Users/madelinescyphers/Documents/projs_.nosync/movebank_vis/data/user_datasets/HawkWatch International Golden Eagles.csv';
windfile = '/Users/madelinescyphers/Documents/projs_.nosync/movebank_vis/data/user_datasets/eagle_ds_2004_thinned2.nc';

% Output location
output_directory = '/Users/madelinescyphers/Documents/projs_.nosync/movebank_vis/output/animator_output/test2';


% Track data
track_memory = 20;

tracks = Tracks(trackfile, track_memory=track_memory, frequency=hours(1));

start_time = datetime('2004-05-15');
end_time = datetime('2004-05-20');

wind_data = Quivers(windfile, latvar='latitude', lonvar='longitude', timevar='time', ...
    u_var='u10', v_var='v10', quiver_lifespan=4, quiver_respawn_interval=4, ...
    quiver_speed=1, quiver_color='k');

animate_tracks(tracks, quiver_data=wind_data, start_time=start_time, end_time=end_time, output_directory=output_directory)


% [lat, lon, time, var] = unpack_netcdf(windfile, 'latitude', 'longitude', 'time', u_var = 'u10', v_var='v10')
