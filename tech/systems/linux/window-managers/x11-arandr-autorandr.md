# X11 monitor management with `arandr` + `autorandr`

Use this workflow on X11 window managers when you want a visual way to arrange monitors and a
repeatable way to save and restore layouts.

- `arandr`: GUI frontend for `xrandr`; use it to arrange outputs and test a layout
- `autorandr`: profile manager for `xrandr`; use it to save known-good layouts and restore them on
  dock/undock

This is for X11 sessions. Wayland compositors have different monitor tooling.

## Packages

```bash
sudo pacman -S --needed xorg-xrandr arandr autorandr
```

## Mental model

1. Connect or disconnect monitors
2. Run `arandr` and arrange the layout visually
3. Apply the layout and confirm it works
4. Save the result with `autorandr --save <profile>`
5. Later, let `autorandr` detect and restore the matching profile

## First-time setup

Check output names first:

```bash
xrandr --query
```

Common examples are `eDP-1` for the laptop panel and `DP-*` or `HDMI-*` for external outputs, but
always use the names reported by `xrandr`.

Create a laptop-only profile:

```bash
# Disconnect external displays first
arandr
# In the GUI: keep only the internal panel enabled, set it primary, Apply
autorandr --save undocked
```

Create a docked/external-monitor profile:

```bash
# Connect the dock or external monitor(s) first
arandr
# In the GUI: place monitors where you want them, choose the primary output, Apply
autorandr --save docked
```

Set a fallback profile:

```bash
autorandr --default undocked
```

## Daily use

Usually this is enough:

```bash
autorandr --change
```

Useful commands:

```bash
autorandr --detected          # Show matching profile(s) for current hardware
autorandr --current           # Show active profile
autorandr --load docked       # Force a specific profile
autorandr --load undocked
autorandr --change --force    # Reapply even if nothing appears to have changed
```

Profiles are stored under:

```text
~/.config/autorandr/<profile>/config
```

## Practical workflow

- Stable layout you want to keep: fix it in `arandr`, then resave the profile
- Temporary one-off layout: use `arandr` and do not save it
- Dock/undock event or monitor state changed: run `autorandr --change`
- Detection looks stale: run `autorandr --change --force`

Prefer native resolutions unless there is a concrete reason to scale or distort the layout.

## Mixed-DPI scaling

X11 has a single global DPI, so when a HiDPI laptop panel (e.g. 4K at 192 DPI) is paired with a
lower-resolution external monitor (e.g. FHD), the external inherits the high DPI and everything
renders too large.

The fix is `xrandr --scale` on the external monitor. For example, `--scale 2x2` on a 1920x1080 panel
renders at 3840x2160 virtual pixels and downscales to the physical resolution. With 192 DPI
globally, the effective DPI on the scaled output becomes 96 — correct proportions. Integer downscale
factors (2x2) stay sharp; non-integer factors may appear blurry.

Example (4K laptop left, FHD external right):

```bash
xrandr \
  --output eDP-1 --mode 3840x2400 --pos 0x0 --scale 1x1 \
  --output DP-2-1-5 --mode 1920x1080 --pos 3840x0 --scale 2x2 --primary
```

Key details:

- `--pos` uses the **unscaled** coordinate space of neighboring outputs. The external starts at
  x=3840 because eDP-1 is 3840 pixels wide at 1x1 scale.
- The external's **virtual** size (3840x2160 after 2x2 scale) determines how much desktop space it
  occupies, but positioning is relative to real pixels.
- Save the result with `autorandr --save <profile> --force` so scaling persists across dock/undock
  cycles.

## Hooks

If something must be refreshed after a profile switch, use `autorandr` hooks:

- Global hook: `~/.config/autorandr/postswitch`
- Per-profile hook: `~/.config/autorandr/<profile>/postswitch`

Typical uses:

- Relaunch wallpaper tools
- Restart bars or trays
- Switch default audio sink after docking

## Troubleshooting

- For a full diagnostic snapshot, run:

```bash
./x11-arandr-autorandr-debug-report.sh
```

This prints a labeled report for `xrandr`, `arandr`, `autorandr`, EDID, provider state, Xorg logs,
kernel messages, and dock-related details. It also saves the same output to a timestamped file under
`/tmp`, which is useful when feeding the report to an AI helper or bug report.

- Wrong profile selected: run `xrandr --query` and confirm the real output names
- Layout saves incorrectly: inspect `~/.config/autorandr/<profile>/config`
- Change not applied: run `autorandr --change --force`
- Hardware state changed permanently: fix the layout in `arandr` and resave the profile
