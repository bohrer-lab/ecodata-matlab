""" Example of converting a .grib file to .nc """

from pymovebank.functions import grib2nc
from pathlib import Path

indir = Path(__file__).parent / 'data' / 'ECMWF_wind_NorthAmerica_April2008_grib'
filename = 'adaptor.mars.internal-1645552037.0943477-16128-3-1db44f8d-d429-4683-bfbe-60c9a573e160.grib'
filein = str(indir / filename)

outdir = Path(__file__).parent / 'output'
# make output directory if one doesn't exist
(outdir).mkdir(exist_ok=True)

fileout = str(outdir/ 'ECMWF_wind_NorthAmerica_April2008_grib.nc')

# make output directory if one doesn't exist
(outdir).mkdir(exist_ok=True)

# Convert the .grib file
grib2nc(filein, fileout)
