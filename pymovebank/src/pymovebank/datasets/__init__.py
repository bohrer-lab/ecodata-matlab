"""
Test datasets for pymovebank
"""

from gettext import install
import os
from pathlib import Path
import wget

__all__ = ["available", "get_path"]

_module_path = os.path.dirname(__file__)
_available_dir = [p for p in next(os.walk(_module_path))[1] if not p.startswith("__")]
_available_zip = {}
available = _available_dir + list(_available_zip.keys())


def get_path(dataset):
    """
    Get the path to the test datasets in pymovebank.data.

    Parameters
    ----------
    dataset : str
        The name of the dataset. See ``pymovebank.data.available`` for
        all options.
    """
    if dataset in _available_dir:
        return os.path.abspath(os.path.join(_module_path, dataset, dataset + ".shp"))
    elif dataset in _available_zip:
        fpath = os.path.abspath(os.path.join(_module_path, _available_zip[dataset]))
        return "zip://" + fpath
    else:
        msg = "The dataset '{data}' is not available. ".format(data=dataset)
        msg += "Available datasets are {}".format(", ".join(available))
        raise ValueError(msg)

def install_roads_dataset():

    print("Installing North America roads dataset. It's a large download and "
          "will take a few mintues...")
    roads_url = 'https://dataportaal.pbl.nl/downloads/GRIP4/GRIP4_Region1_vector_shp.zip'
    install_path = Path(_module_path) / 'large_datasets'
    install_path.mkdir(exist_ok=True)
    wget.download(roads_url, out=str(install_path))
