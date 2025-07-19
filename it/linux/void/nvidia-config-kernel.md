## TLDR

Option	Where to set	Benefit	Source
options nvidia-drm modeset=1 (or nvidia-drm.modeset=1 on the kernel cmdline)	/etc/modprobe.d/nvidia.conf	Enables DRM/KMS path required for GBM; on by default in >= 560 drivers but harmless to keep
https://github.com/hyprwm/hyprland-wiki/issues/968

Neither switch changes GPU clocks. Real performance (on AC) and power-saving (on battery) hinge on NVIDIA’s PowerMizer, PCIe runtime-PM and PRIME off-load, not on these two flags.


`/etc/modprobe.d/99‑nvidia.conf`
```
options nvidia-drm modeset=1 fbdev=1
```

`/etc/dracut.conf.d/nvidia.conf`
```
add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
install_items+=" /etc/modprobe.d/nvidia.conf "
```

```
dracut --regenerate-all --force
xbps-reconfigure -fa
```

test / check

```
cat /sys/module/nvidia_drm/parameters/modeset
cat /sys/module/nvidia_drm/parameters/fbdev
```


**Short answer up-front:**

* `nvidia-drm.modeset=1` (or the modprobe equivalent) **is still required** for any Wayland compositor on NVIDIA - including Niri and Hyprland – because it turns on the DRM/KMS “GBM path”.  With driver 560 the option is often **pre-enabled by the distro package**, but Void currently ships the upstream `.run` driver without that patch, so you should keep the line in `/etc/modprobe.d/99-nvidia.conf`; it has no measurable performance or battery-life penalty.
* `nvidia-drm.fbdev=1` only creates a simple framebuffer console and helps some suspend/hibernate paths; it is **optional** and occasionally unstable on laptops.  Test it; if you see a black screen or boot hang, drop the option.
  Neither switch changes GPU clocks.  Real performance (on AC) and power-saving (on battery) hinge on NVIDIA’s PowerMizer, PCIe runtime-PM and PRIME off-load, not on these two flags.

---

## 1  What the two kernel parameters actually do

| Parameter                  | What it unlocks                                                                                                                                                                     | Typical need on modern drivers                                               |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **`nvidia-drm.modeset=1`** | Registers the NVIDIA kernel module with the DRM subsystem and advertises MODESET capability, which Wayland/GBM clients require to present frames ([forums.developer.nvidia.com][1]) | Mandatory for Wayland; harmless on X11                                       |
| **`nvidia-drm.fbdev=1`**   | Exposes a fallback fbdev console driven by the NVIDIA module; fixes blank vt/suspend problems on some kernels ([forums.developer.nvidia.com][2])                                    | Experimental; default-enabled only in a few distro patches ([github.com][3]) |

---

## 2  Are they already enabled on your Void install?

1. Boot normally and run:

```bash
cat /sys/module/nvidia_drm/parameters/modeset   # Y means enabled
cat /sys/module/nvidia_drm/parameters/fbdev     # Y means enabled
```

2. On Arch and a few other distros the **560.35.03** packaging script flips both switches to “Y” automatically ([bbs.archlinux.org][4], [bbs.archlinux.org][4]).
3. **Void packages the upstream binary**, whose README still ships them **disabled by default** ([download.nvidia.com][5]), so you’ll almost certainly see `N`.

**Conclusion:** keep the file you showed:

```conf
# /etc/modprobe.d/99-nvidia.conf
options nvidia-drm modeset=1 fbdev=1
```

It is evaluated early by runit’s udev cold-plug, so no GRUB edits are needed.

---

## 3  Performance when plugged-in

* The flags only touch the kernel display path; they **do not alter clocks, VRAM timings or boost behaviour**, so FPS in e.g. `glmark2` or Vulkan titles remains unchanged ([support.exxactcorp.com][6]).
* Enabling DRM/KMS actually removes one copy operation in Wayland compositors and can cut a few ms of latency in games and video playback on Hyprland ([deepwiki.com][7]).

---

## 4  Battery-life considerations for the RTX 3000 Ada (AD106GLM)

| Technique                      | Where to enable                                                                            | Effect                                                                                                      |
| ------------------------------ | ------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| **Runtime PCIe D3cold**        | `echo auto > /sys/bus/pci/devices/0000:01:00.0/power/control` (handled by `nvidia-powerd`) | Lets the dGPU fully power-gate when idle; verified on Quadro/RTX laptops ([forums.developer.nvidia.com][8]) |
| **PRIME render-offload**       | Run Wayland session on iGPU and launch games with `prime-run`                              | dGPU stays off on battery, spins up only for 3D workloads                                                   |
| **PowerMizer “Adaptive/Auto”** | `nvidia-settings` or user-space daemon like **nvpowermizerd** ([github.com][9])            | Drops clocks quickly after load spikes                                                                      |
| **Suspend hooks**              | Enable `nvidia-suspend` & `nvidia-resume` runit services                                   | Prevents high drain after resume ([forums.developer.nvidia.com][10])                                        |

The two `nvidia-drm` options above **do not influence any of these power states**.

---

## 5  Void-specific early-KMS / initramfs note

If you regenerate initramfs with **dracut** (needed for LUKS or early console), include the driver list you pasted:

```conf
# /etc/dracut.conf.d/nvidia.conf
add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
install_items+=" /etc/modprobe.d/99-nvidia.conf "
```

Void’s wiki and community gist recommend the same ([gist.github.com][11]).

---

## 6  Practical recommendation for your Lenovo P-series laptop

1. **Keep `modeset=1`** – required for Niri/Hyprland and stable since R520+.
2. **Start with `fbdev=1` disabled** (`fbdev=0`) if you experience a boot hang or frozen TTY; otherwise leave it on for nicer text consoles and smoother resume ([bbs.archlinux.org][12], [bbs.archlinux.org][13]).
3. Enable runtime-PM (`nvidia-powerd`) and PRIME off-load for actual battery gains; use AC-powered profiles (`Prefer‐Maximum‐Performance`) only when gaming or benchmarking ([nvidia.custhelp.com][14]).

Follow these steps and your RTX 3000 Ada will run Wayland fast on AC while sleeping soundly on battery.

[1]: https://forums.developer.nvidia.com/t/understanding-nvidia-drm-modeset-1-nvidia-linux-driver-modesetting/204068?utm_source=chatgpt.com "Understanding nvidia-drm.modeset=1 (NVIDIA Linux driver modesetting)"
[2]: https://forums.developer.nvidia.com/t/blank-screen-on-boot/284828?utm_source=chatgpt.com "Blank screen on boot? - Linux - NVIDIA Developer Forums"
[3]: https://github.com/ventureoo/nvidia-tweaks?utm_source=chatgpt.com "GitHub - ventureoo/nvidia-tweaks: A collection of tweaks and ..."
[4]: https://bbs.archlinux.org/viewtopic.php?id=303311&utm_source=chatgpt.com "[SOLVED]The simpledrm doesn't automatically bypass with NVIDIA drivers ..."
[5]: https://download.nvidia.com/XFree86/Linux-x86_64/560.35.03/README/kms.html?utm_source=chatgpt.com "Chapter 36. Direct Rendering Manager Kernel Modesetting (DRM KMS) - Nvidia"
[6]: https://support.exxactcorp.com/hc/en-us/articles/32048852204951-Understanding-nomodeset-vs-nvidia-drm-modeset-1-on-Linux-Systems-with-NVIDIA-GPUs?utm_source=chatgpt.com "Understanding nomodeset vs. nvidia-drm.modeset=1 on Linux Systems with ..."
[7]: https://deepwiki.com/hyprwm/hyprland-wiki/4.4-nvidia-configuration?utm_source=chatgpt.com "Nvidia Configuration | hyprwm/hyprland-wiki | DeepWiki"
[8]: https://forums.developer.nvidia.com/t/nvidia-runtime-d3-power-management-issues/166854?utm_source=chatgpt.com "Nvidia runtime D3 power management issues - NVIDIA Developer Forums"
[9]: https://github.com/mrpdaemon/nvpowermizerd?utm_source=chatgpt.com "GitHub - mrpdaemon/nvpowermizerd: nvpowermizerd is a daemon to improve ..."
[10]: https://forums.developer.nvidia.com/t/extremely-power-consumption-after-nvidia-suspend-with-4060-laptop/311217?utm_source=chatgpt.com "Extremely power consumption after nvidia-suspend with 4060 laptop"
[11]: https://gist.github.com/inscapist/83fd43b49c17e46059eb4fe0c1ae8bea?utm_source=chatgpt.com "Nvidia and Xorg on Void Linux · GitHub"
[12]: https://bbs.archlinux.org/viewtopic.php?id=295937&utm_source=chatgpt.com "[SOLVED] Wayland + Nvidia - Arch Linux Forums"
[13]: https://bbs.archlinux.org/viewtopic.php?id=292681&utm_source=chatgpt.com "[SOLVED] KDE Wayland Nvidia doesn't load when using module options ..."
[14]: https://nvidia.custhelp.com/app/answers/detail/a_id/3130/~/setting-power-management-mode-from-normal-to-maximum-performance?utm_source=chatgpt.com "Setting \"Power management mode\" from Normal to Maximum Performance - NVIDIA"

---
---
---
---

Below is a detailed review of the two snippets you quoted, what they achieve, and whether they are still useful on a **current Void Linux + Wayland (Niri) + proprietary NVIDIA** system.

---

In one paragraph – **key findings**

*Void’s stock `nvidia`/`nvidiaXXX` packages already give you a working Wayland session; all you normally add is the kernel parameter (or a modprobe file) `nvidia‑drm.modeset=1`, which the official handbook itself hints at for KMS/Wayland support. Everything else in your snippet is only needed if you **also** want the very early, high‑resolution framebuffer console that shows the LUKS password prompt and bootsplash in native resolution. That feature became **experimental in driver 545** and is enabled by `fbdev=1`. To make that console appear before the root filesystem is unlocked you must place the NVIDIA modules **inside the initramfs**, which is what the `dracut.conf.d` lines do. Keeping these extra lines therefore trades a larger/tainted initramfs and the risk of black‑screen bugs for a prettier boot; if you can live with the low‑resolution `simpledrm` console, you can drop them.*

---

## 1  What Void already provides

| Aspect              | How Void handles it out‑of‑the‑box                                                                                                                                                           | Reference                                       |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| Driver installation | `xbps-install nvidia` (or `nvidia470`, `nvidia390`) builds DKMS modules automatically                                                                                                        | ([docs.voidlinux.org][1])                       |
| Wayland readiness   | Handbook recommends adding **`nvidia‑drm.modeset=1`** (either on the kernel command line or as a modprobe option) so wlroots/Niri can open the DRM device                                    | ([docs.voidlinux.org][1], [gist.github.com][2]) |
| initramfs content   | Dracut *already* copies every module **that is loaded while the image is generated**; because the NVIDIA modules are *not* loaded at that moment, they are **absent** from the default image | ([docs.voidlinux.org][3])                       |

So after installing the driver and adding the *modeset* option you can log straight into Niri on Wayland without touching dracut.

---

## 2  Why people add “early KMS + fbdev”

### 2.1 Kernel Mode Setting (`modeset=1`)

* Required for Wayland, PRIME off‑load, and modern color‑management properties.
* Only needs to be set **once** (kernel cmd‑line or `/etc/modprobe.d/nvidia.conf`).
* Harmless and stable since driver 470.
* Not automatically included by Void.
  ([wiki.archlinux.org][4], [forums.developer.nvidia.com][5])

### 2.2 Experimental framebuffer console (`fbdev=1`)

* Added in **driver 545**; gives a native‑resolution console provided by `nvidia‑drm` instead of `simpledrm`/`efifb`, so Plymouth or the cryptsetup prompt looks sharp.
* Still tagged *experimental* in 550/555; known to cause flip‑timeout or blank‑screen errors on some GPUs.
  ([forums.developer.nvidia.com][6], [forums.developer.nvidia.com][7], [forums.developer.nvidia.com][8])
* If `fbdev=1` is not set you still get a console – but via `simpledrm`, which stays at firmware resolution and hands over to NVIDIA only when the display server starts.
  ([forums.developer.nvidia.com][9], [bbs.archlinux.org][10])

---

## 3  Line‑by‑line review of your snippet

### 3.1 `/etc/modprobe.d/nvidia.conf`

```ini
options nvidia_drm modeset=1 fbdev=1
```

* **Syntax:** Module names in modprobe files are written with dashes, not underscores, so the canonical spelling is `nvidia-drm`. Both usually work but dash is safer. ([github.com][11])
* **modeset=1:** Correct and recommended for Wayland.
* **fbdev=1:** Optional; only useful if you run driver ≥ 545 *and* care about a high‑resolution text/plymouth/LUKS screen.

### 3.2 `/etc/dracut.conf.d/nvidia.conf`

```ini
add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
install_items+="/etc/modprobe.d/nvidia.conf"
```

| Directive       | What it does                                                                                                                           | When it helps                                                                                                              |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `add_drivers`   | Forces the four NVIDIA kernel modules into every initramfs that dracut builds. Without it they load *after* the root FS is unlocked.   | Required if you use **`fbdev=1`** or if you want Plymouth/LUKS to appear on external monitors that need the NVIDIA driver. |
| `install_items` | Copies your modprobe file *into* the image, so the module parameters are already in effect when `nvidia-drm` loads from the initramfs. | Same as above.                                                                                                             |

### 3.3 `dracut --regenerate-all --force`

After editing any dracut config you must rebuild the images; the command is correct. ([linuxconfig.org][12])

---

## 4  Risks & caveats

* **Boot‑time failures.** Some users report a hard freeze or “Flip event timeout” when `fbdev=1` is enabled on RTX 30/40‑series cards; simply remove `fbdev=1` (or blacklist the modprobe file) to recover. ([forums.developer.nvidia.com][8])
* **Large initramfs.** Because the proprietary modules are \~50 MiB, the compressed image can grow by 10‑15 MiB and is tagged “tainted” by the kernel.
* **Updates.** Every NVIDIA or kernel update requires rebuilding the initramfs **again** (`xbps-reconfigure -fa` or the dracut command).

---

## 5  Practical recommendations

| Goal                                         | Minimal steps            |
| -------------------------------------------- | ------------------------ |
| **Just run Niri on Wayland** (no fancy boot) | 1. `xbps-install nvidia` |

2. Add `nvidia‑drm.modeset=1` *either* to GRUB `CMDLINE_LINUX_DEFAULT` *or* in `/etc/modprobe.d/99‑nvidia.conf`.
3. `xbps-reconfigure -fa` & reboot. |
   \| **High‑res LUKS/Plymouth screen** with driver ≥ 545 | In addition to the above:
4. Add `fbdev=1` on the same line.
5. Create `/etc/dracut.conf.d/nvidia.conf` exactly as in your snippet.
6. Run `dracut --regenerate-all --force`.
7. Test; if you see “flip timeout” errors, remove `fbdev=1` and rebuild. |
   \| **Troubleshoot** | From a booted system run
   `cat /sys/module/nvidia_drm/parameters/modeset` and
   `cat /sys/module/nvidia_drm/parameters/fbdev` to verify that the parameters were applied. 1 = enabled. |

---

### Bottom line

*`modeset=1` is effectively **required** for any NVIDIA‑on‑Wayland setup and harmless to keep; `fbdev=1` plus the dracut tweaks buy you a nicer pre‑login console but remain experimental. If the crisp LUKS prompt is not worth occasional boot regressions, drop `fbdev=1` and the dracut file and follow the simpler handbook procedure.*

[1]: https://docs.voidlinux.org/config/graphical-session/graphics-drivers/nvidia.html "NVIDIA - Void Linux Handbook"
[2]: https://gist.github.com/inscapist/83fd43b49c17e46059eb4fe0c1ae8bea?utm_source=chatgpt.com "Nvidia and Xorg on Void Linux · GitHub"
[3]: https://docs.voidlinux.org/config/kernel.html?highlight=initramfs&utm_source=chatgpt.com "Kernel - Void Linux Handbook"
[4]: https://wiki.archlinux.org/title/Kernel_mode_setting?utm_source=chatgpt.com "Kernel mode setting - ArchWiki"
[5]: https://forums.developer.nvidia.com/t/understanding-nvidia-drm-modeset-1-nvidia-linux-driver-modesetting/204068?utm_source=chatgpt.com "Understanding nvidia-drm.modeset=1 (NVIDIA Linux driver modesetting)"
[6]: https://forums.developer.nvidia.com/t/linux-solaris-and-freebsd-driver-545-23-06-beta/269750 "Linux, Solaris, and FreeBSD driver 545.23.06 [beta] - Announcements and News - NVIDIA Developer Forums"
[7]: https://forums.developer.nvidia.com/t/linux-solaris-and-freebsd-driver-545-29-02-new-feature-branch-release/271330 "Linux, Solaris, and FreeBSD driver 545.29.02 [new feature branch release] - Announcements and News - NVIDIA Developer Forums"
[8]: https://forums.developer.nvidia.com/t/545-29-02-fbdev-1-cause-nvidia-drm-flip-event-timeout-on-boot-errors/272829?utm_source=chatgpt.com "545.29.02 fbdev=1 cause \"nvidia-drm Flip event timeout\" on boot errors"
[9]: https://forums.developer.nvidia.com/t/wayland-and-drm-fbdev/311423?utm_source=chatgpt.com "Wayland and DRM fbdev - Linux - NVIDIA Developer Forums"
[10]: https://bbs.archlinux.org/viewtopic.php?id=303311&utm_source=chatgpt.com "[SOLVED]The simpledrm doesn't automatically bypass with NVIDIA drivers ..."
[11]: https://github.com/elFarto/nvidia-vaapi-driver/issues/198?utm_source=chatgpt.com "nvidia-drm.modeset=1 OR nvidia_drm.modeset=1 #198 - GitHub"
[12]: https://linuxconfig.org/how-to-build-an-initramfs-using-dracut-on-linux?utm_source=chatgpt.com "How to build an initramfs using Dracut on Linux - LinuxConfig"

