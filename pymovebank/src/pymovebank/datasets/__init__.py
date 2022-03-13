"""
Datasets for pymovebank
"""

import os
from pathlib import Path
import wget
from zipfile import ZipFile

__all__ = ["available", "get_path", "install_roads_dataset" ]

_module_path = Path(__file__).parent

_large_datasets_paths = [f for f in (_module_path / 'large_datasets').iterdir()
                   if not (str(f.name).startswith(".") or str(f.name).startswith("__"))]
_large_datasets_names = [f.name for f in _large_datasets_paths ]
_small_datasets_paths = [f for f in (_module_path / 'small_datasets').iterdir()
                   if not (str(f.name).startswith(".") or str(f.name).startswith("__"))]
_small_datasets_names = [f.name for f in _small_datasets_paths ]
_dict_available = dict(zip(_large_datasets_names, _large_datasets_paths)) | \
            dict(zip(_small_datasets_names, _small_datasets_paths))
available = list(_dict_available.keys())


def get_path(dataset):
    """
    Get the path to the test datasets in pymovebank.datasets.

    Parameters
    ----------
    dataset : str
        The name of the dataset. See ``pymovebank.data.available`` for
        all options.
    """
    if dataset in available:
        return str(_dict_available[dataset])
    else:
        msg = "The dataset '{data}' is not available. ".format(data=dataset)
        msg += "Available datasets are {}".format(", ".join(available))
        raise ValueError(msg)

def install_roads_dataset():
    """
    Install the Region 1 (North America) GRIP roads dataset in shapefile format.

    References
    ----------
    Meijer, J.R., Huijbegts, M.A.J., Schotten, C.G.J. and Schipper, A.M. (2018):
    Global patterns of current and future road infrastructure. Environmental Research
    Letters, 13-064006. Data is available at www.globio.info

    .. todo::
        - Add option to download the global dataset in gdb format instead
    """

    print("Installing North America roads dataset. It's a large download and "
          "will take a few mintues...")

    roads_url = 'https://dataportaal.pbl.nl/downloads/GRIP4/GRIP4_Region1_vector_shp.zip'
    install_path = Path(_module_path) / 'large_datasets'
    install_path.mkdir(exist_ok=True)
    filename = wget.download(roads_url, out=str(install_path))

    filepath = install_path / Path(filename)
    print("Installed dataset at: " + str(filepath))
    with ZipFile(str(filepath), 'r') as zipObj:
        zipObj.extractall(str(install_path / Path(filename).stem))
    os.remove(filepath)
