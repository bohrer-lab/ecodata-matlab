# Overview

See the [documentation pages](https://jemissik.github.io/movebank_vis/index.html)

# Setup instructions

## Adding datasets
- Most of the datasets are too large to be stored in the repository
- Datasets used in the example scripts can be downloaded [here](https://drive.google.com/drive/folders/1pyK4E-z8XUjRlYKYFX5L198YOlvOoUHA?usp=sharing)
- Copy any datasets you want to use to ``data/user_datasets``
## Adding topo data for the m_map package
- [Download the topo data](https://drive.google.com/drive/folders/1RmhHbSsm15i5xQVMWLaerv39fHja2fgr?usp=sharing)
- Copy the contents of this folder to ``m_map/data``
## Specifying Movebank login credentials:
- Save ``movebank_credentials_template.txt`` as ``movebank_credentials.txt`` and update it with your username and password.
- ``movebank_credentials.txt`` is in the .gitignore so it won't be tracked.

# Contributing
Check out this [simple guide for using git](https://rogerdudler.github.io/git-guide/).

1. Create a new branch for your contributions.
2. Commit your changes in this branch.
3. [Open a pull request](https://github.com/jemissik/pymovebank/pulls) to merge changes from your branch into the
repository's ``develop`` branch. 

# Functions available:

## Data access:
- ``import_from_movebank.m``: Import data directly from Movebank using the api.
- ``read_downloaded_data.m``: Reads in Movebank data that has already been saved locally.

## Visualizations:
- ``plot_annotated_track.m``: Static plot of track data, annotated with an environmental variable
- ``animate_track.m``: Basic animation of track data
- ``animate_track_annotated.m``: Animation of track data, annotated with an environmental variable

# Roadmap
## Next steps:

## Planned:
