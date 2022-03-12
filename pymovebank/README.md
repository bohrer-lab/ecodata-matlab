# pymovebank quickstart

## Functions
- :func:`~pymovebank.functions.grib2nc`: Converts .grib files from ECMWF to .nc format
- :func:`~pymovebank.functions.subset_data`: Subset shapefiles to areas of interest

### In progress:
- subset shapefiles to areas of interest

## Install python

Python and conda package manager: recommend to install anaconda or miniconda

See [directions for installing anaconda](https://docs.anaconda.com/anaconda/install/index.html)

See [directions for installing miniconda](https://docs.conda.io/en/latest/miniconda.html)

## Install required packages

To install the package dependencies in a new conda environment:

```
conda env create --file movebankenv.yml
```
Activate the conda environment:
```
conda activate movebankenv
```

- **Note**: It is not recommended to use ``pip`` to install required packages, since the dependencies might not be installed correctly. See [here](https://geopandas.org/en/stable/getting_started/install.html#installing-with-pip) for more info.

See [cheat sheet for working with conda](https://docs.conda.io/projects/conda/en/latest/_downloads/843d9e0198f2a193a3484886fa28163c/conda-cheatsheet.pdf)
