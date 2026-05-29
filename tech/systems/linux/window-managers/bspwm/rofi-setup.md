# Rofi Setup for bspwm

Application launcher, window switcher, and dmenu replacement.

**Reference:** [Arch Wiki: Rofi](https://wiki.archlinux.org/title/Rofi)

---

## Overview

Rofi is a window switcher, application launcher, and dmenu replacement. It provides:

- Application launcher (drun)
- Window switcher
- Command runner
- SSH connection menu
- Custom scripts and menus

Essential for bspwm since there's no built-in launcher.

---

## Installation

```bash
sudo pacman -S rofi
```

---

## Basic Usage

```bash
# Application launcher (desktop entries)
rofi -show drun

# Window switcher
rofi -show window

# Command runner (executables in $PATH)
rofi -show run

# SSH connections (from ~/.ssh/config)
rofi -show ssh

# Combined modes
rofi -show combi -combi-modes "drun,run,window"
```

---

## Configuration

### Config File

Create `~/.config/rofi/config.rasi`:

```bash
mkdir -p ~/.config/rofi
```

### Basic Config

```css
configuration {
    modi: "drun,run,window,ssh";
    show-icons: true;
    icon-theme: "Papirus";
    terminal: "kitty";
    drun-display-format: "{name}";
    font: "JetBrains Mono 12";
    display-drun: "Apps";
    display-run: "Run";
    display-window: "Windows";
    display-ssh: "SSH";
}
```

### HiDPI Config (4K)

For HiDPI/multi-monitor setups, use `dpi: 1` for per-monitor auto-detection:

```css
configuration {
    modi: "drun,run,window,ssh";
    show-icons: true;
    icon-theme: "Papirus";
    terminal: "kitty";
    drun-display-format: "{name}";
    dpi: 1;
    font: "JetBrains Mono 12";
    display-drun: "Apps";
    display-run: "Run";
    display-window: "Windows";
    display-ssh: "SSH";
}

window {
    width: 40%;
    padding: 20px;
}

element {
    padding: 12px;
}

element-icon {
    size: 32px;
}
```

---

## DPI Auto-Detection

Rofi does NOT read Xresources by default. You must explicitly enable auto-detection.

| Value     | Behavior                                        |
| --------- | ----------------------------------------------- |
| (omitted) | Uses Pango default (ignores Xresources)         |
| `dpi: 0`  | Auto-detect from X11 screen size (i3/GTK style) |
| `dpi: 1`  | Auto-detect from monitor rofi is on (Qt5 style) |

**Recommendation:** Use `dpi: 1` for multi-monitor setups - adapts to whichever monitor rofi appears
on. This is the [maintainer's recommendation](https://github.com/davatorium/rofi/discussions/1573).

```css
configuration {
    dpi: 1;
}
```

Test with command line:

```bash
rofi -show drun -dpi 1
```

**Xresources DPI inheritance:**

| Component | Inherits Xft.dpi?                  |
| --------- | ---------------------------------- |
| GTK apps  | Yes (via Xsettings or fontconfig)  |
| Qt apps   | Partial (prefers QT_SCALE_FACTOR)  |
| Rofi      | No (must set `dpi: 0` or `dpi: 1`) |
| Polybar   | No (set in config)                 |
| bspwm     | No (doesn't render fonts)          |
| Terminals | Usually yes                        |

For Xresources to take effect on apps that use it, load with `xrdb -merge ~/.Xresources` in
`~/.xinitrc` before starting bspwm.

---

## Keybindings (sxhkd)

Add to `~/.config/sxhkd/sxhkdrc`:

```bash
# Application launcher
super + p
    rofi -show drun -show-icons

# Window switcher
super + Tab
    rofi -show window -show-icons

# Command runner
super + shift + p
    rofi -show run

# SSH connections
super + s
    rofi -show ssh
```

Reload sxhkd after changes:

```bash
pkill -USR1 -x sxhkd
```

---

## Theming

### Built-in Themes

Preview and select themes:

```bash
rofi-theme-selector
```

Themes are stored in `/usr/share/rofi/themes/`.

### Set Theme in Config

```css
@theme "Arc-Dark"
```

Or specify theme path:

```css
@theme "/usr/share/rofi/themes/Arc-Dark.rasi"
```

### Custom Themes

Custom themes live in `~/.config/rofi/themes/` or `ricing/rofi/` in this repo.

Apply in config:

```css
@theme "theme-name"
```

### Purple City

Theme source: [purple-city.rasi](../../ricing/rofi/purple-city.rasi)\
Palette: [Purple City](../../ricing/colors/purple-city-dark-theme-color-system-specification.md)

Install:

```bash
mkdir -p ~/.config/rofi/themes
cp /path/to/systems/ricing/rofi/purple-city.rasi ~/.config/rofi/themes/purple-city.rasi
```

Apply in config:

```css
@theme "purple-city"

configuration {
    dpi: 1;
    font: "JetBrains Mono 12";
}
```

Font sizing targets (reference for manual override):

| Target          | Font                | Icon size |
| --------------- | ------------------- | --------- |
| 1080p / 96 DPI  | `JetBrains Mono 12` | `24px`    |
| 1440p / 120 DPI | `JetBrains Mono 13` | `28px`    |
| 4K / 192 DPI    | `JetBrains Mono 16` | `32px`    |

Adjust icon size in the theme:

```css
element-icon {
    size: 24px;
}
```

---

## Useful Modes

### Power Menu

Create `~/.local/bin/rofi-power-menu`:

```bash
#!/bin/bash

options="Lock\nLogout\nSuspend\nReboot\nShutdown"
selected=$(echo -e "$options" | rofi -dmenu -p "Power" -i)

case $selected in
    Lock) betterlockscreen -l ;;
    Logout) bspc quit ;;
    Suspend) systemctl suspend ;;
    Reboot) systemctl reboot ;;
    Shutdown) systemctl poweroff ;;
esac
```

```bash
chmod +x ~/.local/bin/rofi-power-menu
```

Add keybinding:

```bash
# Power menu
super + x
    ~/.local/bin/rofi-power-menu
```

### Clipboard Manager (greenclip)

Install greenclip:

```bash
paru -S rofi-greenclip
```

Start greenclip daemon (add to bspwmrc):

```bash
greenclip daemon &
```

Add keybinding:

```bash
# Clipboard history
super + v
    rofi -modi "clipboard:greenclip print" -show clipboard
```

### Emoji Picker

Install rofimoji:

```bash
paru -S rofimoji
```

Add keybinding:

```bash
# Emoji picker
super + period
    rofimoji
```

---

## Command-Line Options

| Option          | Purpose                    |
| --------------- | -------------------------- |
| `-show <mode>`  | Show specific mode         |
| `-show-icons`   | Display application icons  |
| `-theme <name>` | Use specific theme         |
| `-dmenu`        | Run as dmenu replacement   |
| `-p <prompt>`   | Custom prompt text         |
| `-i`            | Case insensitive matching  |
| `-lines <n>`    | Number of visible lines    |
| `-width <n>`    | Window width (% or pixels) |

---

## Troubleshooting

### Icons Not Showing

1. Install icon theme:

   ```bash
   sudo pacman -S papirus-icon-theme
   ```

2. Set in config:

   ```css
   icon-theme: "Papirus";
   ```

3. Update icon cache:

   ```bash
   gtk-update-icon-cache
   ```

### Applications Missing

Update desktop entry cache:

```bash
update-desktop-database ~/.local/share/applications
```

### Slow Startup

Disable icons for faster launch:

```bash
rofi -show drun -no-show-icons
```

### Theme Not Loading

Check theme path:

```bash
rofi -dump-theme
```

---

## References

- [Arch Wiki: Rofi](https://wiki.archlinux.org/title/Rofi)
- [Rofi GitHub](https://github.com/davatorium/rofi)
- [Rofi Themes Collection](https://github.com/davatorium/rofi-themes)
- [setup-arch-linux](setup-arch-linux.md) - bspwm stack overview
