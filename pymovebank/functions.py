
"""Python functions for data subsetting and file conversion.
See also the example scripts of how to these are used."""

import xarray as xr

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