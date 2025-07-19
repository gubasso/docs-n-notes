
```
/e/profile.d> cat 10-nvidia-gbm.sh
#!/bin/sh
export GBM_BACKEND=nvidia-drm

/e/profile.d> cat 11-nvidia-vaapi.sh
#!/bin/sh
export LIBVA_DRIVER_NAME=nvidia
export VDPAU_DRIVER=nvidia
```

## GBM and VA-API settings

### GBM

chmod +x /etc/profile.d/10-nvidia-gbm.sh

```sh
#!/bin/sh
export GBM_BACKEND=nvidia-drm
```

### VA-API

- nvidia-vaapi-driver is installed
chmod +x /etc/profile.d/11-nvidia-vaapi.sh
```sh
#!/bin/sh
export LIBVA_DRIVER_NAME=nvidia
export VDPAU_DRIVER=nvidia        # optional, legacy API
```

### Explanation

The short version: your RTX 3000 Ada card will already expose the NVIDIA GBM backend and the VA-API wrapper as soon as the proprietary driver is loaded, so neither export is *strictly* mandatory.  In practice, though, keeping the two little shell-scripts does no harm, prevents corner-case breakage in some apps, and does **nothing** to GPU clocking or battery life.  Feel free to leave them in place unless you hit one of the known quirks listed below.

---

#### 1  What the two variables do

| Variable                                                 | Scope              | Effect                                                                                                                                                                        | Typical need today                                                                                                                                             |
| -------------------------------------------------------- | ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`GBM_BACKEND=nvidia-drm`**                             | Wayland/GBM loader | Forces Mesa’s GBM loader to pick NVIDIA’s `nvidia-drm_gbm.so` backend even on odd hybrid or early-boot situations ([download.nvidia.com][1])                                  | Optional—modern drivers (≥ 525) auto-detect, but some compositors or hybrid laptops still benefit ([discuss.cachyos.org][2], [forums.developer.nvidia.com][3]) |
| **`LIBVA_DRIVER_NAME=nvidia`** (+ `VDPAU_DRIVER=nvidia`) | Video-decode libs  | Tells libva (and optionally VDPAU) to load the `nvidia-vaapi-driver` shim so Chromium, Firefox, etc. can use NVDEC/NVENC ([github.com][4], [discussion.fedoraproject.org][5]) | Still required because libva can’t yet guess the NVIDIA backend name ([bbs.archlinux.org][6])                                                                  |

---

#### 2  Is your RTX 3000 Ada “AD106GLM” different?

* **Kernel display path** – The card speaks the same DRM interface as every Ada‐Lovelace laptop GPU; the GBM backend that ships with driver 535+ is identical. No extra flags are needed for performance. ([forums.developer.nvidia.com][3])
* **Video codec path** – NVENC/NVDEC are fully supported; `nvidia-vaapi-driver` simply bridges VA-API calls to those engines. The `LIBVA_DRIVER_NAME` export is therefore *generic* for all current GeForce/RTX parts, including yours. ([ubuntuhandbook.org][7])

**Bottom line:** the variables are *not hardware-specific*; they are there to paper over software detection gaps.

---

#### 3  Impact on FPS, latency & battery

* The GBM override only selects which allocator library your Wayland compositor talks to; it does **not** touch clocks, render off-load, or frame pacing. Benchmarks show identical FPS with or without it, except in edge cases where apps mis-detect the backend and crash or stutter ([github.com][8], [forums.developer.nvidia.com][9]).
* The VA-API exports merely allow browsers/FFmpeg to push decode/encode work onto NVDEC/NVENC. Off-loading video lets the CPU idle and *can* save several watts during playback, extending battery life by a few percent ([pcworld.com][10]).
* Neither variable interferes with PowerMizer states, run-time PCIe D3cold, or PRIME off-loading, which are the real levers for battery savings.

---

#### 4  Known caveats & when to remove them

| Symptom                                                | Likely culprit                                       | Fix                                                                                                        |
| ------------------------------------------------------ | ---------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Firefox/GTK app crashes on start                       | Broken GBM mutex in certain 560 betas                | Unset `GBM_BACKEND` (let auto-detect) ([gist.github.com][11])                                              |
| Hyprland black-screens on hybrid laptops without a MUX | GBM forces dGPU when internal panel is wired to iGPU | Comment out `GBM_BACKEND` or set `WLR_DRM_DEVICES` instead ([github.com][12])                              |
| `vainfo` still says “no VA driver found”               | Env var not visible in service scope                 | Add the export to `/etc/environment` or your launcher rather than `profile.d` ([forums.linuxmint.com][13]) |

If none of those affect you, leaving the scripts executable is perfectly safe.

---

#### 5  Recommended setup on Void + Niri

1. **Keep both scripts for now**

   ```sh
   # /etc/profile.d/10-nvidia-gbm.sh
   export GBM_BACKEND=nvidia-drm

   # /etc/profile.d/11-nvidia-vaapi.sh
   export LIBVA_DRIVER_NAME=nvidia
   export VDPAU_DRIVER=nvidia   # optional legacy layer
   ```
2. Verify they work:

   ```bash
   loginctl show-session $XDG_SESSION_ID -p Type
   journalctl -b 0 --grep "Using GBM"
   vainfo | grep -i nvidia
   ```

   You should see GBM reporting `nvidia-drm` and VA-API listing NVDEC codecs.
3. Fine-tune power with the usual NVIDIA knobs (PowerMizer “Adaptive”, `nvidia-powerd`, PRIME render off-load). The exports do not conflict with any of these.

---

#### 6  Conclusion

* **Not strictly necessary** but **harmless insurance**: the exports guarantee that every layer (Wayland compositor, VA-API apps) picks the right NVIDIA backends on first boot.
* They **do not influence** GPU clocks, AC performance, or battery drain—actual gains come from NVDEC off-loading and your existing runtime-PM setup.
* Leave them enabled unless they cause one of the documented corner-case issues; if so, drop only the offending variable.

Follow these guidelines and your Void + Wayland + Niri stack will keep the Ada GPU fast on mains power and thrifty on battery.

[1]: https://download.nvidia.com/XFree86/Linux-x86_64/515.65.01/README/gbm.html?utm_source=chatgpt.com "Chapter 40. GBM and GBM-based Wayland Compositors - Nvidia"
[2]: https://discuss.cachyos.org/t/cant-get-gdm-to-show-wayland-session-upon-login/7671?utm_source=chatgpt.com "Can't get GDM to show Wayland session upon login"
[3]: https://forums.developer.nvidia.com/t/debian-testing-535-104-wayland-blackscreen/269668?utm_source=chatgpt.com "Debian testing +535.104+wayland--> blackscreen - Linux - NVIDIA ..."
[4]: https://github.com/elFarto/nvidia-vaapi-driver/blob/master/README.md?utm_source=chatgpt.com "nvidia-vaapi-driver/README.md at master - GitHub"
[5]: https://discussion.fedoraproject.org/t/aleasto-nvidia-vaapi-driver/36182?utm_source=chatgpt.com "aleasto/nvidia-vaapi-driver - Fedora Discussion"
[6]: https://bbs.archlinux.org/viewtopic.php?id=294879&utm_source=chatgpt.com "No nvidia .so driver in /usr/lib/dri when needed to enable VA-API ..."
[7]: https://ubuntuhandbook.org/index.php/2024/01/firefox-vaapi-nvidia/?utm_source=chatgpt.com "Get Firefox VA-API Hardware Acceleration working on NVIDIA GPU"
[8]: https://github.com/hyprwm/Hyprland/issues/1878?utm_source=chatgpt.com "Nvidia update caused GBM_BACKEND=nvidia-drm to not work"
[9]: https://forums.developer.nvidia.com/t/gbm-does-not-work-with-hyprland-sway-games-have-fps-drops-below-30-every-few-mins/271268?utm_source=chatgpt.com "GBM does not work with Hyprland/Sway, games have FPS drops below 30 ..."
[10]: https://www.pcworld.com/article/2550326/how-gpu-hardware-acceleration-works-with-linux.html "How GPU hardware acceleration works with Linux | PCWorld"
[11]: https://gist.github.com/kRHYME7/1d2574e8f3a4b7ad4059535503ce1eaa?utm_source=chatgpt.com "Hyprland Environment Variables for NVIDIA and Intel Setups"
[12]: https://github.com/hyprwm/Hyprland/issues/9113?utm_source=chatgpt.com "Black screen when setting env = AQ_DRM_DEVICES,/dev/dri/card0:/dev/dri ..."
[13]: https://forums.linuxmint.com/viewtopic.php?t=423716&utm_source=chatgpt.com "[SOLVED] Firefox Video Acceleration, nvidia-vaapi-driver"
