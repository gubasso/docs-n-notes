# Migration Cost: bspwm → Hyprland

| Component                 | Transfers?    | Effort                                      |
| ------------------------- | ------------- | ------------------------------------------- |
| **kitty config**          | ✅ Direct     | None                                        |
| **bash config**           | ✅ Direct     | None                                        |
| **neovim config**         | ✅ Direct     | None                                        |
| **Application configs**   | ✅ Direct     | None                                        |
| **Fonts, icons, cursors** | ✅ Direct     | None                                        |
| **GTK themes**            | ✅ Direct     | None                                        |
| **bspwmrc**               | ❌ Rewrite    | `hyprland.conf` (different syntax)          |
| **sxhkdrc**               | ❌ Rewrite    | Bindings in `hyprland.conf`                 |
| **picom**                 | ❌ Not needed | Hyprland has built-in compositor            |
| **polybar**               | ❌ Replace    | waybar (similar concepts, different syntax) |
| **rofi**                  | ⚠ Works       | Or switch to wofi (native)                  |
| **dunst**                 | ⚠ Works       | Or switch to mako (native)                  |
| **flameshot**             | ⚠ Works       | Or switch to grim+slurp                     |
| **feh**                   | ❌ Replace    | hyprpaper or swaybg                         |
| **autorandr**             | ❌ Replace    | hyprctl monitors / kanshi                   |
| **betterlockscreen**      | ❌ Replace    | hyprlock                                    |
| **.Xresources**           | ❌ Not used   | Wayland ignores X resources                 |
| **.xinitrc**              | ❌ Not used   | Different launch method                     |

## Migration Effort Estimate

| Category                       | Percentage |
| ------------------------------ | ---------- |
| Configs that transfer directly | ~60%       |
| Configs needing rewrite        | ~30%       |
| New concepts to learn          | ~10%       |

### What's Actually Hard

1. **Learning Hyprlang syntax** - Different from shell scripts, but well-documented
2. **Waybar config** - Similar to polybar conceptually, different format (JSON-ish)
3. **Monitor management** - hyprctl instead of xrandr (actually easier once learned)
4. **Mental model shift** - Wayland works differently (but you won't notice day-to-day)

### What's Actually Easy

1. **Your core workflow is terminal + neovim** - Zero changes
2. **Keyboard bindings** - Same concepts, different syntax
3. **Hyprland docs are excellent** - Well-maintained wiki
4. **Active community** - Lots of dotfiles to reference

### Migration Strategy (if you decide later)

```bash
# 1. Keep bspwm working, install Hyprland alongside
sudo pacman -S hyprland waybar wofi hyprpaper hyprlock hypridle

# 2. Create ~/.config/hypr/hyprland.conf
#    Start with example config, port keybindings gradually

# 3. Test Hyprland from TTY without breaking bspwm
#    (Don't overwrite .xinitrc, launch Hyprland directly)

# 4. Run both for a week, switch when comfortable
```

### Bottom Line

**Migration cost: Medium (1-2 days of config work)**

Your actual _work_ (terminal, neovim, bash, apps) is unaffected. Only the "window decoration" layer
changes. If you set up bspwm now and want Hyprland later:

- You won't lose anything
- You'll reuse 60%+ of your setup
- The WM configs need rewriting but concepts transfer
- Biggest learning curve: waybar syntax

**My suggestion:** Start with bspwm. If NVIDIA Wayland matures and you get curious, Hyprland is a
weekend project to try.

## My take

I don't mind for "learning curves", "new config ways, and config files"... what I bother is a system
with a bunch of leftwovers (packages, spread config files loose, like when we install KDE or
Gnome)... if I get a polluted system the migration cost that I can not handle is: having a cluttered
system with dirs/files/packages... so the solution for me is to do a fresh distro install

## WM Setups Are Clean (Unlike DEs)

That's a very valid concern, and actually good news here:

| Aspect                  | KDE/GNOME                   | bspwm/Hyprland                |
| ----------------------- | --------------------------- | ----------------------------- |
| Meta-packages           | Pull 200+ deps              | You install explicitly        |
| Hidden configs          | dconf, akonadi, baloo, etc. | ~/.config/appname/            |
| Background services     | Dozens                      | Only what you start           |
| Orphan cleanup          | Nightmare                   | `pacman -Rns $(pacman -Qdtq)` |
| Know what you installed | No                          | Yes                           |

## bspwm → Hyprland: What Actually Changes

### Packages Removed (X11-specific)

```bash
# Clean removal
sudo pacman -Rns bspwm sxhkd picom polybar xorg-server xorg-xinit \
    xorg-xrandr xorg-xsetroot autorandr feh betterlockscreen
```

### Packages Added (Wayland-specific)

```bash
# Hyprland stack
sudo pacman -S hyprland waybar hyprpaper hyprlock hypridle \
    xdg-desktop-portal-hyprland
```

### Packages That Stay (toolkit-agnostic)

```text
kitty, bash, neovim, rofi*, dunst*, thunar, pipewire,
nvidia, fonts, icons, themes, all your actual apps
```

*rofi/dunst work on both, or swap for wofi/mako

### Config Directories

| Directory            | Action                     |
| -------------------- | -------------------------- |
| `~/.config/bspwm/`   | Delete                     |
| `~/.config/sxhkd/`   | Delete                     |
| `~/.config/picom/`   | Delete                     |
| `~/.config/polybar/` | Delete                     |
| `~/.config/hypr/`    | New                        |
| `~/.config/waybar/`  | New                        |
| `~/.Xresources`      | Delete (or keep, harmless) |
| `~/.xinitrc`         | Delete                     |
| Everything else      | Unchanged                  |

## The Clean Migration Path

```bash
# 1. Remove X11/bspwm stack
sudo pacman -Rns bspwm sxhkd picom polybar xorg-server xorg-xinit \
    xorg-xrandr xorg-xsetroot xorg-xset autorandr feh

# 2. Clean orphans
sudo pacman -Rns $(pacman -Qdtq)

# 3. Remove config dirs
rm -rf ~/.config/{bspwm,sxhkd,picom,polybar}
rm -f ~/.Xresources ~/.xinitrc

# 4. Install Hyprland stack
sudo pacman -S hyprland waybar wofi mako hyprpaper hyprlock hypridle \
    xdg-desktop-portal-hyprland grim slurp

# 5. Create new configs
mkdir -p ~/.config/{hypr,waybar,mako}
```

**Result: Zero leftovers, clean system.**

## Why WMs Don't Pollute

1. **No meta-packages** - You choose each component
2. **Explicit configs** - All in `~/.config/appname/`
3. **No dconf/gsettings** - Plain text files
4. **No background daemons** - Only what's in your autostart
5. **Clear dependency chains** - `pacman -Qi package` shows exactly what depends on what

## Comparison to KDE/GNOME Uninstall

```bash
# KDE removal attempt (nightmare)
sudo pacman -Rns plasma-meta kde-applications-meta
# Still left with: akonadi, baloo, kwallet, dozens of kf5-* libs,
# dbus configs, systemd user units, ~/.local/share/akonadi/,
# ~/.config/kde*, ~/.config/plasma*, etc.

# bspwm removal (clean)
sudo pacman -Rns bspwm sxhkd
# Done. That's it. Maybe picom/polybar if you want.
```

## Bottom Line

**bspwm → Hyprland migration is clean IF you track what you install.**

Suggestion: Keep a simple list

```bash
# ~/installed-packages.txt
# X11/bspwm stack
bspwm
sxhkd
picom
polybar
xorg-server
xorg-xinit
...
```

When you migrate, you know exactly what to remove. No fresh install needed.

**The "fresh install requirement" applies to DE migrations (GNOME↔KDE). WM setups are modular by
design - that's the whole point.**
