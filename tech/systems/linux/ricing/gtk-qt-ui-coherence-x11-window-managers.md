# GTK/Qt UI Coherence for X11 Window Managers

Coherent UI setup for X11 window-manager sessions such as `dwm`, `bspwm`, `i3`, and similar minimal
stacks where no desktop environment settings daemon is applying theme defaults for you.

This guide covers:

- GTK apps (`Thunar`, `lxappearance`, many dialogs)
- Qt apps (`qt5ct` / `qt6ct` managed)
- browser upload/save dialogs through XDG portals
- color-picking workflow with `gpick`

This guide uses a discover-then-persist workflow:

1. Use GUI tools (`lxappearance`, `qt5ct`, `qt6ct`) to choose values.
2. Persist those values in your user configuration.
3. Relogin to verify the session picks them up cleanly.

Optional palette reference:
[Purple City](colors/purple-city-dark-theme-color-system-specification.md)

---

## 1) Scope and Success Criteria

### Scope

- Session type: any X11 WM stack without GNOME/KDE settings integration
- Core tools: `lxappearance`, `qt5ct`, `qt6ct`, `gpick`
- Supporting pieces: `xsettingsd`, `xdg-desktop-portal`, `xdg-desktop-portal-gtk`

### Success criteria

- GTK and Qt apps use the same icon theme, cursor theme, and font.
- File chooser dialogs use a consistent GTK-backed path.
- Settings survive reboot/login via your persistent per-user configuration.

---

## 2) Why UI Diverges on a WM Stack

Without a full desktop environment, theming comes from multiple layers:

- GTK settings files (`~/.config/gtk-3.0/settings.ini`, `~/.gtkrc-2.0`, and optionally GTK4
  settings)
- Qt platform theme plugin (`QT_QPA_PLATFORMTHEME` with `qt5ct` / `qt6ct`)
- XSETTINGS (`xsettingsd`) for DPI, font, and rendering hints
- XDG Desktop Portal backend selection for toolkit-neutral file chooser flows

That split is normal on standalone X11 WM setups. The fix is to configure each layer deliberately
and keep one canonical set of values.

---

## 3) Preflight Checks

Run these checks before changing anything.

Generic package requirements:

- `lxappearance`
- `qt5ct`
- `qt6ct`
- `gpick`
- `xsettingsd`
- `xdg-desktop-portal`
- `xdg-desktop-portal-gtk`
- `thunar` (or another GTK file manager/dialog source for testing)
- `orchis-theme` (GTK theme)
- `papirus-icon-theme` (icon theme)
- `inter-font` (UI font)
- `bibata-cursor-theme` (AUR — cursor theme)
- `papirus-folders` (AUR — folder color customization)

Arch example:

```bash
pacman -Q lxappearance qt5ct qt6ct gpick xsettingsd xdg-desktop-portal xdg-desktop-portal-gtk thunar orchis-theme papirus-icon-theme inter-font
```

Session checks:

```bash
pgrep -ax xsettingsd
pgrep -ax thunar
systemctl --user status xdg-desktop-portal.service xdg-desktop-portal-gtk.service --no-pager
```

Confirm your X11 session startup path launches the relevant daemons:

```bash
rg -n "xsettingsd|thunar --daemon|dbus-update-activation-environment" ~/.xinitrc ~/.xprofile ~/.config 2>/dev/null
```

If packages are missing on Arch, install the concrete package set for your host:

```bash
sudo pacman -Syu --needed lxappearance qt5ct qt6ct gpick xsettingsd \
  xdg-desktop-portal xdg-desktop-portal-gtk thunar orchis-theme \
  papirus-icon-theme inter-font
```

---

## 4) Set Portal Backend for Dialog Coherence

For standalone WM sessions, set the GTK portal backend explicitly.

Create:

```ini
# ~/.config/xdg-desktop-portal/portals.conf
[preferred]
default=gtk
org.freedesktop.impl.portal.FileChooser=gtk
```

Then restart portal services:

```bash
systemctl --user daemon-reload
systemctl --user restart xdg-desktop-portal.service xdg-desktop-portal-gtk.service
```

Validate:

```bash
systemctl --user status xdg-desktop-portal.service xdg-desktop-portal-gtk.service --no-pager
journalctl --user -u xdg-desktop-portal -b --no-pager | tail -n 80
```

---

## 5) Install Theme Assets

### 5.1 Theme selection rationale

Purple City palette reference:
[Purple City](colors/purple-city-dark-theme-color-system-specification.md)

| Role         | Package               | Source | Value to set                |
| ------------ | --------------------- | ------ | --------------------------- |
| GTK theme    | `orchis-theme`        | pacman | `Orchis-Purple-Dark`        |
| Icon theme   | `papirus-icon-theme`  | pacman | `Papirus-Dark`              |
| Folder color | `papirus-folders`     | AUR    | `violet` (applied in-place) |
| Cursor theme | `bibata-cursor-theme` | AUR    | `Bibata-Modern-Classic`     |
| UI font      | `inter-font`          | pacman | `Inter 10`                  |

**Why Orchis-Purple-Dark:**

- Polished Material Design GTK2/3/4 theme with a dedicated purple accent variant.
- Available directly from `extra` — no AUR build required.
- Stock dark backgrounds sit around `#303030` (grey), not matching the near-black `#010005` of
  Purple City. For exact palette fidelity you would fork and patch the SCSS variables, but
  out-of-the-box it is the closest purple-accented dark theme with maintained Arch packaging.

**Alternatives considered:**

- `Catppuccin-Mocha-Standard-Mauve-Dark` (`catppuccin-gtk-theme-mocha` AUR) — Mauve accent `#cba6f7`
  is close to Purple City `#C89DEA`, but base background is blue-grey `#1e1e2e`, not purple-tinted.
  Repo is archived.
- `Sweet-Dark` (`sweet-gtk-theme-dark` AUR) — neon purple gradients, but blue-grey backgrounds and
  reported GTK2/3 rendering bugs.
- `Adwaita-dark` — safe baseline but no purple accent at all.

### 5.2 Install packages

Pacman:

```bash
sudo pacman -S --needed orchis-theme papirus-icon-theme inter-font
```

AUR (use your AUR helper):

```bash
paru -S --needed bibata-cursor-theme papirus-folders
```

### 5.3 Set Papirus folder color

After installing `papirus-folders`, apply violet folders:

```bash
papirus-folders -C violet --theme Papirus-Dark
```

Verify:

```bash
papirus-folders -l --theme Papirus-Dark
```

---

## 6) Configure GTK with `lxappearance`

Launch:

```bash
lxappearance
```

Set these values:

- Widget theme: `Orchis-Purple-Dark`
- Icon theme: `Papirus-Dark`
- Cursor theme: `Bibata-Modern-Classic`
- Default font: `Inter 10`

Confirm the saved files:

```bash
sed -n '1,120p' ~/.config/gtk-3.0/settings.ini
sed -n '1,120p' ~/.gtkrc-2.0
```

For GTK4-capable apps, keep a matching `~/.config/gtk-4.0/settings.ini`.

---

## 7) Configure Qt with `qt5ct` and `qt6ct`

### 7.1 Set the Qt platform theme env

Set once in your user environment layer:

```ini
# ~/.config/environment.d/60-qt-platform-theme.conf
QT_QPA_PLATFORMTHEME=qt5ct:qt6ct
```

Reload it for the current user manager or relogin:

```bash
set -a
. ~/.config/environment.d/60-qt-platform-theme.conf
set +a
systemctl --user import-environment QT_QPA_PLATFORMTHEME
echo "$QT_QPA_PLATFORMTHEME"
```

### 7.2 Configure both generations

Run:

```bash
qt5ct
qt6ct
```

Set both to the same:

- icon theme
- font
- dark/light strategy
- any palette overrides you intentionally want

Confirm the saved files:

```bash
sed -n '1,200p' ~/.config/qt5ct/qt5ct.conf
sed -n '1,200p' ~/.config/qt6ct/qt6ct.conf
```

---

## 8) `xsettingsd` Consistency Check

Your X11 session should start `xsettingsd` from whichever entrypoint you use: `~/.xinitrc`, a
display-manager session script, or a WM autostart hook.

Verify applied values:

```bash
xsettingsd --dump | sed -n '1,120p'
```

The repo stores XSETTINGS content here:

- `~/.config/xsettingsd/xsettingsd.conf`

Upstream `xsettingsd` defaults to `~/.xsettingsd`. If values are not applied, ensure one of:

1. Launch `xsettingsd` with `-c ~/.config/xsettingsd/xsettingsd.conf`
2. Provide a compatibility symlink

```bash
ln -sf ~/.config/xsettingsd/xsettingsd.conf ~/.xsettingsd
```

---

## 9) Browser Upload/Save Dialog Behavior

After portal configuration, most browsers should use the GTK-backed chooser path. If a
Chromium-family browser still shows inconsistent dialogs, test forcing the portal path in whatever
launcher or environment wrapper starts the browser:

```bash
export GTK_USE_PORTAL=1
```

Restart the browser fully and test upload/save again.

---

## 10) Optional Palette Workflow with `gpick`

Use `gpick` to sample colors from wallpapers or UI surfaces, then map them back to a constrained
palette instead of inventing per-app accents.

If you want a predefined palette, Purple City is documented here:

- [Purple City](colors/purple-city-dark-theme-color-system-specification.md)

Recommended flow:

1. Open `gpick` and sample accents/backgrounds.
2. Compare sampled values against your palette tokens.
3. Keep one canonical accent plus one canonical surface set.
4. Re-apply those choices in GTK and Qt tools.

---

## 11) Persist User Configuration

After you confirm the visuals, keep the relevant files under your normal user-configuration
management:

- `~/.config/gtk-3.0/settings.ini`
- `~/.config/gtk-4.0/settings.ini`, if used
- `~/.gtkrc-2.0`
- `~/.config/qt5ct/qt5ct.conf`
- `~/.config/qt6ct/qt6ct.conf`
- `~/.config/xdg-desktop-portal/portals.conf`
- `~/.config/environment.d/60-qt-platform-theme.conf`

If your browser launcher environment needs `GTK_USE_PORTAL=1`, persist that with the same mechanism
you use for application launchers or session environment files.

---

## 12) Policy: Dotfiles vs System Files

Use dotfiles for:

- per-user theming
- GTK/Qt appearance
- browser env overrides
- portal preferences for your user session

Use `/etc` only when:

- all users must share the same behavior
- you are configuring display-manager or root-session behavior
- you intentionally want the policy outside home-directory control

Use GUI tools only for discovery:

- `lxappearance`, `qt5ct`, and `qt6ct` are selection UIs
- final state should be captured in your persistent configuration
- if a change is not captured, treat it as temporary

---

## 13) Verification Scenarios

Run these checks after applying the configuration and relogin:

```bash
echo "$QT_QPA_PLATFORMTHEME"                         # expect: qt5ct:qt6ct
pgrep -ax xsettingsd                                # running
systemctl --user is-active xdg-desktop-portal.service xdg-desktop-portal-gtk.service
```

Manual checks:

1. Open `thunar` or another GTK file manager and verify theme, icon, cursor, and font.
2. Open one Qt5 app and one Qt6 app and verify font, icons, and dark/light alignment.
3. Open a browser and test a file upload dialog.

If any test fails, check sections 4, 7, and 8 in that order.

---

## 14) References (Verified 2026-02-27)

- ArchWiki: Uniform look for Qt and GTK applications
  <https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications>
- ArchWiki raw (includes current `QT_QPA_PLATFORMTHEME=qt5ct:qt6ct` guidance for qt5ct/qt6ct)
  <https://wiki.archlinux.org/index.php?title=Qt&action=raw>
- ArchWiki: XDG Desktop Portal <https://wiki.archlinux.org/title/XDG_Desktop_Portal>
- ArchWiki raw (portal backend/config examples)
  <https://wiki.archlinux.org/index.php?title=XDG_Desktop_Portal&action=raw>
- XDG Desktop Portal docs: `portals.conf(5)`
  <https://flatpak.github.io/xdg-desktop-portal/docs/portals.conf.html>
- GTK settings reference (`GtkSettings`) <https://docs.gtk.org/gtk3/class.Settings.html>
  <https://docs.gtk.org/gtk4/class.Settings.html>
- `xsettingsd(1)` manpage (default config path and options)
  <https://manpages.debian.org/testing/xsettingsd/xsettingsd.1.en.html>
