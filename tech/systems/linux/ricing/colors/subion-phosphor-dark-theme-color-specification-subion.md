# Subion Phosphor — Dark Theme Color Specification (subion)

## 1. Purpose and scope

This document defines a cohesive **dark UI color system** inspired by a **green phosphor terminal /
HUD** aesthetic (thin lines, controlled glow, near-black glass). It is optimized for **OLED-friendly
near-black backgrounds**, high legibility, and strict **single-accent discipline**.

Apply consistently across:

- Window manager (X11 WM)
- Bars/widgets (polybar)
- Terminal (kitty)
- Launchers (rofi)
- Notifications (dunst)
- Editors and other apps with theming support

---

## 2. Design intent

- **Phosphor-first**: UI reads like green ink on dark glass.
- **Near-black foundations**: large surfaces stay deep to preserve contrast and perceived glow.
- **Line-art chrome**: borders/dividers are green-tinted overlays, not gray.
- **Accent discipline**: one primary accent; a brighter glow only for attention cues.
- **Readability over novelty**: long-session comfort is the constraint.

### 2.1 Typography and optional CRT feel (non-color guidance)

- Fonts: prefer crisp monospace with good low-contrast rendering (e.g., **IBM Plex Mono**,
  **JetBrains Mono**, **Terminus**).
- Optional CRT effects (scanlines/bloom) are **out of scope** for this palette, but pair well if
  kept subtle.

---

## 3. Core palette

### 3.1 Neutral layers (backgrounds and surfaces)

| Token      | Hex       | Usage                                                |
| ---------- | --------- | ---------------------------------------------------- |
| `bg0`      | `#020604` | True background (desktop root, app background)       |
| `bg1`      | `#04130B` | Base background for panels/containers                |
| `bg2`      | `#071E11` | Elevated background (sidebars, grouped blocks)       |
| `surface0` | `#0B2A17` | Primary surface (cards, bar background)              |
| `surface1` | `#0F3620` | Secondary surface (hovered/focused containers)       |
| `overlay0` | `#184C2F` | Borders, separators, subtle selection background     |
| `overlay1` | `#21683E` | Stronger borders, active outlines, low-glow emphasis |

### 3.2 Text (phosphor ink)

| Token     | Hex       | Usage                                        |
| --------- | --------- | -------------------------------------------- |
| `text`    | `#E6FFF3` | Primary text                                 |
| `subtext` | `#BFE9D3` | Secondary text (labels, inactive tabs)       |
| `muted`   | `#94C8AD` | Tertiary text (hints, timestamps, subtle UI) |

**Contrast verification note:** `muted` (`#94C8AD`) on `surface1` (`#0F3620`) is ~**7.09:1** (WCAG
contrast ratio), leaving headroom even if perceived contrast feels softer in green-heavy pairs.

### 3.3 Brand accents (phosphor greens)

| Token         | Hex       | Usage                                                                       |
| ------------- | --------- | --------------------------------------------------------------------------- |
| `green_mid`   | `#39C777` | Active fills, selected elements, steady emphasis                            |
| `accent`      | `#7CF5A6` | **Primary accent** (focus ring, active border, links, primary buttons)      |
| `accent_glow` | `#00FF80` | **Attention-only** (urgent highlight, glow indicators, critical focus cues) |

**Rationale:** `accent_glow` stays **on-hue** (intensified green) rather than shifting into
yellow-green, and is deliberately **higher saturation** than `accent` so it reads as “attention” on
real OLED panels. If it’s too aggressive in your environment, dial back toward `#5FFFB0`.

### 3.4 Semantic colors (status)

Keep these consistent with conventional semantics while still fitting the neon-terminal vibe.

| Token     | Hex       | Usage                                  |
| --------- | --------- | -------------------------------------- |
| `success` | `#42F5C0` | Success states, OK/connected           |
| `warning` | `#FFD166` | Warnings, prompts requiring attention  |
| `error`   | `#FF5A7A` | Errors, urgent/critical states         |
| `info`    | `#6EE7FF` | Informational messages, optional links |

### 3.5 Auxiliary chroma (terminal lanes)

These tokens exist to keep terminal/ANSI behavior coherent without polluting the semantic set.

| Token             | Hex       | Usage                                                             |
| ----------------- | --------- | ----------------------------------------------------------------- |
| `cyan`            | `#50D4D4` | ANSI cyan lane (`color6`) — distinct from `success`               |
| `cyan_bright`     | `#86EFFF` | ANSI bright cyan lane (`color14`)                                 |
| `alt_phosphor`    | `#5FAA80` | ANSI “magenta slot” repurposed (`color5`) — on-theme but distinct |
| `alt_phosphor_hi` | `#A0FFB8` | ANSI bright “magenta slot” (`color13`)                            |

---

## 4. Usage rules

### 4.1 Elevation model

- **Background**: `bg0`
- **Base panels/blocks**: `bg1` (flat) or `bg2` (raised)
- **Interactive surfaces**: `surface0` (default), `surface1` (hover/focus)
- **Separation**: `overlay0` for borders/dividers
- **Active emphasis**: `overlay1` for stronger separators/active outlines

### 4.2 Accent discipline

- Use **`accent`** (`#7CF5A6`) as the default accent across the system:

  - focused borders
  - active tabs
  - links
  - primary actions
- Use **`accent_glow`** (`#00FF80`) sparingly:

  - urgent focus/selection feedback
  - “live” indicators (recording/progress/active session)
  - critical highlights that must pop

### 4.3 Text contrast

- `text` for primary body content
- `subtext` for labels and secondary chrome
- `muted` only when information can be de-emphasized

### 4.4 Borders and separators

- Default border: `overlay0`
- Active/selected border or fill: `green_mid`
- Focused border/focus ring: `accent`

### 4.5 Selection and highlight behavior

- Selection background: `overlay0` (subtle, readable)
- Search highlight / strong selection: `accent` (default)
- “critical search” / presel feedback: `accent_glow` (attention-only)

### 4.6 Cursor model (CRT-friendly guidance)

- Prefer a **block cursor** with a **moderate blink** for phosphor feel.
- For kitty, place cursor behavior in **`kitty.conf`** (not `colors.conf`): `cursor_shape block` +
  `cursor_blink_interval 0.6`

---

## 5. Reference implementations

### 5.1 Kitty

**File**: `~/.config/kitty/colors.conf`

```conf
# Subion Phosphor (subion)
foreground            #E6FFF3
background            #020604
selection_foreground  #E6FFF3
selection_background  #184C2F
cursor                #7CF5A6
cursor_text_color     #020604

# UI
active_border_color   #7CF5A6
inactive_border_color #184C2F
bell_border_color     #00FF80
url_color             #6EE7FF

# ANSI 16
# Notes:
# - Magenta slot (5/13) is NOT lime; it's a distinct phosphor-tinted lane to preserve CLI semantics.
# - Cyan (6) is separated from success (2/10 + semantic success) to avoid collisions.
color0  #04130B
color8  #184C2F

color1  #FF5A7A
color9  #FF86A0

color2  #39C777
color10 #7CF5A6

color3  #FFD166
color11 #FFE08A

color4  #6EE7FF
color12 #A6F3FF

# Magenta slot repurposed to a distinct “alt phosphor” (still on-theme, not yellow-green)
color5  #5FAA80
color13 #A0FFB8

# Cyan lane separated from success
color6  #50D4D4
color14 #86EFFF

color7  #BFE9D3
color15 #E6FFF3
```

**File**: `~/.config/kitty/kitty.conf` (behavior + include)

```conf
include colors.conf

# Cursor feel (CRT-leaning; behavior belongs here, not in colors.conf)
cursor_shape          block
cursor_blink_interval 0.6
```

---

### 5.2 dwm

**File**: `src/dwm/config.h`

```c
/* Border colors are compile-time constants in dwm */
static const char normbordercolor[] = "#184C2F";
static const char selbordercolor[]  = "#7CF5A6";
```

---

### 5.3 Polybar

**File**: `~/.config/polybar/config.ini`

```ini
[colors]
# Core keys (kept structurally compatible with other specs)
bg      = #020604
fg      = #E6FFF3
muted   = #94C8AD

surface = #0B2A17
border  = #184C2F

primary = #7CF5A6
glow    = #00FF80

warn    = #FFD166
alert   = #FF5A7A
info    = #6EE7FF
ok      = #42F5C0

# Extended tokens (optional, when your bar config benefits from them)
subtext = #BFE9D3
bg1     = #04130B
bg2     = #071E11
surface1= #0F3620
border2 = #21683E
mid     = #39C777
cyan    = #50D4D4
```

---

### 5.4 Dunst

**File**: `~/.config/dunst/dunstrc`

```ini
[global]
frame_color = "#184C2F"
separator_color = "frame"

[urgency_low]
background = "#071E11"
foreground = "#BFE9D3"
frame_color = "#184C2F"

[urgency_normal]
background = "#0B2A17"
foreground = "#E6FFF3"
frame_color = "#7CF5A6"

[urgency_critical]
background = "#0B2A17"
foreground = "#E6FFF3"
frame_color = "#FF5A7A"
```

---

### 5.5 Rofi

**Theme file**: `~/.config/rofi/themes/subion-phosphor.rasi` **Config include**:
`~/.config/rofi/config.rasi`

```css
/* Subion Phosphor (subion) */
* {
  bg0:      #020604;
  bg1:      #04130B;
  bg2:      #071E11;
  surface0: #0B2A17;
  surface1: #0F3620;

  overlay0: #184C2F;
  overlay1: #21683E;

  fg:       #E6FFF3;
  subtext:  #BFE9D3;
  muted:    #94C8AD;

  primary:  #7CF5A6;
  mid:      #39C777;
  glow:     #00FF80;

  warn:     #FFD166;
  alert:    #FF5A7A;
  info:     #6EE7FF;
  ok:       #42F5C0;
}

window {
  background-color: @bg0;
  border: 1px;
  border-color: @overlay0;
}

mainbox {
  background-color: @bg0;
}

inputbar {
  background-color: @bg1;
  text-color: @fg;
  border: 1px;
  border-color: @overlay0;
}

prompt {
  text-color: @primary;
  background-color: transparent;
}

entry {
  text-color: @fg;
  background-color: transparent;
}

listview {
  background-color: @bg0;
}

element {
  background-color: transparent;
  text-color: @subtext;
}

element selected {
  background-color: @surface0;
  text-color: @fg;

  /* Selection indicator: phosphor-idiomatic left bar (avoids “boxed card” look) */
  border: 0px;
  border-left: 2px;
  border-color: @primary;
}

element-text selected {
  text-color: @fg;
}

message {
  background-color: @bg0;
  border: 1px;
  border-color: @overlay0;
}
```

Add to `~/.config/rofi/config.rasi`:

```css
@theme "subion-phosphor"
```

Run:

```bash
rofi -show drun -theme ~/.config/rofi/themes/subion-phosphor.rasi
```

---

## 6. Change control

- Treat this palette as the **single source of truth**.
- If a component needs a new color, add it here first as a token with a stated purpose.
- Avoid introducing additional greens unless they have a specific semantic role.

---

## 7. Quick checklist

- [ ] Large backgrounds use `bg0/bg1` (not mid-gray)
- [ ] Body text uses `text` on dark surfaces
- [ ] Focus states use `accent`
- [ ] Only urgent cues use `accent_glow` / `error`
- [ ] ANSI magenta slot is **not** lime/yellow; it remains on-theme but semantically distinct
      (`alt_phosphor`)
- [ ] Cyan lane (`cyan` / `color6`) is distinct from `success`
- [ ] Rofi selection uses a left-bar indicator (not a full box border)
- [ ] Kitty cursor behavior lives in `kitty.conf` (colors stay in `colors.conf`)
