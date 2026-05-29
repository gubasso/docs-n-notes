# Color Management (X11 / dwm)

Color management ensures your display shows accurate colors by applying correction profiles (ICC
files) that compensate for each panel's unique characteristics.

## Stack Overview

The standard stack for non-GNOME/KDE X11 setups:

| Component       | Role                                                                                                                                         |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **ICC profile** | Calibration file describing how a specific display reproduces color                                                                          |
| **colord**      | D-Bus system daemon that stores a device ↔ profile database                                                                                  |
| **xiccd**       | Session bridge for X11 — enumerates XRandR displays, registers them in colord, generates EDID-based defaults, and applies the active profile |

xiccd should **not** be used in desktop environments with native color management (GNOME, KDE). It
is specifically for standalone WMs like dwm.

## Do You Need This?

- **Coding / general use:** Probably not. OLED panels ship with decent factory calibration. If
  colors look off, check gamma or night-light settings first.
- **Photo/video editing, design:** Yes — proper calibration matters, especially with mixed displays
  (e.g., internal OLED + docked external).

## Setup

### 1. Install Packages

Baseline:

```bash
sudo pacman -S colord xiccd
```

For real calibration (recommended if you have a colorimeter):

```bash
sudo pacman -S argyllcms displaycal
```

Optional GUI for browsing/managing profiles (works without GNOME):

```bash
sudo pacman -S gnome-color-manager
```

### 2. Polkit Authentication Agent

colord actions may require PolicyKit authorization. Without a running agent in your X session, you
get silent failures.

The Arch X11 WM package list already includes `polkit-gnome`. Ensure its agent is autostarted in
your session (add to `~/.xinitrc` before `exec startdwm`):

```sh
pgrep -f polkit-gnome-authentication-agent-1 >/dev/null || \
  /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
```

See [Polkit - ArchWiki][polkit] for details.

### 3. Start xiccd

Add to `~/.xinitrc` (before `exec startdwm`):

```sh
pgrep -x xiccd >/dev/null || xiccd &
```

Once running, xiccd enumerates displays via XRandR, registers them in colord, and applies profiles.
It handles hotplug (dock/undock) automatically.

### 4. Check for Existing Profiles

```bash
# System-wide ICC directory
ls /usr/share/color/icc/

# User directory
ls ~/.color/icc/

# Profiles known to colord
colormgr get-profiles
```

Some panels ship with bundled profiles. Search for your panel model online for community profiles if
none are present.

### 5. Assign Profiles to Displays

The `colormgr` workflow uses **object paths**, not raw filenames.

1. **Install the ICC file** where colord looks:

   ```bash
   # System-wide
   sudo cp profile.icc /usr/share/color/icc/

   # Or per-user
   cp profile.icc ~/.color/icc/
   ```

   Restart `colord.service` if it was already running so new profiles are indexed.

2. **List devices** (xiccd must be running):

   ```bash
   colormgr get-devices
   ```

3. **List profiles** to find the object path:

   ```bash
   colormgr get-profiles
   ```

4. **Attach and set default:**

   ```bash
   colormgr device-add-profile <DEVICE_OBJECT_PATH> <PROFILE_OBJECT_PATH>
   colormgr device-make-profile-default <DEVICE_OBJECT_PATH> <PROFILE_OBJECT_PATH>
   ```

## Calibration (Requires Hardware)

Creating an accurate ICC profile requires a colorimeter.

### Supported Colorimeters

ArgyllCMS supports devices in the i1Display and ColorChecker families:

- **Budget:** X-Rite i1Display Studio (~$180)
- **Mid-range:** Calibrite ColorChecker Display (~$250)

On Linux, you may need **udev rules** so ArgyllCMS can access the meter as a normal user. See
[ArgyllCMS Linux installation][argyll-linux].

### Profiling Workflow

DisplayCAL provides a GUI front-end for ArgyllCMS:

```bash
sudo pacman -S argyllcms displaycal
displaycal
```

It walks you through measuring and generating an ICC profile for your panel.

### Multi-Monitor Strategy

For setups with mixed displays (e.g., internal OLED + docked 27" external):

- Create **separate profiles** for each display.
- xiccd maps profiles to XRandR outputs using EDID, so hotplug/docking is handled automatically.

## X11 Limitations

Color management on X11 primarily benefits **color-managed applications** (browsers with profile
support, photo editors, some toolkits). Many UI toolkits and applications still ignore ICC profiles.
This is an inherent X11 limitation, not a configuration problem.

## OLED-Specific Notes (ThinkPad P1 Gen 7)

The P1's 4K OLED panel has reasonable factory calibration. Unless you are doing color-critical work,
the setup above is not worth the effort. The panel is more likely to benefit from proper calibration
when paired with a docked external monitor that has visibly different color rendering.

## References

- [ICC profiles - ArchWiki][icc-wiki]
- [colord — How do I use colord?][colord-using]
- [xiccd(8) — Arch manual pages][xiccd-man]
- [ArgyllCMS — Supported instruments][argyll-instruments]
- [DisplayCAL — Arch package][displaycal-pkg]

[icc-wiki]: https://wiki.archlinux.org/title/ICC_profiles "ICC profiles - ArchWiki"
[colord-using]: https://www.freedesktop.org/software/colord/using.html "How do I use colord? - freedesktop.org"
[xiccd-man]: https://man.archlinux.org/man/extra/xiccd/xiccd.8.en "xiccd(8) — Arch manual pages"
[argyll-instruments]: https://www.argyllcms.com/doc/instruments.html "ArgyllCMS — Supported instruments"
[argyll-linux]: https://www.argyllcms.com/doc/Installing_Linux.html "ArgyllCMS — Linux installation"
[displaycal-pkg]: https://archlinux.org/packages/extra/x86_64/displaycal/ "Arch Linux — displaycal"
[polkit]: https://wiki.archlinux.org/title/Polkit "polkit - ArchWiki"
