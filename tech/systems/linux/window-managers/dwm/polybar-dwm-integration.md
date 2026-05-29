# Polybar + DWM Integration

This setup replaces DWM's built-in status bar with polybar using standard EWMH properties. No IPC
patch or dwm-msg is needed — only the lightweight `ewmhtags` patch (already merged into `dwm.c`) to
expose workspace atoms.

## How it works

### 1. Disable DWM's bar

In `src/dwm/config.h`:

```c
static const int showbar = 0;
```

This turns off the native DWM bar entirely, freeing screen space for polybar.

### 2. Polybar reads workspace state via EWMH

In `src/polybar/config.ini`:

```ini
[module/ewmh]
type = internal/xworkspaces
label-active = %{T2}●%{T-}
label-empty  = %{T2}○%{T-}
label-occupied  = %{T2}○%{T-}
```

`internal/xworkspaces` reads **EWMH (Extended Window Manager Hints)** — standard X11 properties like
`_NET_CURRENT_DESKTOP` and `_NET_NUMBER_OF_DESKTOPS`. Vanilla DWM does not set these — the
`ewmhtags` patch (merged into `dwm.c`) adds them. Polybar watches the X root window for property
changes and updates the workspace indicators automatically.

- Active workspace: `●`
- Empty/occupied: `○`

### 3. Polybar floats independently with override-redirect

```ini
[bar/bar1]
override-redirect = true
background = #00000000
height = 30
offset-y = 5
```

`override-redirect = true` tells X11 that polybar manages its own window — DWM won't tile, move, or
resize it. The background is fully transparent (`#00000000`), letting picom's blur and shadows
handle the visual appearance. The bar sits 5px from the top of the screen.

### 4. Window title via X11 properties

```ini
[module/xwindow]
type = internal/xwindow
label = %title%
label-maxlen = 30
```

Uses `_NET_WM_NAME` / `WM_NAME` X properties to display the focused window's title. No DWM-specific
protocol needed.

## Bar layout

```text
| <window title>       ● ○ ○ ○ ○        vol | date  time |
  modules-left         modules-center         modules-right
```

| Section | Modules                                                |
| ------- | ------------------------------------------------------ |
| Left    | `xwindow` — focused window title (max 30 chars)        |
| Center  | `ewmh` — workspace indicators                          |
| Right   | `pipewire` volume, `date`, `time` (separated by pipes) |

## Why this works (ewmhtags patch)

Vanilla DWM only implements basic EWMH atoms (`_NET_WM_NAME`, `_NET_WM_STATE`, `_NET_ACTIVE_WINDOW`,
etc.) — enough for window managers to function, but not the desktop/workspace atoms that polybar's
`internal/xworkspaces` needs. The `ewmhtags` patch, baked directly into `dwm.c`, adds the missing
atoms:

- `_NET_CURRENT_DESKTOP` — updated by `updatecurrentdesktop()` on every tag switch
- `_NET_NUMBER_OF_DESKTOPS` — set to `TAGSLENGTH` (5) at startup
- `_NET_DESKTOP_NAMES` — set from the `tags[]` array at startup
- `_NET_DESKTOP_VIEWPORT` — set to `{0, 0}` at startup

**Bitmask→index caveat:** DWM uses a bitmask for tag selection, but EWMH expects a linear desktop
index. `updatecurrentdesktop()` converts by finding the highest set bit
(`while(*rawdata >> (i+1))`). Note: the upstream suckless `ewmhtags` patch finds the _lowest_ set
bit instead (`for(i=0; !(tags & (1 << i)); i++)`); this fork diverges. For single-tag selection the
result is identical. When multiple tags are active simultaneously, this reports the highest tag
index to polybar (upstream would report the lowest).

The full requirements are:

1. `ewmhtags` patch merged into `dwm.c` (already done)
2. `showbar = 0` in DWM's config.h
3. `override-redirect = true` so DWM ignores the polybar window
4. `internal/xworkspaces` module in polybar to read the EWMH workspace properties
5. picom running for the transparent background to look correct (blur underneath)
