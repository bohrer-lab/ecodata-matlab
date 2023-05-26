# Inputs and settings

After opening the program, you will see a main window with six tabs, each containing settings for different input data. Settings and instructions for each tab are provided below. Selections shown in the screenshots below can be used to reproduce the [example animation](https://www.movebank.org/cms/movebank-content/ecodata#example_ecodata_animation) illustrating moose movements from the study [Peters Hebblewhite Alberta-BC Moose](https://www.movebank.org/cms/webapp?gwt_fragment=page=studies,path=study178994931).  

![app_gui](images/app_screenshot.png)

```{Tip}
You can use [custom colors](custom-colors) in addition to the default values included in many of the dropdown menus.  

Read our [general notes](general-notes) for advice about using the interface, saving and reloading settings, and iteratively building your animation to optimize your layer and design choices with minimal processing time.
```

You can flexibly prepare and test animations within the program. Here is an example of steps to creating an animation:  
1. Use the tabs at the top of the application to define the contents of the animation. You can work on the tabs in any order.
- [Animal track data](animal-track-data): Include animal tracking data (required)
- [Tracks visualization options](track-visualization-options): Define how to display track points and trajectories (required)
- [Environmental data](environmental-data): Include raster background layers (optional)
- [Shapefiles](shapefiles): Include additional shapefile layers (optional)
- [Labeled points](labeled-points): Include a labels layer (optional)
- [Elevation](elevation): Include elevation contours (optional)

2. Create a folder in which to save the results (a large number of .png files).
3. Click "Set output file" to specify the folder location. 

```{Tip}
The file browser window is sometimes hidden behind other windows. Click on the ECODATA_Animate icon from the Dock (on Mac) or close other windows to find it.
```

4. After providing input data and configurations, click "Create animation". If you have many input files, you may want to add one input at a time, generate a single frame to ensure it displays as expected, and then proceed with the next input [read more](general-notes).
5. Watch "Status" in the lower right to monitor progress. It may take a minute before a message appears. It should say *"Generating animation… Please be patient"*. Do not shut down your computer, move or rename the folder, or change settings, while this step is in progress. As frames are created, they will be saved in the specified folder, where you can review them to monitor the results and progress.
6. After processing is complete, you will see the message "Animation saved to the output directory". If the processing fails, error messages will be posted here. You can search for and report errors or unexpected results [here](https://github.com/jemissik/movebank_vis/issues).

![animation_saved](images/ecodata-animate_saved.png)

7. The results consist of a set of .png image files representing each frame for the animation, based on the chosen configuration, which can be viewed and used individually.
8. Use the [ECODATA-Prepare Movie Maker App](https://ecodata-apps.readthedocs.io/en/latest/user_guide/movie_maker.html) to compile these images into an animation.

(animal-track-data)=
## Animal track data

![animalTrackData](images/ecodata-animate_animalTrackData_PetersHebblewhite_moose_annot.png)

Here you upload a file of animal tracking data to animate. This should follow the format used when [accessing data from Movebank](https://www.movebank.org/cms/movebank-content/access-data#download_data_in_movebank_format), following formats described in the [Movebank Attribute Dictionary](https://www.movebank.org/cms/movebank-content/movebank-attribute-dictionary). This file should contain at least the attributes ``[timestamp](http://vocab.nerc.ac.uk/collection/MVB/current/MVB000200/)``, ``[location-long](http://vocab.nerc.ac.uk/collection/MVB/current/MVB000146/)``, ``[location-lat](http://vocab.nerc.ac.uk/collection/MVB/current/MVB000145/)`` and ``[individual-local-identifier](http://vocab.nerc.ac.uk/collection/MVB/current/MVB000016/)``. It can be composed of tracking data subsets or combinations from multiple Movebank studies, as well as additional columns of your choice, which can include environmental covariates from [Env-DATA](https://www.movebank.org/cms/movebank-content/env-data), results and annotations from [MoveApps](https://www.moveapps.org/), or [reference data](https://www.movebank.org/cms/movebank-content/mb-data-model#reference_data) attributes from the Movebank study.

1. Click on ``Select track data``. Browse to the .csv file containing your tracking data.
2. After the file is loaded, the filepath will be displayed, and the time range and geographic extent will be automatically populated based on the contents of the file.
3. Optionally, update the selected individuals, time range, or geographic extent as needed to refine what to include in the animation. Select ``Update filters`` to save your selections and calculate a summary of the contents of the filtered dataset.

(track-visualization-options)=
## Track visualization options

![tracksVisualizationOptions](images/ecodata-animate_tracksVisualizationOptions_PetersHebblewhite_moose_annot.png)

Here you define how the tracking data will be displayed in the animation, as well as the time period represented by each frame (in ``Track frequency``).

- Use the options on the left to define the design of the markers used to show the animals on the map. You can color the tracks by any attribute of the data (by default, the individual_local_identifier, or animal ID, is used).
- Use ``Track frequency`` to define the number of hours to represent in each frame of the animation. The track data are always resampled to this frequency for animation. For example, if it is set to 24 hours, the animation will generate one frame per day. Consider the sampling frequency in your tracking and environmental data, the length of time being animated, and how long you want the animation to be.
- Use ``Track memory`` to define the length of time to continue to show the movement trail, in terms of the track frequency. For example, if the track frequency is set to 24 (hours) and the track memory is set to 20, then a trail of the previous 20 days will be shown.
- Use ``Track opacity`` to define the transparency of the trail, with 0 being fully transparent and 1 being fully opaque.
- If the ``Fade tracks`` button is checked, the ``Track opacity`` setting is ignored and instead the trail will fade out with a "comet" effect.
- To choose your own track color/s, check the ``Use custom colors`` box and click on ``Add color``. You can select from a default palette or define colors using RGB, hexadecimal or HSV codes.

![standard_color_picker](images/ecodata-animate_colorpicker_standard.png)    ![custom_color_picker](images/ecodata-animate_colorpicker_custom.png)

(environmental-data)=
## Environmental data

![environmentalData_grid](images/ecodata-animate_environmentalData_grid_PetersHebblewhite_moose_annot.png)

Here you can optionally select dynamic up to three raster files in NetCDF-4 format to use as background layers for the animation. There are three environmental layers that can be (optionally):
- Gridded colormap
- Contours
- Vector fields (e.g., for wind)

There is a separate tab under the ``Environmental data`` tab for each of these layers.
You can request a variety of environmental raster data using NASA's [AppEEARS](https://ecodata-apps.readthedocs.io/en/latest/user_guide/tracks_explorer.html#requesting-environmental-data-from-nasa) service. While the program is designed to handle very large files, for more efficient processing and storage, use raster data only at the resolution needed for the animation. Files can be preprocessed to an appropriate resolution and masked using polygons with the ECODATA-Prepare [Gridded Data Explorer App](https://ecodata-apps.readthedocs.io/en/latest/user_guide/gridded_data_explorer.html).

### Gridded colormap

1. Click on ``Select gridded data`` and browse to a NetCDF (.nc) file containing raster environmental data to use as a color map in the background of the animation.
1. The app will attempt to populate the variables that define the time, location coordinates, and the variable to display in the animation. Review the results and click the dropdown boxes to update if needed.
1. Choose a color map. Current options are green, blue, diverging, and [jet](https://www.mathworks.com/help/matlab/ref/jet.html). By default, "green" will display lower values in darker colors. Check ``Invert color map`` to reverse this scale (for example, to show higher NDVI or EVI values in darker green).

### Contours

1. Click on ``Select contour data`` and browse to a .nc file containing raster environmental data to display data from a raster file as contour lines in the background of the animation.
1. The app will attempt to populate the variables that define the time, location coordinates, and the variable to display in the animation. Review the results and click the dropdown boxes to update if needed.
1. Choose a color and width for the contour lines, and check the box next to ``Show contour text`` to display labels.

### Vector fields

1. Click on ``Select vector field data`` and browse to a NetCDF (.nc) file containing raster environmental data to use for vector fields in the animation.
1. The app will attempt to populate the variables that define the time, location coordinates, and the variables to display in the animation. For vector fields, the dataset needs to include variables for the U and V components of the vectors. Review the results and click the dropdown boxes to update if needed.
1. Edit additional quiver style options.

Note that if your quiver dataset is too dense, it will need to be thinned using the ECODATA-Prepare [Gridded Data Explorer App](https://ecodata-apps.readthedocs.io/en/latest/user_guide/gridded_data_explorer.html).

(shapefiles)=
## Shapefiles

![shapefiles](images/ecodata-animate_shapefiles_PetersHebblewhite_moose_annot.png)

Here you can optionally select shapefiles to display in your animation frames. These layers will appear beneath the animal tracks and above the environmental (raster) data layers. Note that these layers will be drawn in the order that they are entered (i.e., the first layer in the list will be drawn first, so it will be on the bottom).

1. Click on an ``Select shapefile`` button and browse to a shapefile containing a vector data layer to display in the animation.
2. Available display properties will depend on the type of vector layer:
- Polygons: Select a color for polygon outlines (``Edge color``) and fill (``Face color``), and define the fill transparency (``Face opacity``, 1 = fully opaque).
- Lines: Select a line color and width.
- Points: Select a color, marker style, and marker size.

3. Repeat steps 1 and 2 to add additional shapefile layers, if desired.
4. If you want to remove shapefiles you have entered, you can click ``Clear all shapefiles`` to remove all of them, or ``Clear last shapefile`` to clear just the last one that was entered.

```{Important}
The app will not be able to render shapefiles that are too large and/or have too many features. Files should be clipped to the area of interest using [ECODATA-Prepare's Subsetter app](https://ecodata-apps.readthedocs.io/en/latest/user_guide/subsetter.html) before using them for animations. Note that some shapefiles may still be too large even after clipping them. In this case, try find a lower-resolution version of the dataset, if possible.

A future version of the app will include an option to use shapefiles that have been converted to raster images (created by ECODATA-Prepare), as a workaround for this limitation.
```

(labeled-points)=
## Labeled points

![labels](images/ecodata-animate_labels.png)

Here you can optionally define arbitrary points and labels to display in the animation, for example to identify place names or times and locations of relevant events.

1. Prepare a .csv file containing labels and their placement on the map. This file can be prepared using a spreadsheet (e.g., Excel), **as long it is saved as a .csv file**.
Information to include is as follows (all coordinates in decimal deg):
    - ``longitude`` and ``latitude`` (required): coordinates for the location of interest, in decimal degrees, WGS84
    - ``label`` (required): the text to display
    - ``start_time`` and ``end_time`` (optional): can be used to restrict the display of the label to the specified range of dates, in format yyyy-mm-dd
    - ``label_longitude`` and ``label_latitude`` (optional): coordinates where the label text should be placed on the map (left edge of label if the point is to the left of the label, right edge if the point is to the right of the label). This option is used if the label placement needs adjustment.
    - ``horizontal_alignment`` (optional): "right" or "left", indicating the alignment of the point relative to the label (e.g., "left" means that the point will be aligned to the left of the label). Defaults to "left" if not otherwise specified.

    An example will look something like this (this example is displayed in table format for easier reading, but **note that the file must be saved in .csv format**):

    | longitude 	| latitude 	| label        	| start_time 	| end_time   	| label_longitude 	| label_latitude 	| horizontal_alignment 	|
    |-----------	|----------	|--------------	|------------	|------------	|-----------------	|----------------	|----------------------	|
    | -123      	| 56       	| Test point 1 	| 2015-07-20 	| 2015-07-30 	| -123.1          	| 56.1           	|                      	|
    | -121.5    	| 54.5     	| Test point 2 	|            	|            	|                 	|                	| right                	|

    In .csv format:
    ```
    longitude,latitude,label,start_time,end_time,label_longitude,label_latitude,horizontal_alignment
    -123,56,Test point 1,2015-07-20,2015-07-30,-123.1,56.1,
    -121.5,54.5,Test point 2,,,,,right
    ```

    Note that only the ``longitude``, ``latutude``, and ``label`` columns are required, and rows can also be left empty in the optional columns.


2. Click on ``Select file`` and browse to the .csv file with the label information.
3. Adjust the marker color and size as desired.

(elevation)=
## Elevation

![animate_elevation](images/ecodata-animate_elevation_PetersHebblewhite_moose_annot.png)

Here you can optionally select to display elevation contours, based on the [ETOPO1 1-Arc-Minute Global Relief Model](https://doi.org/10.7289/V5C8276M).

1. Check ``Include elevation contours`` to draw these on the map.
2. If selected, review or update the number of levels and line design to use, and choose whether or not to display labels on the contour lines.
