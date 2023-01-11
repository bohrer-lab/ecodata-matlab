# Overview


ECODATA-Animate is a MATLAB® program for creating animated maps of animal movements along with additional layers.

Inputs to ECODATA-Animate include:

- A file of movement track data in Movebank format (required). This can include additional columns such as environmental covariates annotated by Env-DATA or reference data attributes, and can include tracking data combined from multiple Movebank studies.

- 1-2 static and/or dynamic rasters (maps) in NETCDF-4 format (optional). One will be displayed as a colormap, the other with contour lines.

- GIS shapefiles, lines or polygons (optional).

- Lists of points to label on the map in .csv format (optional). Files must contain columns "longitude", "latitude" and "label" to indicate where each label's method and placement on the map, using coordinates in decimal degrees, WGS84 coordinate reference system. If present, the additional columns "start_time" and "end_time" can be used to restrict the display of the label to a range of dates.

- In addition, ECODATA-Animate allows you to include elevation contours using the default mapping database (optional), which does not require input of DEM data.

## Links

See the [documentation pages](https://ecodata-animate.readthedocs.io/en/latest/)

[GitHub repository](https://github.com/jemissik/movebank_vis)


Check out the [overview page on Movebank's website](https://www.movebank.org/cms/movebank-content/ecodata)