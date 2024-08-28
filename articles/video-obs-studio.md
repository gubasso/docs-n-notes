# Video: OBS Studio

[Top 10 OBS Plugins Of All Time (2024) - nutty](https://www.youtube.com/watch?v=kO8VJuIzCJA)

## Optimize recording

- [How to: Gstreamer VA-API OBS Debian Flatpak, under 6min - LoftyPancake](https://www.youtube.com/watch?v=Xpi0uo3UAFQ)
  - vaapi
  - settings > output > output mode: advanced
  - video enconder: Gstreamer
  - enconder type: VA-API

- [Best OBS Settings for Recording 2024 - NO LAG - SlurpTech](https://www.youtube.com/watch?v=0eITm_XGELg)
- [BEST OBS Recording Settings For LOW END PC 2024 (NO LAG) - Agent](https://www.youtube.com/watch?v=b0LtsJY9NNI)

## [Make Any Mic Sound Expensive In OBS | Mic Settings & Filters (2023) - The Video Nerd](https://www.youtube.com/watch?v=G1VzeT9t24Y)

- max obs mic volume
- adjust the system volume so when talk normally, chart at yellow range (mic audio track)
- audiomixer, advanced audio properties > audio monitoring > monitor and output (hear your own microphone)
- add filters

1) if max system vol + max obs vol is less than yellow range, add "gain" filter
2) noise supression: speex
3) 3-band equalizer
  - reduce mid a little bit (more professional)
  - maybe add a little to high
  - final adjust to the high
  - enable/disable to compare the raw and adjusted
4) expander
  - ratio: 3
  - attack: 1ms
  - release: 100ms
  - threshold: all to left
  - now talk as quiet as possible (as it would be your minimum vol)
  - observe the audio mixer: adjust "output gain" to the yellow mark
  - go back to threshold:
    - find a low spot where the sound will activate
5) compressor
  - ratio: 3
  - threshold: all to right
  - attack: 1ms
  - release: 100ms
  - shout: reduce the "threshold" until the shout doesn't peek anymore
    - aim shout to go to -1db
6) limiter
  - threshold: all to right + one click to at bottom arrow (-0.1db)

- [Create a Virtual Microphone on Linux with Pulseaudio for Obs Studio - NapoleonWils0n](https://www.youtube.com/watch?v=Goeucg7A9qE)
  - settings > audio
  - advanced: monitoring device > (choose the virtual cable)
  - make sure mic output is set to "monitor and output"
  - at other program, choose the virtual mic as input

## [ANIMATED Masks Using Nothing But OBS Studio! - nutty](https://www.youtube.com/watch?v=btzlExdrsg4)

> https://obsproject.com/forum/resources/advanced-masks.1856/

- camera source > filters
- advanced masks

## Plugin: Stroke Glow Shadow 1.0.2

> [DROP SHADOWS Using Only OBS Studio! (Also Outlines & Glows) - nutty](https://www.youtube.com/watch?v=dsVQ_LnUQNM)
> https://obsproject.com/forum/resources/stroke-glow-shadow.1800/

- camera source > filters
- stroke/shadow/glow
- blur type: dual kawase
- stroke
  - outlines

- do not use alt+change size to resize camera (it will cut the shadow)
  - to change the camera size, use crop/pad filter
  - add to the top (first)
  - positive numbers will crop the borders
- if using mask filter: need to be before the shadow
- if shadow doesn't show:
  - add a Crop/Pad filter
  - add negative values to left/top/right/bottom (like padding)
  - drag this filter above the shadow filter

## [How to Make Circle Webcam in OBS Studio - Northern Viking Everyday](https://www.youtube.com/watch?v=LgrDeVKXQII)

- new scene > "cam-circle-scene"
- source > add source > video capture device web cam
- "cam-circle-scene" > filters > effect filter + > Image mask/blend > browse "circle-mask.png"
- resize
- source square > lock button
- go to the main scene > sources + > scene > "cam-circle-scene"


## Manual plugins installation

> https://wiki.archlinux.org/title/Open_Broadcaster_Software#Encoding_using_GStreamer

You can manually install plugin to the ~/.config/obs-studio/plugins/. The folder structure is the following:

```
~/.config/obs-studio/plugins/plugin_name/bin/64-bit/plugin_name.so
~/.config/obs-studio/plugins/plugin_name/data/locale/en-US.ini
```

