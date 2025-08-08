
On Arch linux: `~/.config/chromium-flags.conf`

Correct setup on Void Linux (only sources profile.d files):

```
/e/profile.d> cat chromium-flags.sh
#!/bin/sh
export CHROME_FLAGS="
--ozone-platform=wayland
--use-gl=egl
--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,\
VaapiVideoDecodeLinuxGL,AcceleratedVideoDecodeLinuxZeroCopyGL,\
VaapiIgnoreDriverChecks,VaapiOnNvidiaGPUs
--ignore-gpu-blacklist
--enable-zero-copy
--enable-parallel-downloading
--hide-crash-restore-bubble
"
```

## Summary

Many Chromium slowdowns on Wayland result from software compositing fallbacks due to missing GBM/DRM support, which forces the GPU process into CPU-bound rendering ([github.com][1]). Others stem from the “Preferred Ozone platform” flag defaulting to Auto or X11, causing compositor conflicts under native Wayland sessions on wlroots-based WMs like Niri ([bbs.archlinux.org][2]). Applying Ozone launch flags, disabling GPU driver workarounds, toggling vsync, ensuring up-to-date Mesa/VA-API packages, or—even temporarily—falling back to X11 can restore hardware acceleration and smooth scrolling ([wiki.archlinux.org][3], [issues.chromium.org][4]).

---

## Common Symptoms

### Laggy Scrolling and Stuttering

Users on wlroots compositors such as Niri WM report Chromium on Wayland feels laggy and choppy, with frame rates around 40–60 fps during scrolling—whereas Firefox remains fluid under identical conditions ([forum.manjaro.org][5]).

### WebGL Frame Drops

Certain WebGL-intensive sites exhibit very low rendering rates and high CPU usage, causing intermittent stuttering when moving windows or switching workspaces ([github.com][6]).

### Slow Launch Times

Under some Wayland sessions, opening a new Chromium window can be delayed by several seconds per instance, even when Ozone flags are supposedly enabled ([bbs.archlinux.org][7]).

---

## Underlying Causes

### Ozone Platform Fallback

By default, Chromium’s “Preferred Ozone platform” may be set to Auto or X11, forcing it into xWayland under native Wayland sessions and triggering compositor-level conflicts ([bbs.archlinux.org][2]).

### GPU Driver Fallbacks

Without proper libgbm, DRM render node access, or Wayland DMA-BUF protocols, Chromium’s GPU process can’t initialize hardware acceleration and falls back to software compositing, skyrocketing CPU usage ([github.com][1]).

### Compositor-Specific Quirks

Even with native Wayland enabled, driver or compositor bugs in wlroots-based environments can stall the GPU pipeline or introduce rendering glitches ([github.com][6]).

---

## Diagnostics

1. **Inspect `chrome://gpu`**

   * Check **Ozone platform** in the “Graphics Feature Status” section. If it reports `x11` instead of `wayland`, Chromium is running under xWayland ([forum.manjaro.org][5]).
   * Look for any “Software only” or “Disabled” entries under GPU rasterization or WebGL; these indicate fallback to CPU rendering ([github.com][6]).

2. **Verify Driver Availability**

   * Ensure that `/dev/dri/render*` nodes exist and that `libgbm`, `libdrm`, and Wayland EGL libraries are installed; missing components force software compositing ([github.com][1]).

---

## Recommended Fixes

### 1. Force Native Wayland with Ozone

Launch Chromium with the following flags to enable genuine Wayland support and bypass xWayland:

```bash
chromium \
  --enable-features=UseOzonePlatform \
  --ozone-platform=wayland
```

This explicitly sets the Ozone platform, ensuring Chromium talks directly to the Wayland compositor ([blogs.igalia.com][8], [bbs.archlinux.org][2]).

### 2. Toggle Hardware Acceleration

Disable GPU acceleration briefly to isolate driver issues:

```bash
chromium --disable-gpu
```

If disabling GPU removes stutters or freezes, re-enable it once you’ve updated drivers or applied other fixes ([groups.google.com][9]).

### 3. Ensure Mesa and GBM Packages

Install or update the Mesa stack, `libgbm`, `libdrm`, and `mesa-va-drivers` so Chromium can access the GPU render nodes directly, avoiding software fallbacks ([github.com][1]).

### 4. Disable GPU Driver Bug Workarounds

Some built-in workarounds can inadvertently degrade performance. Append:

```bash
--disable-gpu-driver-bug-workarounds
```

to your launch flags to disable these fallbacks ([issues.chromium.org][4]).

### 5. Disable GPU VSync

For persistent stutter related to vertical sync, disable vsync with:

```bash
--disable-gpu-vsync
```

This prevents blocking on VSync events and may smooth out animations ([docs.getquicker.cn][10]).

### 6. Fallback to X11 (Temporary)

If Wayland issues persist, force xWayland by using:

```bash
--ozone-platform=x11
```

or simply log into an X11 session. X11 mode avoids many Wayland-specific compositor bugs ([bbs.archlinux.org][2]).

### 7. Enable VA-API for Video Decoding

Offload video playback from the CPU by enabling VA-API:

```bash
--enable-features=VaapiVideoDecoding
```

and install the appropriate VA-API driver package. This reduces CPU load during video playback ([wiki.archlinux.org][3]).

---

## Example: Creating `chromium-flags.conf`

```bash
mkdir -p ~/.config
cat <<EOF > ~/.config/chromium-flags.conf
--enable-features=UseOzonePlatform
--ozone-platform=wayland
--disable-gpu-driver-bug-workarounds
--disable-gpu-vsync
EOF
```

Then launch Chromium normally (your WM config will pick up these flags automatically).

---

## Further Resources

* **ArchWiki: Chromium** – Up-to-date notes on VA-API, Wayland support, and related packages ([wiki.archlinux.org][3])
* **Peter Beverloo’s Switch List** – Comprehensive list of Chromium command-line flags ([peter.sh][11])
* **Chromium Issue Tracker** – Real-world reports of Ozone/Wayland bugs and workarounds ([github.com][1], [github.com][6])

[1]: https://github.com/OSSystems/meta-browser/issues/447?utm_source=chatgpt.com "chromium-ozone-wayland freezes when context menu's are destroyed ..."
[2]: https://bbs.archlinux.org/viewtopic.php?id=294895&utm_source=chatgpt.com "Chromium odd behavior with Preferred Ozone Platform Flag / Applications ..."
[3]: https://wiki.archlinux.org/title/Chromium?utm_source=chatgpt.com "Chromium - ArchWiki"
[4]: https://issues.chromium.org/issues/40654256?utm_source=chatgpt.com "Add ability to disable all the GPU driver bug workarounds ... - Chromium"
[5]: https://forum.manjaro.org/t/chrome-doesnt-work-properly-on-wayland/74090?utm_source=chatgpt.com "Chrome doesnt work properly on Wayland - Manjaro Linux Forum"
[6]: https://github.com/hyprwm/Hyprland/issues/9320?utm_source=chatgpt.com "Chromium WebGL wayland performance issue #9320 - GitHub"
[7]: https://bbs.archlinux.org/viewtopic.php?id=298567&utm_source=chatgpt.com "Chrome starts very slowly on Wayland / AUR Issues, Discussion ..."
[8]: https://blogs.igalia.com/msisov/chrome-on-wayland-waylandification-project/?utm_source=chatgpt.com "Chrome/Chromium on Wayland: The Waylandification project"
[9]: https://groups.google.com/a/chromium.org/g/chromium-discuss/c/IIQeveVRLVE?utm_source=chatgpt.com "The GPU process still runs with --disable-gpu - Google Groups"
[10]: https://docs.getquicker.cn/chrome/developer.chrome.com/developers/how-tos/run-chromium-with-flags.html?utm_source=chatgpt.com "Run Chromium with flags - The Chromium Projects"
[11]: https://peter.sh/experiments/chromium-command-line-switches/?utm_source=chatgpt.com "List of Chromium Command Line Switches « Peter Beverloo"

