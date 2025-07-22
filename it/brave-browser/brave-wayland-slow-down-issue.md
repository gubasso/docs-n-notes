
On Arch linux:

Brave (community “brave” package) ships a `brave-launcher` that reads `$XDG_CONFIG_HOME/brave-flags.conf` (i.e. `~/.config/brave-flags.conf`). If you use the brave-bin AUR package, you’ll need to adopt a similar wrapper or adjust the .desktop entry yourself.

On Void Linux:

```
~/.config> cat brave-flags.conf
--ozone-platform=wayland
--enable-features=UseOzonePlatform,WaylandWindowDecorations
--enable-gpu-rasterization
--enable-zero-copy
--ignore-gpu-blocklist
--enable-parallel-downloading
--hide-crash-restore-bubble

## OPTIONAL – VA-API/NVDEC video decode
--use-gl=angle
# --use-angle=vulkan
--use-cmd-decoder=passthrough
--enable-features=VaapiVideoDecoder,VaapiVideoDecodeLinuxGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,UseMultiPlaneFormatForHardwareVideo,VaapiVideoEncoder

## Screen-sharing under Wayland
--enable-features=WebRTCPipeWireCapturer

## Extra perf / UI niceties
# --enable-features=Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,OzonePlatformAcceleratedUi,CanvasOopRasterization,UseDrainableVideoFramePool,UseSkiaRenderer
```
