# Welcome to ECODATA-Animate!

## Overview

ECODATA-Animate is a MATLAB® program for creating customized animated maps of animal movements. The program creates image frames that can be animated using the [ECODATA-Prepare Movie Maker App](https://ecodata-apps.readthedocs.io/en/latest/user_guide/movie_maker.html). Define track visualization options and include additional layers from raster files, shapefiles, an elevation model and label lists. See [ECODATA-Prepare](https://ecodata-apps.readthedocs.io/en/latest/index.html) for additional tools for preparing input data. Development is supported by MathWorks® and the NASA Earth Science Division, Ecological Forecasting Program, as part of the [Room to Roam: Y2Y Wildlife Movements](https://ceg.osu.edu/Y2Y_Room2Roam) project.

## Installation

[Download the installers here](https://github.com/jemissik/movebank_vis/releases)

## Getting started

Before using this program, prepare data to include in the animation. Inputs to ECODATA-Animate include the following:

- A file of movement track data in Movebank format (required) that can include additional columns.
- 1 or 2 static and/or dynamic raster files (maps) in NetCDF-4 format (optional). These can be used as background layers for the animation, with the possibility to display one layer as a colormap and the other with contour lines.
- Shapefiles with lines or polygons containing other vector data you want to display (optional). For example, you could use this to include water bodies, roads or property lines.
- A list of points to label on the map in .csv format (optional), with the option to restrict the display of the label to a range of dates.
- In addition, you can display elevation contours using a stored digital elevation model (DEM) that does not require a user file.

## Using the app

**Overview of steps**
1. Use the tabs at the top of the application to define the contents of the animation. You can work on the tabs in any order.
- [Animal track data](animal-track-data): Include animal tracking data (required)
- [Tracks visualization options](track-visualization-options): Define how to display track points and trajectories (required)
- [Environmental data](environmental-data): Include raster background layers (optional)
- [Shapefiles](shapefiles): Include additional shapefile layers (optional)
- [Labeled points](labeled-points): Include a labels layer (optional)
- [Elevation](elevation): Include elevation contours (optional)
 
2. Create a folder in which to save the results (a large number of .png files).  
3. Click "Set output file" to specify the folder location. The file browser window is sometimes hidden behind other windows.  
4. Click on the ECODATA_Animate icon from the Dock (on Mac) or close other windows to find it.  
5. After providing all input data and configurations, click "Create animation". 
6. Watch "Status" in the lower right to monitor progress. It may take a minute before a message appears. It should say *"Generating animation… Please be patient"*. Do not shut down your computer, move or rename the folder, or change settings, while this step is in progress. As frames are created, they will be saved in the specified folder.  
7. After processing is complete, you will see the message "Animation saved to the output directory". If the processing fails, error messages will be posted here. You can search for and report errors or unexpected results [here](https://github.com/jemissik/movebank_vis/issues).
8. The results consist of a set of .png image files representing each frame for the animation, based on the chosen configuration, which can be viewed or used individually. 
9. Use the [ECODATA-Prepare Movie Maker App](https://ecodata-apps.readthedocs.io/en/latest/user_guide/movie_maker.html) to compile these images into an animation.

**General notes** 
- Expect some trial and error as you define settings and see how they appear in the saved frames.
- To review results with minimal processing time, you can start by limiting the "time range" under "Animal track data", so that fewer frames are created. Once the settings are as desired, extend the time range to that of the full dataset for final processing. 
- It is not yet possible to save settings within the app, so we recommend noting chosen settings or taking screenshots as you go, in case you need to restart the application. 
- When clicking a button to select a filepath, the browse window might not automatically appear, and may be hidden behind other application windows or displayed on another monitor. Clicking on the application icon from the Dock may bring it to the front of your screen.  
![ecodata-animate_dock_icon](../images/ecodata-animate_dock_icon.png)
- After selecting a file or setting the output filepath, expect that it may take several seconds before the information loads or updates appear in the status window.  
- For help or to share suggestions, submit a GitHub issue or contact support@movebank.org.

## Links

- [GitHub repository](https://github.com/jemissik/movebank_vis)
- Check out the [overview page on Movebank's website](https://www.movebank.org/cms/movebank-content/ecodata)

## Contents

```{toctree}
---
maxdepth: 2
---
installation
user_guide