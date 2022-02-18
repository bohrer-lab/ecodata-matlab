# Overview

[Documentation](https://jemissik.github.io/movebank_vis/index.html)

## Specifying Movebank login credentials:
- Save ``movebank_credentials_template.txt`` as ``movebank_credentials.txt`` and update it with your username and password.
- ``movebank_credentials.txt`` is in the .gitignore so it won't be tracked.

## Functions available:

### Data access:
- ``import_from_movebank.m``: Import data directly from Movebank using the api.
- ``read_downloaded_data.m``: Reads in Movebank data that has already been saved locally.

### Visualizations:
- ``plot_annotated_track.m``: Static plot of track data, annotated with an environmental variable
- ``animate_track.m``: Basic animation of track data
- ``animate_track_annotated.m``: Animation of track data, annotated with an environmental variable

## In progress/planned:
- Visualize & animate gridded environmental data products
- Add options to select data of interest
- Stream particle visualization
