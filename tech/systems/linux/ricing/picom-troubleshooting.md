# Picom Troubleshooting: Black Flash on New Window

## Symptom

Subtle black flicker/flash when opening a new terminal (or any window) in a tiled window manager
workspace.

## Fix escalation (try in order)

### 1. Disable `unredir-if-possible` (most likely fix)

`unredir-if-possible = true` causes picom to toggle between redirected and unredirected compositing.
Window map/unmap triggers a redirect switch, producing a visible black frame.

```conf
unredir-if-possible = false;
```

Trade-off: fullscreen apps (games, video players) no longer bypass the compositor. Usually
negligible for desktop use.

**Test without editing config:**

```bash
pkill -x picom
picom --config ~/.config/picom/picom.conf --unredir-if-possible=false --log-level WARN
```

### 2. Disable damage tracking

`use-damage = true` tells picom to only repaint changed screen regions. Buggy damage tracking can
composite incomplete regions on newly mapped windows.

```conf
use-damage = false;
```

Trade-off: higher GPU usage (full redraws every frame).

**Test:**

```bash
pkill -x picom
picom --config ~/.config/picom/picom.conf --no-use-damage --log-level WARN
```

### 3. Fall back to xrender backend

If GLX artifacts persist, xrender is the safe fallback. Picom docs call it the stable option when
GLX causes rendering issues.

```conf
backend = "xrender";
```

Trade-off: loses GLX-specific features (blur, some optimizations). VSync still works.

**Test:**

```bash
pkill -x picom
picom --backend xrender --vsync --log-level WARN
```

### 4. Disable xrender-sync-fence

Only relevant if using GLX on NVIDIA hybrid. In rare cases, the sync fence itself introduces latency
that looks like a flash.

```conf
xrender-sync-fence = false;
```

**Test:** edit `picom.conf` to set `xrender-sync-fence = false;`, then:

```bash
pkill -x picom
picom --config ~/.config/picom/picom.conf --log-level WARN &
```

Note: `--no-xrender-sync-fence` does not exist as a CLI flag. This option can only be toggled via
the config file.

## Not applicable to current config

These fixes from online guides do NOT apply to the current minimal config:

- `no-fading-openclose = true` — fading is already fully disabled (`fading = false`)
- `glx-no-rebind-pixmap` — deprecated and removed; modern picom handles pixmap binding internally
- `glx-no-stencil` — deprecated and removed; modern picom handles stencil buffer internally

## Useful debug commands

```bash
# Run picom in foreground with verbose logging
pkill -x picom; picom --config ~/.config/picom/picom.conf --log-level DEBUG

# Check if picom is running
pgrep -x picom

# Check GLX support
glxinfo | grep "direct rendering"

# Check for another compositor
pgrep -x compton picom
```
