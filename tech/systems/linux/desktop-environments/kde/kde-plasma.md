# KDE Plasma Desktop Environment

- plasma 6 toggle desktop last walk through desktop
  - <https://invent.kde.org/vladz/switch-to-previous-desktop.git>

<https://bbs.archlinux.org/viewtopic.php?id=293522>

- kde tiling window manager
  - <https://github.com/anametologin/krohnkite>

install / uninstall

```sh
git clone https://github.com/anametologin/krohnkite.git
make install
make uninstall # to uninstall the script
```

## Open app automatically on a desktop

To have a given application automatically open on virtual desktop 4 after you log into KDE, you need
to combine:

- A KWin (Window Rules) rule that forces the app's window onto desktop 4.
- An Autostart entry so the application launches at login.

### 1. Create a KWin Window Rule

#### CLI method

```sh
kwriteconfig6 --file ~/.config/kwinrulesrc \
  --group "Window-specific settings for myapp" \
  --key wmclass myapp \
  --key desktop 4 \
  --key desktoprule 2
```

#### GUI method

1. Launch the application once.
2. **Right-click** its title bar (or press **Alt + F3**) and choose **More Actions → Special
   Application Settings…**
3. In the dialog, go to the **Size & Position** tab, **check** "Desktop", set the rule to **Force**
   (or "Remember"), and select **4** from the dropdown.
4. Click **Apply**. The rule is saved in `~/.config/kwinrulesrc` (e.g. with `desktop=4` and
   `desktoprule=2`)

You can also open the **Window Rules** module directly under **System Settings → Workspace → Window
Management → Window Rules** ([KDE UserBase][kwin-rules])

### 2. Configure Autostart

#### GUI method

1. Open **System Settings → Startup and Shutdown → Autostart** ([KDE UserBase][autostart])
2. Click **Add Program…**, select your application, and confirm. This copies its `.desktop` file
   into `~/.config/autostart/`.
3. Plasma scans `$HOME/.config/autostart/` for `.desktop` files at each login and launches them

#### Manual XDG Autostart

Drop or create a `.desktop` in `~/.config/autostart/` yourself. For example,
`~/.config/autostart/myapp.desktop`:

```ini
[Desktop Entry]
Type=Application
Exec=/usr/bin/myapp
Hidden=false
X-GNOME-Autostart-enabled=true
```

By the **XDG Autostart** spec, entries in `~/.config/autostart` are run automatically on session
start ([Arch Wiki][xdg-autostart])

[kwin-rules]: https://userbase.kde.org/KWin_Rules "KWin Rules - KDE UserBase Wiki"
[autostart]: https://userbase.kde.org/System_Settings/Autostart "System Settings/Autostart - KDE UserBase Wiki"
[xdg-autostart]: https://wiki.archlinux.org/title/XDG_Autostart "XDG Autostart - ArchWiki"
