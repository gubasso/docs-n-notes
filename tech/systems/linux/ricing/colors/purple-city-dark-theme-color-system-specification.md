# Purple City — Brand Guidelines / Visual Identity + Web Style Guide

> **Version:** 2.0.0 **Purpose:** Single source of truth (SoT) for Purple City's visual identity and
> web UI system. All derived artifacts (CSS variables, Tailwind config, JSON tokens, component
> libraries) should be generated from the tokens and rules defined here.

---

## Table of Contents

1. [Brand Foundations](#1-brand-foundations)
2. [Color System](#2-color-system)
3. [Accessibility](#3-accessibility)
4. [Typography System](#4-typography-system)
5. [Layout & Spacing](#5-layout--spacing)
6. [Iconography & Imagery](#6-iconography--imagery)
7. [Components (Spec-Level)](#7-components-spec-level)
8. [Motion](#8-motion)

---

## 1. Brand Foundations

### Summary

**Purple City** is a neon-noir, cyberpunk design system built on deep violet darkness and saturated
purple/magenta illumination. The UI should feel like a terminal-grade control surface inside a
rain-slick metropolis: minimal chrome, precise highlights, deliberate glow.

**Logo / Mark:** Not provided in source image(s).

### Visual Principles

1. **Dark-first, glow-second** — darkness is the canvas; glow is the hierarchy cue.
2. **Sparse emphasis** — use neon only where interaction or hierarchy requires it.
3. **Atmosphere over ornament** — haze gradients, vignettes, subtle grain are allowed. Busy
   decoration is not.
4. **Terminal credibility** — mono type, system-like labels, CRT-inspired effects.
5. **High contrast, low noise** — bright accents on near-black; no visual clutter.

### Tone of Voice (UI Copy)

Crisp, technical, slightly mysterious. Prefer short verbs and system/status language.

_Assumption (Med confidence):_ Microcopy favors system actions over playful phrasing (e.g.,
"Authenticate", "Initialize", "Trace", "Access Denied").

**Do:** Use concise labels and status patterns ("ONLINE", "SYNCING", "FAILED"). Error copy should be
direct and actionable.

**Don't:** Use casual exclamations or emoji that break the noir/terminal tone.

---

## 2. Color System

### 2.1 Extraction Notes

Colors are reverse-engineered from the source image's dominant dark violets and neon signage
highlights. Where semantic/utility colors are not present in the image, they are proposed and
flagged.

### 2.2 Raw Palette

| Token                  | Name          | HEX       | RGB           | HSL             | Intended Use                |
| ---------------------- | ------------- | --------- | ------------- | --------------- | --------------------------- |
| `palette.purpleInk`    | Purple Ink    | `#030009` | 3, 0, 9       | 260°, 100%, 2%  | Page background             |
| `palette.abyssViolet`  | Abyss Violet  | `#0B0117` | 11, 1, 23     | 267°, 92%, 5%   | Surface base                |
| `palette.nightPlum`    | Night Plum    | `#120326` | 18, 3, 38     | 266°, 85%, 8%   | Surface raised / inputs     |
| `palette.darkOrchid`   | Dark Orchid   | `#2D084C` | 45, 8, 76     | 273°, 81%, 16%  | Subtle borders              |
| `palette.deepViolet`   | Deep Violet   | `#631086` | 99, 16, 134   | 282°, 79%, 29%  | Secondary emphasis          |
| `palette.duskLavender` | Dusk Lavender | `#8B6BB2` | 139, 107, 178 | 267°, 32%, 56%  | Muted text / strong borders |
| `palette.softLavender` | Soft Lavender | `#CBB7E6` | 203, 183, 230 | 266°, 48%, 81%  | Text secondary              |
| `palette.lavenderMist` | Lavender Mist | `#F3E9FF` | 243, 233, 255 | 267°, 100%, 96% | Text primary                |
| `palette.neonPurple`   | Neon Purple   | `#DC4ADF` | 220, 74, 223  | 299°, 70%, 58%  | Primary interactive         |
| `palette.neonLilac`    | Neon Lilac    | `#E350EA` | 227, 80, 234  | 297°, 79%, 62%  | Primary hover               |
| `palette.hotMagenta`   | Hot Magenta   | `#E040F3` | 224, 64, 243  | 294°, 88%, 60%  | Accent / focus              |
| `palette.pinkBloom`    | Pink Bloom    | `#EC63F0` | 236, 99, 240  | 298°, 82%, 66%  | Accent alt                  |

### 2.3 Semantic Colors

_Assumption (Low confidence):_ Not present in source image. Proposed as high-chroma neon companions
that read on the dark violet base.

| Role    | Token                       | HEX       | RGB          | HSL             |
| ------- | --------------------------- | --------- | ------------ | --------------- |
| Success | `palette.successNeonMint`   | `#2DFF8F` | 45, 255, 143 | 148°, 100%, 59% |
| Warning | `palette.warningAmberGlare` | `#FFB020` | 255, 176, 32 | 39°, 100%, 56%  |
| Error   | `palette.errorCrimsonPulse` | `#FF3B5C` | 255, 59, 92  | 350°, 100%, 62% |
| Info    | `palette.infoCyanTrace`     | `#2DE2FF` | 45, 226, 255 | 188°, 100%, 59% |

### 2.4 Role Mapping

Product code should consume role tokens, not raw palette values, except for art-direction cases
(gradients, illustrations).

| Role                               | Token                            | Palette Reference           |
| ---------------------------------- | -------------------------------- | --------------------------- |
| **Background**                     | `color.bg`                       | `purpleInk`                 |
| **Surface (default)**              | `color.surface.1`                | `abyssViolet`               |
| **Surface (raised/inputs/modals)** | `color.surface.2`                | `nightPlum`                 |
| **Border (subtle)**                | `color.border.subtle`            | `darkOrchid`                |
| **Border (strong)**                | `color.border.strong`            | `duskLavender`              |
| **Text primary**                   | `color.text.primary`             | `lavenderMist`              |
| **Text secondary**                 | `color.text.secondary`           | `softLavender`              |
| **Text muted**                     | `color.text.muted`               | `duskLavender`              |
| **Text on primary**                | `color.text.onPrimary`           | `purpleInk`                 |
| **Action primary (default)**       | `color.action.primary.bg`        | `neonPurple`                |
| **Action primary (hover)**         | `color.action.primary.bgHover`   | `neonLilac`                 |
| **Action primary (fg)**            | `color.action.primary.fg`        | `purpleInk`                 |
| **Action primary (focus)**         | `color.action.primary.focus`     | `hotMagenta`                |
| **Action secondary (fg/border)**   | `color.action.secondary.fg`      | `neonPurple`                |
| **Action secondary (hover bg)**    | `color.action.secondary.bgHover` | `neonPurple` at 10% opacity |
| **Accent primary**                 | `color.accent.primary`           | `hotMagenta`                |
| **Accent alt**                     | `color.accent.alt`               | `pinkBloom`                 |
| **Semantic success**               | `color.semantic.success`         | `successNeonMint`           |
| **Semantic warning**               | `color.semantic.warning`         | `warningAmberGlare`         |
| **Semantic error**                 | `color.semantic.error`           | `errorCrimsonPulse`         |
| **Semantic info**                  | `color.semantic.info`            | `infoCyanTrace`             |

**Do:** Use neon primarily for actions, focus, selection, and key status indicators. Keep most
layouts grounded in surfaces + typography.

**Don't:** Use neon as a general background fill across large areas — it flattens hierarchy and
fatigues users.

### 2.5 Gradients

| Name                   | CSS Value                                                                              | Usage                              | Confidence |
| ---------------------- | -------------------------------------------------------------------------------------- | ---------------------------------- | ---------- |
| **Background Haze**    | `linear-gradient(180deg, #1D0538 0%, #120326 35%, #030009 100%)`                       | Page/section background depth      | Med        |
| **Neon Glow (radial)** | `radial-gradient(circle at 50% 50%, rgba(224,64,243,0.35) 0%, rgba(224,64,243,0) 60%)` | Ambient glow behind focal elements | High       |
| **Overlay Veil**       | `linear-gradient(180deg, rgba(18,3,38,0.85) 0%, rgba(3,0,9,0.95) 100%)`                | Text-over-image overlay            | Med        |

### 2.6 Glow Tokens

Glow is the primary elevation/emphasis language — not drop shadows.

| Token               | Value                                                                 | Usage                               |
| ------------------- | --------------------------------------------------------------------- | ----------------------------------- |
| `shadow.glowSm`     | `0 0 12px rgba(224, 64, 243, 0.25)`                                   | Focus rings, hover hints            |
| `shadow.glowMd`     | `0 0 20px rgba(224, 64, 243, 0.35)`                                   | Primary buttons, active cards       |
| `shadow.glowLg`     | `0 0 32px rgba(224, 64, 243, 0.45)`                                   | Hero elements, featured cards       |
| `shadow.lift`       | `0 10px 30px rgba(0, 0, 0, 0.55)`                                     | Modals, popovers (subtle dark lift) |
| `shadow.textGlowSm` | `0 0 6px rgba(224, 64, 243, 0.5)`                                     | Neon text hover/emphasis            |
| `shadow.textGlowMd` | `0 0 12px rgba(224, 64, 243, 0.5), 0 0 24px rgba(224, 64, 243, 0.25)` | Display/hero neon text              |

**Do:** Reserve `glowMd`/`glowLg` for primary actions, focused states, featured elements.

**Don't:** Apply glow to every element — it destroys hierarchy.

### 2.7 Selection Colors

Background: `neonPurple`, text: `purpleInk`.

---

## 3. Accessibility

### 3.1 Contrast Checks (WCAG AA)

| Foreground                  | Background             | Ratio | AA Normal (>=4.5) | AA Large (>=3.0) |
| --------------------------- | ---------------------- | ----: | :---------------: | :--------------: |
| `#F3E9FF` (text primary)    | `#030009` (bg)         | 17.77 |       Pass        |       Pass       |
| `#CBB7E6` (text secondary)  | `#030009` (bg)         | 11.37 |       Pass        |       Pass       |
| `#8B6BB2` (text muted)      | `#030009` (bg)         |  4.81 |       Pass        |       Pass       |
| `#DC4ADF` (neon purple)     | `#030009` (bg)         |  6.04 |       Pass        |       Pass       |
| `#030009` (on-primary text) | `#DC4ADF` (primary bg) |  6.04 |       Pass        |       Pass       |
| `#F3E9FF` (text primary)    | `#0B0117` (surface.1)  | ~15.2 |       Pass        |       Pass       |
| `#CBB7E6` (text secondary)  | `#0B0117` (surface.1)  |  ~9.7 |       Pass        |       Pass       |
| `#8B6BB2` (text muted)      | `#0B0117` (surface.1)  |  ~4.1 |    Borderline     |       Pass       |
| `#DC4ADF` (neon purple)     | `#0B0117` (surface.1)  |  ~5.2 |       Pass        |       Pass       |

### 3.2 Boundary Clarity Rule

`darkOrchid` (#2D084C) on `purpleInk` (#030009) is intentionally low-contrast (aesthetic) but
insufficient as the sole affordance for inputs/focusable elements.

**Rule:** Interactive elements must always provide at least one of:

1. Focus ring (2px) in `hotMagenta`
2. Glow cue (`glowSm`) on hover/focus
3. Stronger border using `duskLavender`

### 3.3 General Rules

- Focus indicators must meet 3:1 contrast against adjacent colors
- Glow is decorative and must never be the sole indicator of state change — always pair with a solid
  color or border change
- Never use `text.muted` for essential/actionable content — reserve for timestamps, captions,
  disabled labels
- Minimum font size: 12px (caption). Nothing smaller

---

## 4. Typography System

### 4.1 Font Selection

Exact UI type is not visible in the image; the CRT/terminal/hacker directive drives selection.

| Role               | Font                                                                                                 | Alternatives                    | Confidence |
| ------------------ | ---------------------------------------------------------------------------------------------------- | ------------------------------- | ---------- |
| **Primary (UI)**   | IBM Plex Mono                                                                                        | JetBrains Mono, Share Tech Mono | Med        |
| **Display (hero)** | VT323                                                                                                | Share Tech Mono, Press Start 2P | Med        |
| **Fallback stack** | `ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace` | —                               | High       |

**Do:** Keep the system mono-first to maintain terminal credibility.

**Don't:** Mix multiple stylistic families (serif + grotesk + mono) in the same UI.

### 4.2 Type Scale

Base: 16px. All sizes in px for the spec; implementations should convert to rem as needed.

| Token      | Family  | Weight | Size | Line Height | Letter Spacing | Notes                                     |
| ---------- | ------- | -----: | ---: | ----------: | -------------: | ----------------------------------------- |
| `display`  | display |    400 | 56px |        64px |         0.02em | Use with `textGlowMd`                     |
| `h1`       | mono    |    600 | 40px |        48px |         0.01em |                                           |
| `h2`       | mono    |    600 | 32px |        40px |         0.01em |                                           |
| `h3`       | mono    |    600 | 24px |        32px |              0 |                                           |
| `h4`       | mono    |    600 | 20px |        28px |              0 |                                           |
| `body`     | mono    |    400 | 16px |        24px |              0 |                                           |
| `small`    | mono    |    400 | 14px |        20px |              0 |                                           |
| `caption`  | mono    |    400 | 12px |        16px |         0.01em | Color: `text.muted`                       |
| `button`   | mono    |    600 | 14px |        16px |         0.06em | UPPERCASE                                 |
| `overline` | mono    |    600 | 12px |        16px |         0.12em | UPPERCASE, color: `accent.primary`        |
| `code`     | mono    |    400 | 14px |        20px |              0 | BG: `surface.2`, 1px border, 16px padding |

### 4.3 Text Rules

- **Line length:** target 60–72ch for body text
- **Paragraph spacing:** 0.75em–1.0em
- **Heading spacing:** ~1.5em top margin, ~0.5em bottom margin
- **Links:** underlined by default, `accent.primary` color; glow on hover/focus
- **Strong:** weight 700, color `accent.alt` or `text.primary` (context-dependent)
- **Emphasis:** italic, same color as parent
- **Code blocks:** `surface.2` background, `border.subtle`, padding `spacing.4`

---

## 5. Layout & Spacing

### 5.1 Spacing Scale (4px base)

| Token       | Value |
| ----------- | ----: |
| `spacing.0` |     0 |
| `spacing.1` |   4px |
| `spacing.2` |   8px |
| `spacing.3` |  12px |
| `spacing.4` |  16px |
| `spacing.5` |  24px |
| `spacing.6` |  32px |
| `spacing.7` |  48px |
| `spacing.8` |  64px |

**Defaults:** Component padding: `spacing.4` (16px). Card padding: `spacing.5` (24px). Section
spacing: `spacing.7`–`spacing.8` (48–64px).

### 5.2 Grid & Containers

_Assumption (Med confidence)_

| Property  | Desktop | Tablet | Mobile |
| --------- | ------: | -----: | -----: |
| Max width |  1280px |  fluid |  fluid |
| Columns   |      12 |      8 |      4 |
| Gutters   |    32px |   24px |   16px |

**Breakpoints:**

| Token            |  Value |
| ---------------- | -----: |
| `breakpoint.xs`  |  360px |
| `breakpoint.md`  |  768px |
| `breakpoint.lg`  | 1024px |
| `breakpoint.xl`  | 1280px |
| `breakpoint.xxl` | 1536px |

### 5.3 Radius Scale

| Token         |  Value | Usage                                               |
| ------------- | -----: | --------------------------------------------------- |
| `radius.0`    |    0px | Terminal-sharp elements (default for dividers, nav) |
| `radius.1`    |    4px | Inputs, chips, small interactive elements           |
| `radius.2`    |    8px | Buttons                                             |
| `radius.3`    |   12px | Cards, modals                                       |
| `radius.4`    |   16px | Hero containers, large panels                       |
| `radius.pill` | 9999px | Badges, tags, pills                                 |

**Note:** The terminal aesthetic favors sharp corners. Use `radius.0`–`radius.1` by default. Reserve
larger radii for containers that need visual softness.

### 5.4 Border Widths

| Token              | Value | Usage                               |
| ------------------ | ----: | ----------------------------------- |
| `border.hairline`  |   1px | Default borders, dividers           |
| `border.focusRing` |   2px | Focus states, active borders        |
| `border.heavy`     |   3px | Decorative — alert left-bar accents |

---

## 6. Iconography & Imagery

### Iconography

_Assumption (Med confidence):_ Inferred from the holographic wireframe globe in the source image.

- **Style:** Outline only, geometric, minimal detail, 1.5–2px strokes
- **Color:** `text.secondary` default; tint with `accent.primary` only on hover/focus/active
- **Glow:** Apply `glowSm` via `filter: drop-shadow()` on hover/active only
- **Recommended sets:** Lucide (stroke-based, MIT), Phosphor (thin variant)

**Do:** Keep icons monochrome by default; state drives color.

**Don't:** Use multi-color filled icon sets, rounded/friendly styles, or illustrative icons that
compete with neon.

### Imagery

- **Style:** Dark, atmospheric, high-contrast cyberpunk — rain reflections, neon signage, fog/haze,
  industrial textures
- **Color treatment:** Desaturate, apply purple/violet monochrome grading
- **Overlay:** Always apply `gradient.overlay` or `gradient.bgHaze` over photography to preserve
  text legibility
- **Grain/noise:** 2–4% opacity noise overlay for texture (optional)
- **Aspect ratios:** 16:9 hero, 4:3 cards, 1:1 thumbnails

**Do:** Add overlay + gradient mask behind text-heavy areas.

**Don't:** Place body text directly on bright neon clusters without overlay. Don't use
bright/warm/saturated stock photography without color treatment.

---

## 7. Components (Spec-Level)

All specs reference role tokens. Implementations should resolve tokens, not hard-code hex values.

### 7.1 Buttons

#### Primary (Filled)

| Property     | Value                                        |
| ------------ | -------------------------------------------- |
| BG           | `color.action.primary.bg`                    |
| FG           | `color.action.primary.fg`                    |
| Radius       | `radius.2`                                   |
| Padding (md) | `spacing.3` vertical, `spacing.4` horizontal |
| Shadow       | `shadow.glowMd`                              |

**Sizes:**

| Size | Padding   | Font           | Min Height |
| ---- | --------- | -------------- | ---------- |
| sm   | 8px 12px  | caption (12px) | 32px       |
| md   | 12px 16px | button (14px)  | 40px       |
| lg   | 16px 24px | body (16px)    | 48px       |

**States:**

| State    | Change                                                       |
| -------- | ------------------------------------------------------------ |
| Hover    | bg → `action.primary.bgHover`, shadow → `glowLg`             |
| Active   | slight darken (mix bg toward `purpleInk`), remove hover lift |
| Focus    | 2px ring `action.primary.focus` + `glowSm`                   |
| Disabled | opacity 0.4, remove glow, cursor not-allowed                 |

**Do:** Use exactly one primary button per view when possible.

**Don't:** Present multiple competing primary actions.

#### Secondary (Outline)

| Property | Value                                           |
| -------- | ----------------------------------------------- |
| BG       | transparent                                     |
| Border   | 1px `color.action.secondary.fg`                 |
| FG       | `color.action.secondary.fg`                     |
| Hover    | bg tinted `action.secondary.bgHover` + `glowSm` |
| Disabled | opacity 0.4, no glow                            |

#### Tertiary (Ghost)

| Property | Value                                       |
| -------- | ------------------------------------------- |
| BG       | transparent                                 |
| Border   | none                                        |
| FG       | `color.text.primary`                        |
| Hover    | fg → `accent.primary`, underline + `glowSm` |

### 7.2 Inputs (Text / Textarea / Select)

| Property    | Default                 | Hover               | Focus                | Error                   | Disabled        |
| ----------- | ----------------------- | ------------------- | -------------------- | ----------------------- | --------------- |
| BG          | `surface.2`             | `surface.2`         | `surface.2`          | `surface.2`             | `surface.1`     |
| Border      | 1px `border.subtle`     | 1px `border.strong` | 2px `accent.primary` | 2px `semantic.error`    | 1px `surface.2` |
| Text        | `text.primary`          | `text.primary`      | `text.primary`       | `text.primary`          | `text.muted`    |
| Placeholder | `text.secondary` at 60% | —                   | —                    | —                       | `text.muted`    |
| Shadow      | none                    | none                | `glowSm`             | `0 0 12px` error at 25% | none            |

- **Padding:** `spacing.3` vertical, `spacing.4` horizontal
- **Min height:** 40px
- **Radius:** `radius.1`
- **Label:** use `overline` style above input
- **Helper text:** `caption` style below input

**Rule:** Inputs must not rely on subtle border alone; focus ring is mandatory.

### 7.3 Links

| State   | Color            | Decoration | Effect       |
| ------- | ---------------- | ---------- | ------------ |
| Default | `accent.primary` | underline  | —            |
| Hover   | `accent.alt`     | underline  | `textGlowSm` |
| Active  | `deepViolet`     | underline  | —            |
| Visited | `deepViolet`     | none       | —            |
| Focus   | `accent.primary` | underline  | focus ring   |

### 7.4 Cards

| Variant             | BG          | Border               | Shadow          | Radius     |
| ------------------- | ----------- | -------------------- | --------------- | ---------- |
| Default             | `surface.1` | 1px `border.subtle`  | none            | `radius.3` |
| Raised              | `surface.2` | 1px `border.subtle`  | `shadow.lift`   | `radius.3` |
| Featured            | `surface.1` | 1px `accent.primary` | `shadow.glowSm` | `radius.3` |
| Interactive (hover) | `surface.2` | 1px `border.strong`  | `shadow.lift`   | `radius.3` |

- **Padding:** `spacing.5` (24px)
- **Internal spacing:** `spacing.3`–`spacing.4` between child elements

### 7.5 Navigation

**Header:**

| Property      | Value                                                                   |
| ------------- | ----------------------------------------------------------------------- |
| Height        | 64px                                                                    |
| BG            | `surface.1` (optionally translucent with `backdrop-filter: blur(12px)`) |
| Border bottom | 1px `border.subtle`                                                     |
| Active link   | `accent.primary` + bottom 2px indicator                                 |
| Hover link    | `accent.alt` + `textGlowSm`                                             |

**Mobile:** Full-screen drawer, bg `surface.2`, overlay dark veil. Hamburger icon: 3 lines in
`text.primary`, animates to X.

### 7.6 Badges / Tags

| Property | Value                                                  |
| -------- | ------------------------------------------------------ |
| BG       | `neonPurple` at 10% opacity (or semantic color at 10%) |
| Border   | 1px `neonPurple` (or semantic color)                   |
| Text     | `accent.alt` (or semantic color)                       |
| Radius   | `radius.pill`                                          |
| Padding  | 4px 10px                                               |
| Font     | `overline`                                             |

Semantic variants (success/warning/error/info): same pattern, swap accent for semantic token.

### 7.7 Alerts / Toasts

_Assumption (Low confidence):_ Not visible in source.

| Property    | Value                                      |
| ----------- | ------------------------------------------ |
| BG          | `surface.2`                                |
| Left border | 3px in semantic color                      |
| Radius      | `radius.3`                                 |
| Padding     | `spacing.4`                                |
| Title       | `text.primary`, `h4` or `small` weight 600 |
| Body        | `text.secondary`, `small`                  |
| Icon        | Semantic color                             |

### 7.8 Modal / Dialog

| Property     | Value                                                                           |
| ------------ | ------------------------------------------------------------------------------- |
| Backdrop     | `purpleInk` at 80% + `backdrop-filter: blur(8px)`                               |
| Container BG | `surface.2`                                                                     |
| Border       | 1px `border.subtle`                                                             |
| Shadow       | `shadow.lift`                                                                   |
| Radius       | `radius.3`                                                                      |
| Max widths   | sm: 480px, md: 640px, lg: 960px                                                 |
| Padding      | `spacing.6` (32px)                                                              |
| Close button | Top-right, ghost style, X icon in `text.secondary`                              |
| Motion       | Backdrop fade `duration.modal`, container scale(0.95→1) + fade `duration.modal` |
| Focus trap   | Required, visible focus ring                                                    |

---

## 8. Motion

_Assumption (Med confidence):_ No motion visible in source. Proposed to match terminal/cyberpunk
aesthetic — snappy, deliberate, not bouncy.

### 8.1 Duration Tokens

| Token          | Value | Usage                                    |
| -------------- | ----- | ---------------------------------------- |
| `motion.fast`  | 120ms | Color transitions, opacity micro-changes |
| `motion.base`  | 160ms | Most interactions (hover, focus, border) |
| `motion.modal` | 220ms | Modals, drawers, page transitions        |

### 8.2 Easing

| Token                    | Value                            |
| ------------------------ | -------------------------------- |
| `motion.easing.standard` | `cubic-bezier(0.2, 0.8, 0.2, 1)` |

### 8.3 Interaction Patterns

- **Hover:** glow intensity ramp + optional `translateY(-1px)` lift
- **Focus:** instant ring appearance (no transition on ring itself, glow can transition)
- **Modal enter:** fade backdrop + scale container from 0.95→1
- **Toast enter:** slide from edge + fade

### 8.4 CRT Effects (Optional, Use Sparingly)

- **Scanlines:** Repeating 2px horizontal lines at 2–3% opacity via pseudo-element
- **Flicker:** Subtle opacity oscillation (0.97–1.0) on terminal-style elements, ~4s cycle
- **Typewriter:** Character-by-character reveal for hero text, 30–50ms per char
- **Glow pulse:** Shadow intensity oscillation on idle neon elements, ~3s cycle ease-in-out

**Do:** Use one CRT effect per view maximum. They're seasoning, not the meal.

**Don't:** Apply scanlines + flicker + glow pulse simultaneously. Don't use bouncy/springy easing.

---

_Purple City v2.0.0 — Consolidated SoT. All assumptions marked inline with confidence levels._
