# KDE Plasma Desktop Environment

- plasma 6 toggle desktop last walk through desktop
  - https://invent.kde.org/vladz/switch-to-previous-desktop.git

https://bbs.archlinux.org/viewtopic.php?id=293522

- kde tiling window manager
  -   https://github.com/anametologin/krohnkite

install / uninstall

```sh
git clone https://github.com/anametologin/krohnkite.git
make install
make uninstall # to uninstall the script
```

## Open app automatically on a desktop

To have a given application automatically open on virtual desktop 4 after you log into Arch Linux KDE, you need to combine:

- A KWin (Window Rules) rule that forces the app’s window onto desktop 4.
- An Autostart entry so the application launches at login.

### 1. Create a KWin Window Rule

```sh
kwriteconfig6 --file ~/.config/kwinrulesrc \
  --group "Window-specific settings for myapp" \
  --key wmclass myapp \
  --key desktop 4 \
  --key desktoprule 2
```

### 2. Configure Autostart


Drop or create a `.desktop` in `~/.config/autostart/` yourself. For example, `~/.config/autostart/myapp.desktop`:

```ini
[Desktop Entry]
Type=Application
Exec=/usr/bin/myapp
Hidden=false
X-GNOME-Autostart-enabled=true
```
