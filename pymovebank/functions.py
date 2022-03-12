
"""Python functions for data subsetting and file conversion.
See also the example scripts of how these are used."""

import xarray as xr

from shapely.geometry import Polygon
import geopandas as gpd
import pandas as pd


def grib2nc(filein, fileout):
    """
    Converts .grib files from ECMWF to .nc format.

    Parameters
    ----------
    filein : str
        .grib file to convert
    fileout : str
        Output filename where the .nc file will be written
    """

    # Read the .grib file using xarray and the cfgrib engine
    ds = xr.load_dataset(filein, engine = "cfgrib")

    # Write the dataset to a netcdf file
    ds.to_netcdf(fileout)

def subset_data(filename, bbox = None, track_points = None, bounding_geom = None,
               boundary_type = 'envelope', buffer = 0.1, clip = False,
               outfile = None):
    """
    Subsets a dataset to an area of interest.

    There are three subsetting options:
        - **Specify a bounding box**: Provide coordinates for a bounding box.
          (Use the ``bbox`` argument.)
        - **Provide animal track data**: Provide a csv file of Movebank animal
          track data, and a boundary will be drawn that encompasses all of the
          track points.(Use the ``track_points`` argument).
        - **Provide another shapefile for subsetting**: A boundary will be drawn
          around the features in this shapefile. For example, you could a provide
          a shapefile with a bounding polygon for a region of interest. (Use the
          ``bounding_geom`` argument)


    If using ``track_points`` or ``bounding_geom``, you can also specify:
        - Whether the bounding shape should be rectangular or a convex hull (Use
          the ``boundary_type`` argument.)
        - A buffer size around the track points or shape of interest (Use the
          ``buffer`` argument.)


    The newly subsetted shapefile is returned as a GeoDataFrame, and is optionally
    written out to a new shapefile.

    Parameters
    ----------
    filename : str
        Path to data file to subset
    bbox : list or tuple, optional
        Bounding box coordinates for the subset. Should be specified in the format
        ``(long_min, lat_min, long_max, lat_max)``.
    track_points : str, optional
        Path to csv file with animal track points. Latitude and longitude must be
        labeled as "location-lat" and "location-long".
    bounding_geom : str, optional
        Path to shapefile with bounding geometry.
    boundary_type : str, optional
        Specifies whether the bounding shape should be rectangular (``boundary_type=
        'envelope'``)
        or convex hull(``boundary_type = 'convex_hull'``), by default 'envelope'
    buffer : float, optional
        Buffer size, by default 0.1
    clip : bool, optional
        Whether or not to clip the subsetted data to the specified boundary (i.e., cut off
        intersected features at the boundary edge). By default False.
    outfile : str, optional
        Path to write the subsetted .shp file, if specified. If no path is specified, the
        subsetted data won't be written out to a file.

    Returns
    -------
    geopandas GeoDataFrame
        GeoDataFrame with the subsetted data
    geopandas GeoDataFrame
        GeoDataFrame with the bounding geometry


    .. todo::
        - Add option to subset from an exact boundary, rather than a convex hull
        - Add examples section
    """

    # Check that one and only one of the subsetting options was specified
    assert sum([item is not None for item in [bbox, track_points, bounding_geom]]) == 1, (
        "subset_data: Must specify one and only one of the subsetting options bbox, \
            track_points, or bounding_shp ")

    # Subset for bbox case
    if bbox is not None:
        gdf = gpd.read_file(filename, bbox = bbox)

    # Subset for track_points and bounding_geom case
    else:

        # Get feature geometry for track_points case
        track_crs = "EPSG:4326"
        if track_points is not None:
            df = pd.read_csv(track_points)
            gdf_track = gpd.GeoDataFrame(df,
                        geometry=gpd.points_from_xy(df['location-long'], df['location-lat']),
                        crs = track_crs)
            feature_geom = gdf_track.dissolve() # Dissolve points to a single geometry

        # Get feature geometry for bounding_geom case
        elif bounding_geom is not None:
            # Read shapefile
            gdf_features = gpd.read_file(bounding_geom)
            feature_geom = gdf_features.dissolve() # Dissolve features to one geometry

        # Get boundary for envelope or convex hull
        if boundary_type == 'envelope':
            boundary = feature_geom.geometry.envelope
        elif boundary_type == 'convex_hull':
            boundary = feature_geom.geometry.convex_hull

        # Adjust boundary with the buffer
        tot_bounds = boundary.geometry.total_bounds
        buffer_scale = max([tot_bounds[2] - tot_bounds[0], tot_bounds[3] - tot_bounds[1]])
        boundary = boundary.buffer(buffer * buffer_scale)

        # Read and subset
        if boundary_type == 'envelope':
            gdf = gpd.read_file(filename, bbox = boundary)
        elif boundary_type == 'convex_hull':
            gdf = gpd.read_file(filename, mask = boundary)

        if clip:
            gdf = gdf.clip(boundary.to_crs(gdf.crs))

    # Write new data to file if output path was specified
    if outfile is not None:
        gdf.to_file(outfile)

    return gdf, boundary
