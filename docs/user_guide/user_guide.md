# Using the app

![app gui](images/app_screenshot.png)
## Track visualization options

- Track frequency: Sets the time frequency of the tracks that will be shown. The track data is always resampled to this frequency for animation. So if it is set to 24 hours the animation will generate one frame per day, if it is set to 1 hour the animation will give one frame per hour, etc.
- Track memory: Sets how long of a trail will be left for the tracks (and this number is in terms of the track frequency). So if the track frequency is set to 24 hours and the track memory is set to 20, then a trail of the previous 20 days will be shown.
- Track alpha is the transparency of the trail, with 0 being fully transparent and 1 being fully opaque. If the “Fade tracks” button is checked, this setting is ignored and instead the trail will fade out with a “comet” effect.