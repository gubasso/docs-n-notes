# Arch Linux + BSPWM

## Complete bspwm Stack Checklist for Arch + NVIDIA

### Core Window Management

| Component      | Package | Purpose                           |
| -------------- | ------- | --------------------------------- |
| Window Manager | `bspwm` | Tiling WM                         |
| Hotkey Daemon  | `sxhkd` | Keybindings                       |
| Compositor     | `picom` | Transparency, shadows, animations |

### Display & Session

| Component          | Package                  | Purpose                              |
| ------------------ | ------------------------ | ------------------------------------ |
| Display Manager    | `ly` or `sddm`           | Login screen (or skip, use `startx`) |
| Screen Locker      | `betterlockscreen` (AUR) | Lock screen with blur                |
| Wallpaper          | `feh` or `nitrogen`      | Set wallpaper                        |
| Monitor Management | `autorandr`              | Auto-detect dock/undock              |

### Bar & Launcher

| Component    | Package                    | Purpose                                 |
| ------------ | -------------------------- | --------------------------------------- |
| Status Bar   | `polybar`                  | Most riceable bar                       |
| App Launcher | `rofi`                     | Application launcher, dmenu replacement |
| Power Menu   | `rofi-power-menu` (script) | Shutdown/reboot/lock menu               |

### Terminal & Shell

| Component | Package    | Purpose                       |
| --------- | ---------- | ----------------------------- |
| Terminal  | `kitty`    | You already use it            |
| Shell     | `bash`     | You already use it            |
| Prompt    | `starship` | Cross-shell prompt (optional) |

### Notifications

| Component           | Package | Purpose                    |
| ------------------- | ------- | -------------------------- |
| Notification Daemon | `dunst` | Customizable notifications |

### File Management

| Component        | Package                    | Purpose                                 |
| ---------------- | -------------------------- | --------------------------------------- |
| GUI File Manager | `thunar` + `thunar-volman` | Lightweight, auto-mount                 |
| TUI File Manager | `ranger`, `lf`, or `yazi`  | Terminal file browser (user preference) |
| Trash            | `glib2` (provides `gio`)   | Trash support                           |

### Media & Audio

| Component      | Package                                       | Purpose                                   |
| -------------- | --------------------------------------------- | ----------------------------------------- |
| Audio Server   | `pipewire` + `pipewire-pulse` + `wireplumber` | Modern audio                              |
| Volume Control | `pwvucontrol`                                 | PipeWire-native GUI mixer                 |
| Volume CLI     | `wpctl`                                       | PipeWire-native CLI (part of wireplumber) |

### Screenshots & Recording

| Component        | Package                         | Purpose                |
| ---------------- | ------------------------------- | ---------------------- |
| Screenshot       | `flameshot` or `maim` + `xclip` | Screen capture         |
| Screen Recording | `obs-studio` or `ffmpeg`        | Recording              |
| Color Picker     | `gpick` or `xcolor` (AUR)       | Pick colors for ricing |

### System Tray & Applets

| Component         | Package                         | Purpose                               |
| ----------------- | ------------------------------- | ------------------------------------- |
| Network Applet    | `network-manager-applet`        | nm-applet for tray                    |
| Bluetooth         | `blueman`                       | Bluetooth GUI                         |
| Clipboard Manager | `greenclip` (AUR) or `clipmenu` | Optional: clipboard history with rofi |

### Laptop/ThinkPad Specific

| Component        | Package         | Purpose                |
| ---------------- | --------------- | ---------------------- |
| Brightness       | `brightnessctl` | Backlight control      |
| Power Management | `tlp`           | Battery optimization   |
| Lid/Power Events | `acpid`         | Handle lid close, etc. |

### Theming & Fonts

| Component        | Package                     | Purpose                 |
| ---------------- | --------------------------- | ----------------------- |
| GTK Theme Setter | `lxappearance`              | Set GTK theme           |
| Qt Theme         | `qt5ct` + `qt6ct`           | Qt app theming          |
| Icon Theme       | `papirus-icon-theme`        | Popular icon set        |
| Fonts            | `ttf-jetbrains-mono-nerd`   | Nerd font for bar icons |
| Cursor Theme     | `bibata-cursor-theme` (AUR) | Modern cursor           |

### NVIDIA Specific

| Component         | Package                   | Purpose            |
| ----------------- | ------------------------- | ------------------ |
| Driver            | `nvidia` + `nvidia-utils` | Proprietary driver |
| Settings          | `nvidia-settings`         | GUI config         |
| Prime (if hybrid) | `nvidia-prime`            | Optimus support    |

---

## Dotfiles to Steal From

These are well-known, well-documented bspwm rices:

| Repo                                                                  | Style                        | Notes                 |
| --------------------------------------------------------------------- | ---------------------------- | --------------------- |
| [gh0stzk/dotfiles](https://github.com/gh0stzk/dotfiles)               | 12+ themes, installer script | Most popular, turnkey |
| [adi1090x/polybar-themes](https://github.com/adi1090x/polybar-themes) | Polybar only                 | Tons of bar styles    |
| [Axarva/dotfiles-2.0](https://github.com/Axarva/dotfiles-2.0)         | Cozy aesthetic               | Popular on r/unixporn |
| [elenapan/dotfiles](https://github.com/elenapan/dotfiles)             | Soft, pastel                 | Very polished         |
| [siduck/dotfiles](https://github.com/siduck/dotfiles)                 | Minimal                      | NvChad creator        |

**gh0stzk** is probably your best starting point - it includes an install script and 12 switchable
themes.

---

## One-Liner Install (Core Stack)

```bash
# Core
sudo pacman -S bspwm sxhkd picom polybar rofi dunst

# Terminal & shell (you have these)
sudo pacman -S kitty

# Display & wallpaper
sudo pacman -S feh autorandr

# Audio
sudo pacman -S pipewire pipewire-pulse wireplumber pwvucontrol

# Screenshots
sudo pacman -S flameshot maim xclip

# File management
sudo pacman -S thunar thunar-volman ranger

# Laptop
sudo pacman -S brightnessctl tlp acpid

# Theming
sudo pacman -S lxappearance qt5ct papirus-icon-theme

# Fonts (pick one or more)
sudo pacman -S ttf-jetbrains-mono-nerd ttf-firacode-nerd

# Network
sudo pacman -S network-manager-applet

# NVIDIA
sudo pacman -S nvidia nvidia-utils nvidia-settings
```

```bash
# AUR (via yay/paru)
yay -S betterlockscreen bibata-cursor-theme
# Optional: yay -S greenclip  # Clipboard manager
```

---

## Minimal ~/.xinitrc

```bash
#!/bin/sh

# Keyboard layout (adjust as needed)
setxkbmap -layout us

# Start sxhkd (hotkeys)
pgrep -x sxhkd > /dev/null || sxhkd &

# Start picom
picom -b

# Set wallpaper
feh --bg-fill ~/.config/wallpaper.jpg &

# Start polybar
~/.config/polybar/launch.sh &

# Notifications
dunst &

# Network applet
nm-applet &

# Finally, start bspwm
exec bspwm
```

---

## Directory Structure You'll End Up With

```text
~/.config/
├── bspwm/
│   └── bspwmrc           # WM config (shell script)
├── sxhkd/
│   └── sxhkdrc           # Keybindings
├── picom/
│   └── picom.conf        # Compositor
├── polybar/
│   ├── config.ini        # Bar config
│   └── launch.sh         # Bar launcher script
├── rofi/
│   └── config.rasi       # Launcher theme
├── dunst/
│   └── dunstrc           # Notification style
├── kitty/
│   └── kitty.conf        # Terminal config
└── bash/
    └── .bashrc           # Shell config
```

---

## Next Steps

1. Install core packages
2. Clone gh0stzk or another dotfile repo
3. Cherry-pick configs you like
4. Tweak colors/fonts to taste
5. Post to r/unixporn for validation
