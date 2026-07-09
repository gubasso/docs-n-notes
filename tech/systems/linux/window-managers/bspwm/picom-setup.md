# Picom Setup for bspwm

Compositor configuration for transparency, shadows, animations, and vsync.

**Reference:** [Arch Wiki: Picom](https://wiki.archlinux.org/title/Picom)

---

## Overview

Picom is a standalone compositor for X11. It provides:

- Window transparency and opacity
- Shadows and rounded corners
- Fade animations
- VSync (prevents screen tearing)

Without a compositor, X11 has no vsync and windows have no visual effects.

---

## Installation

```bash
sudo pacman -S picom
```

---

## Configuration File

Create `~/.config/picom/picom.conf`:

```bash
mkdir -p ~/.config/picom
```

### Minimal Config

```conf
# Backend
backend = "glx";
vsync = true;

# Shadows
shadow = true;
shadow-radius = 12;
shadow-offset-x = -12;
shadow-offset-y = -12;
shadow-opacity = 0.3;

# Fading
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;

# General
mark-wmwin-focused = true;
detect-rounded-corners = true;
detect-client-opacity = true;
```

### NVIDIA-Optimized Config

For Intel + NVIDIA hybrid systems (like ThinkPad P1):

```conf
# =============================================================================
# Backend (NVIDIA optimized)
# =============================================================================
backend = "glx";
vsync = true;
xrender-sync-fence = true;
# glx-no-stencil and glx-no-rebind-pixmap are deprecated in modern picom.
use-damage = true;

# =============================================================================
# Shadows
# =============================================================================
shadow = true;
shadow-radius = 12;
shadow-offset-x = -12;
shadow-offset-y = -12;
shadow-opacity = 0.3;

shadow-exclude = [
    "name = 'Notification'",
    "class_g = 'Polybar'",
    "class_g = 'slop'",
    "_GTK_FRAME_EXTENTS@:c"
];

# =============================================================================
# Fading
# =============================================================================
fading = true;
fade-in-step = 0.03;
fade-out-step = 0.03;
fade-delta = 5;

# =============================================================================
# Opacity
# =============================================================================
inactive-opacity = 1.0;
active-opacity = 1.0;
frame-opacity = 1.0;
inactive-opacity-override = false;

# Per-application opacity (optional)
opacity-rule = [
    # "90:class_g = 'kitty' && focused",
    # "80:class_g = 'kitty' && !focused"
];

# =============================================================================
# Corners
# =============================================================================
corner-radius = 8;

rounded-corners-exclude = [
    "class_g = 'Polybar'",
    "window_type = 'dock'",
    "window_type = 'desktop'"
];

# =============================================================================
# Blur (optional - can be heavy on GPU)
# =============================================================================
# blur-method = "dual_kawase";
# blur-strength = 5;
# blur-background = false;

# =============================================================================
# General
# =============================================================================
mark-wmwin-focused = true;
mark-ovredir-focused = true;
detect-rounded-corners = true;
detect-client-opacity = true;
detect-transient = true;
detect-client-leader = true;
use-ewmh-active-win = true;

wintypes:
{
    tooltip = { fade = true; shadow = false; opacity = 0.9; focus = true; };
    dock = { shadow = false; };
    dnd = { shadow = false; };
    popup_menu = { opacity = 1.0; shadow = false; };
    dropdown_menu = { opacity = 1.0; shadow = false; };
};
```

---

## Starting Picom

### From bspwmrc (Recommended)

Add to `~/.config/bspwm/bspwmrc`:

```bash
# Kill existing picom, start fresh
pkill -x picom
picom --config ~/.config/picom/picom.conf &
```

Or with duplicate prevention:

```bash
pgrep -x picom > /dev/null || picom --config ~/.config/picom/picom.conf &
```

### Manual Start (Testing)

```bash
# Foreground (see errors)
picom --config ~/.config/picom/picom.conf

# Background
picom --config ~/.config/picom/picom.conf &

# Background (daemon mode)
picom -b --config ~/.config/picom/picom.conf
```

---

## Verification

### Check Picom Running

```bash
pgrep picom
```

### Test Compositor Effects

1. **Shadows:** Open multiple windows, check for drop shadows
2. **Transparency:** If configured, inactive windows should be translucent
3. **Fading:** Windows should fade in/out when opening/closing
4. **Rounded corners:** Window corners should be rounded (if configured)
5. **VSync:** No screen tearing when scrolling or moving windows

### Check for Errors

```bash
# Run in foreground to see output
pkill picom
picom --config ~/.config/picom/picom.conf
```

---

## Reloading picom after config changes

Picom does not support live reload. Kill and restart it:

```bash
pkill -x picom
picom --config ~/.config/picom/picom.conf &
```

Or restart bspwm (`bspc wm -r`) — bspwmrc re-launches picom via its `pgrep` guard:

```bash
pgrep -x picom >/dev/null || picom --config ~/.config/picom/picom.conf &
```

Because of the guard, picom must be killed first if it is already running. `bspc wm -r` alone will
**not** restart picom.

---

## Troubleshooting

### Screen Tearing

1. Ensure `vsync = true` in config
2. Use `backend = "glx"` (not xrender)
3. For NVIDIA, add to config:

   ```conf
   xrender-sync-fence = true;
   ```

### High CPU/GPU Usage

1. Disable blur:

   ```conf
   blur-background = false;
   ```

2. Reduce shadow complexity:

   ```conf
   shadow = false;
   ```

3. Disable fading:

   ```conf
   fading = false;
   ```

### Black Screen / Artifacts

1. Try xrender backend:

   ```conf
   backend = "xrender";
   ```

2. Disable damage tracking:

   ```conf
   use-damage = false;
   ```

### Picom Won't Start

Check for errors:

```bash
picom --config ~/.config/picom/picom.conf 2>&1 | head -20
```

Common issues:

- Another compositor running (check `pgrep compton picom`)
- Invalid config syntax
- Missing GLX support (`glxinfo | grep "direct rendering"`)

### Flickering with NVIDIA

Add to config:

```conf
unredir-if-possible = false;
```

### Window Borders Disappear

Ensure bspwm border settings don't conflict:

```bash
# In bspwmrc
bspc config border_width 2
bspc config focused_border_color "#ffffff"
```

---

## Backend Comparison

| Backend   | Performance  | Compatibility    | Features              |
| --------- | ------------ | ---------------- | --------------------- |
| `glx`     | Best         | Good (needs GPU) | Full blur, best vsync |
| `xrender` | Good         | Best             | Limited blur          |
| `egl`     | Experimental | Variable         | Modern alternative    |

Use `glx` unless you have issues, then fall back to `xrender`.

---

## Useful Options Reference

| Option             | Purpose                             |
| ------------------ | ----------------------------------- |
| `vsync`            | Prevent screen tearing              |
| `backend`          | Rendering backend (glx/xrender)     |
| `shadow`           | Enable window shadows               |
| `fading`           | Enable fade animations              |
| `inactive-opacity` | Dim unfocused windows               |
| `corner-radius`    | Rounded window corners              |
| `blur-method`      | Background blur effect              |
| `use-damage`       | Optimize redraws (can cause issues) |

---

## References

- [Arch Wiki: Picom](https://wiki.archlinux.org/title/Picom)
- [Picom GitHub](https://github.com/yshui/picom)
- [setup-arch-linux](./setup-arch-linux.md) - bspwm stack overview
