"""
Datasets for pymovebank
"""

import os
import shutil
from pathlib import Path

import requests
import wget
from datasize import DataSize

__all__ = ["available", "get_path", "install_roads_dataset"]

_module_path = Path(__file__).parent

_large_datasets_paths = [
    f
    for f in (_module_path / "large_datasets").iterdir()
    if not (
        str(f.name).startswith(".")
        or str(f.name).startswith("__")
        or str(f.name) == "temp_downloads"
    )
]
_large_datasets_names = [f.name for f in _large_datasets_paths]
_small_datasets_paths = [
    f
    for f in (_module_path / "small_datasets").iterdir()
    if not (str(f.name).startswith(".") or str(f.name).startswith("__"))
]
_small_datasets_names = [f.name for f in _small_datasets_paths]
_dict_available = dict(zip(_large_datasets_names, _large_datasets_paths)) | dict(
    zip(_small_datasets_names, _small_datasets_paths)
)
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
        path = _dict_available[dataset]
        if path.suffix == ".zip":
            path = "zip://" + str(path)
        else:
            path = str(path)
        return path
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

    # Remove any partially downloaded datasets
    _remove_temp_downloads()

    roads_url = (
        "https://dataportaal.pbl.nl/downloads/GRIP4/GRIP4_Region1_vector_shp.zip"
    )

    # Confirm user wants to proceed with download
    while True:
        # Get size of requested file
        filesize = requests.head(roads_url).headers["Content-Length"]
        print()
        response = input(
            "The download is {:.2GB}. Do you want to proceed? [y/n]".format(
                DataSize(filesize + "B")
            )
        )
        if response.lower() == "y":
            print(
                "Installing North America roads dataset. It's a large download and will take a few mintues..."
            )
            install_path = Path(_module_path) / "large_datasets"
            install_path.mkdir(exist_ok=True)

            # Run wget from temp downloads directory
            download_path = install_path / "temp_downloads"
            download_path.mkdir(exist_ok=True)
            os.chdir(download_path)
            try:
                filename = wget.download(roads_url, out=str(install_path))
                filepath = install_path / Path(filename)
                print("Installed dataset at: " + str(filepath))
            except BaseException as e:
                download_path = Path(_module_path) / "large_datasets/temp_downloads"
                shutil.rmtree(download_path)
                print(f"\nFailed to download dataset because of {e!r}")
            break
        elif response.lower() == "n":
            print("Download cancelled.")
            break
        else:
            print("Invalid answer. Please answer [y/n]")


def _remove_temp_downloads():
    """
    Delete any partially downloaded files from failed attempts to install datasets.
    """
    download_path = Path(_module_path) / "large_datasets/temp_downloads"
    if os.path.exists(download_path) and os.listdir(download_path):
        print("Found partially downloaded files in pymovebank.datasets.")
        while True:
            response = input(
                "Do you want to delete these files before you download a new dataset? [y/n]"
            )
            if response.lower() == "y":
                shutil.rmtree(download_path)
                print("Removed files.")
                break
            elif response.lower() == "n":
                break
            else:
                print("Invalid answer. Please answer [y/n]")