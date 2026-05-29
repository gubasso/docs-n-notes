# greetd + tuigreet

Minimal display manager with TUI greeter.

**References:** [greetd](https://sr.ht/~kennylevinsen/greetd/),
[tuigreet](https://github.com/apognu/tuigreet)

---

## Installation

```bash
sudo pacman -S greetd greetd-tuigreet
```

---

## Configuration

Edit `/etc/greetd/config.toml`:

```toml
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --asterisks --theme 'text=magenta;border=magenta;prompt=magenta;title=magenta;greet=magenta;time=magenta;action=magenta;button=magenta;container=black;input=magenta' --cmd startx"
user = "greeter"
```

**Options explained:**

| Option         | Description                              |
| -------------- | ---------------------------------------- |
| `--time`       | Display current time                     |
| `--remember`   | Remember last logged-in user             |
| `--asterisks`  | Show asterisks for password input        |
| `--theme`      | Color theme (purple on black)            |
| `--cmd startx` | Session command (launches X via xinitrc) |

---

## Enable Service

```bash
sudo systemctl enable greetd.service
```

Reboot to start using greetd:

```bash
systemctl reboot
```

---

## PAM Integration (Keyring Auto-Unlock)

greetd supports PAM modules for keyring auto-unlock. Add the appropriate module to
`/etc/pam.d/greetd`:

**KWallet:**

```pam
auth       optional     pam_kwallet5.so
session    optional     pam_kwallet5.so auto_start
```

**GNOME Keyring:**

```pam
auth       optional     pam_gnome_keyring.so
session    optional     pam_gnome_keyring.so auto_start
```

Place keyring lines **after** the corresponding `system-local-login` includes.

**Important:** Keyring password must match login password for auto-unlock.

See host-specific docs for complete keyring setup.

---

## Troubleshooting

### TTY Fallback

If greetd fails, switch to another TTY:

```bash
Ctrl+Alt+F2
```

Login and check logs:

```bash
journalctl -u greetd.service -e
```

### Reset to TTY Login

Disable greetd to return to manual TTY login:

```bash
sudo systemctl disable greetd.service
systemctl reboot
```

### Common Issues

**Black screen on boot:**

- Check VT setting matches available TTY
- Verify greeter user has permissions

**Session fails to start:**

- Verify `startx` works manually from TTY
- Check `~/.xinitrc` exists and is executable

---

## Verification

Quick checks after login:

```bash
# greetd service running
systemctl status greetd.service

# D-Bus session active
echo $DBUS_SESSION_BUS_ADDRESS

# Secrets service available (should not timeout)
busctl --user status org.freedesktop.secrets
```

Expected results:

- greetd: `active (running)`
- DBUS_SESSION_BUS_ADDRESS: `unix:path=/run/user/1000/bus`
- busctl: shows service info without timeout

For keyring-specific verification, see host docs.
