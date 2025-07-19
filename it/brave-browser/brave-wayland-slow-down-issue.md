


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
