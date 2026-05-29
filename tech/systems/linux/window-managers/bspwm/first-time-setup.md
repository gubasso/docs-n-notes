# bspwm First-Time Setup

Minimal steps to get bspwm running after a fresh Arch install.

**Reference:** [Arch Wiki: bspwm](https://wiki.archlinux.org/title/Bspwm)

---

## Prerequisites

- X11 server installed (`xorg-server`, `xorg-xinit`)
- bspwm and sxhkd installed
- Terminal emulator installed (kitty recommended)

---

## Configuration Files

bspwm requires two config files:

- `~/.config/bspwm/bspwmrc` - WM configuration (shell script, must be executable)
- `~/.config/sxhkd/sxhkdrc` - Keybindings

### Option A: Using Existing Dotfiles

If dotfiles are already cloned and stowed:

```bash
# Verify configs exist
ls -la ~/.config/bspwm/bspwmrc
ls -la ~/.config/sxhkd/sxhkdrc
ls -la ~/.xinitrc
```

### Option B: Starting Fresh (Arch Wiki Examples)

Copy example configs from package:

```bash
install -Dm755 /usr/share/doc/bspwm/examples/bspwmrc ~/.config/bspwm/bspwmrc
install -Dm644 /usr/share/doc/bspwm/examples/sxhkdrc ~/.config/sxhkd/sxhkdrc
```

---

## Critical Steps

### 1. Ensure bspwmrc is Executable

```bash
chmod +x ~/.config/bspwm/bspwmrc
```

bspwm will fail silently if the config isn't executable.

### 2. Configure Terminal Emulator

Edit `~/.config/sxhkd/sxhkdrc` and set your terminal:

```bash
# Default is urxvt, change to your terminal
super + Return
    kitty
```

### 3. Ensure sxhkd Starts in bspwmrc

sxhkd (the hotkey daemon) must be started from bspwmrc, not xinitrc.

Edit `~/.config/bspwm/bspwmrc`:

```bash
nvim ~/.config/bspwm/bspwmrc
```

Verify sxhkd is started near the top of the file. The example config includes a simple `sxhkd &`,
but use this pattern to prevent duplicates on reload:

```bash
pgrep -x sxhkd > /dev/null || sxhkd &
```

If missing, add it after the initial comments/shebang.

### 4. Create ~/.xinitrc (if missing)

Copy the system template as a starting point:

```bash
cp /etc/X11/xinit/xinitrc ~/.xinitrc
```

Edit to replace the default WM (twm/xclock/xterm) at the end with bspwm:

```bash
nvim ~/.xinitrc
```

Remove the last few lines (twm, xclock, xterm) and replace with:

```sh
# Load Xresources (DPI, cursor, colors)
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

# Keyboard: Caps↔Esc swap, US International AltGr dead keys
setxkbmap -layout us -variant altgr-intl -option caps:swapescape

# Start bspwm
exec bspwm
```

**Note:** Xresources must be loaded _before_ starting bspwm for apps to inherit settings like
`Xft.dpi`.

**What belongs where:**

| File                      | Purpose                                                                           |
| ------------------------- | --------------------------------------------------------------------------------- |
| `~/.xinitrc`              | X server init: source system scripts, load Xresources, keyboard layout, `exec` WM |
| `~/.config/bspwm/bspwmrc` | WM config: start sxhkd, polybar, picom, set monitors, bspc rules                  |

---

## First Start

```bash
startx
```

---

## Verify

After X starts:

```bash
# Check sxhkd is running
pgrep sxhkd

# Test terminal keybind (default: super + Return)
# Should open terminal

# Test window focus (super + h/j/k/l)
```

---

## Troubleshooting

### Black Screen

1. Check bspwmrc permissions: `ls -la ~/.config/bspwm/bspwmrc`
2. Check sxhkd is running: `pgrep sxhkd`
3. Try from TTY: `Ctrl+Alt+F2`, login, check `~/.local/share/xorg/Xorg.0.log`

### No Keybinds

1. Verify sxhkdrc exists: `ls ~/.config/sxhkd/sxhkdrc`
2. Reload sxhkd: `pkill -USR1 -x sxhkd`
3. Check sxhkd log: Run `sxhkd` in terminal to see errors

### X Won't Start

1. Verify X server: `pacman -Q xorg-server xorg-xinit`
2. Check xinitrc: `cat ~/.xinitrc`
3. Check X log: `cat ~/.local/share/xorg/Xorg.0.log | grep EE`

---

## Next Steps

- [setup-arch-linux](setup-arch-linux.md) - Complete bspwm stack reference
