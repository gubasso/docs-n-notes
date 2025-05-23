## Automate: Move application to virtual desktop

To have a given application automatically open on virtual desktop 4 after you log into KDE, you need to combine:

- **An Autostart entry** so the application launches at login.
- **A KWin (Window Rules) rule** that forces the app’s window onto desktop 4.

## Configure Autostart

### a. Using System Settings

1. Open **System Settings → Startup and Shutdown → Autostart** ([KDE UserBase][4])
2. Click **Add Program…**, select your application, and confirm. This copies its `.desktop` file into `~/.config/autostart/`.
3. Plasma scans `$HOME/.config/autostart/` for `.desktop` files at each login and launches them ([KDE Documentation][5])

### b. Manual XDG Autostart

Alternatively, drop or create a `.desktop` in `~/.config/autostart/` yourself. For example, `~/.config/autostart/myapp.desktop`:

```ini
[Desktop Entry]
Type=Application
Exec=/usr/bin/myapp
Hidden=false
X-GNOME-Autostart-enabled=true
```

* By the **XDG Autostart** spec, entries in `~/.config/autostart` are run automatically on session start ([Arch Wiki][6], [Arch Wiki][7])

## Create a KWin Window Rule

### a. Via the GUI

1. Launch the application once.
2. **Right-click** its title bar (or press **Alt + F3**) and choose **More Actions → Special Application Settings…** ([Ask Ubuntu][1])
3. In the dialog, go to the **Size & Position** tab, **check** “Desktop”, set the rule to **Force** (or “Remember”), and select **4** from the dropdown.
4. Click **Apply**. The rule is saved in `~/.config/kwinrulesrc` (e.g. with `desktop=4` and `desktoprule=2`) ([Ask Ubuntu][1])

### b. How It Works

* **KWin Rules** let you override window attributes such as which virtual desktop a window appears on ([KDE UserBase][2])
* You can also open the **Window Rules** module directly under **System Settings → Workspace → Window Management → Window Rules** ([KDE UserBase][3])

---

[1]: https://askubuntu.com/questions/1194529/how-do-i-launch-a-specific-application-on-a-specific-desktop-in-kubuntu-18-04 "virtualbox - How do I launch a specific application on a specific desktop in Kubuntu 18.04? - Ask Ubuntu"
[2]: https://userbase.kde.org/KWin_Rules "KWin Rules - KDE UserBase Wiki"
[3]: https://userbase.kde.org/System_Settings/Window_Rules "System Settings/Window Rules - KDE UserBase Wiki"
[4]: https://userbase.kde.org/System_Settings/Autostart "System Settings/Autostart - KDE UserBase Wiki"
[5]: https://docs.kde.org/stable5/en/plasma-workspace/kcontrol/autostart/index.html "Autostart"
[6]: https://wiki.archlinux.org/title/XDG_Autostart?utm_source=chatgpt.com "XDG Autostart - ArchWiki"
[7]: https://wiki.archlinux.org/title/Desktop_entries?utm_source=chatgpt.com "Desktop entries - ArchWiki"
[8]: https://commandmasters.com/commands/kwriteconfig5-linux/ "How to use the command 'kwriteconfig5' (with examples)"

