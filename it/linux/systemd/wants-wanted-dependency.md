# Systemd: Wants/WantedBy dependency

Once your unit file includes:

```ini
[Install]
WantedBy=graphical-session.target
```

you only need to run:

```bash
systemctl --user enable --now keepassxc.service
```

* `enable` installs the symlink into `graphical-session.target.wants/` as specified by your `WantedBy=` line
* `WantedBy=graphical-session.target` – install-time “reverse” dependency
* `graphical-session.target` is a special user target that is active for any Wayland or X11 session; services that are only useful in a GUI are typically attached here .
* The `--now` flag tells systemd to **also start** the service immediately, combining what would otherwise be separate `enable` + `start` commands
* After that, KeePassXC will be pulled in and started automatically whenever your graphical session (i.e. `graphical-session.target`) is activated.

`After=waybar.service` – runtime ordering only

* `After=` (and its twin `Before=`) tell systemd **when** to start one unit *relative to* another, but they do **not** create any dependency by themselves – if no one asks for *both* units, nothing happens
* In your KeePassXC unit this makes the service wait until Waybar has reached the “started” state before it launches, preventing the classic tray-icon race

---

*Need automatic start at login?*
→ Keep `WantedBy=graphical-session.target` **or** `add-wants niri.service …`.
  → Use **one** of the two wiring methods (WantedBy *or* add-wants) and avoid duplicating links.
*Need to guarantee the tray is present first?*
→ Keep `After=waybar.service`.

With this mental model—**ordering (`After=`) vs pulling (`Wants=`/symlinks)**—you can reason about any other user-unit relationship in your Arch + Niri setup.

## Summary

Both `systemctl --user add-wants niri.service keepassxc.service` and declaring

```ini
[Install]
WantedBy=graphical-session.target
```

serve the **same underlying mechanism**—they create a *Wants=* dependency via symlinks—yet they differ only in **which unit** becomes the “puller.” You can choose either approach interchangeably **if** you’re happy with the same parent unit wanting your KeePassXC service.

---

## How they work under the hood

* **`Wants=` vs. `WantedBy=`**
  In systemd, a `Wants=` line in a unit’s `[Unit]` section defines a soft dependency, while `WantedBy=` in `[Install]` tells `systemctl enable` where to drop the symlink so that activating that target will pull in your service ([Unix & Linux Stack Exchange][1]).
* **`systemctl --user add-wants`**
  This CLI command programmatically creates the identical kind of symlink (in `~/.config/systemd/user/<target>.wants/`), without you having to edit unit files or run `enable` ([Debian Manpages][2]).

---

## What’s the only real difference?

| Method                                     | Puller Unit                | Symlink location                                                                                             |
| ------------------------------------------ | -------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `add-wants niri.service keepassxc.service` | `niri.service`             | `~/.config/systemd/user/niri.service.wants/keepassxc.service` ([Debian Manpages][2])                         |
| `WantedBy=graphical-session.target`        | `graphical-session.target` | `~/.config/systemd/user/graphical-session.target.wants/keepassxc.service` ([Unix & Linux Stack Exchange][1]) |

---

## When to pick which

* **Tie to Niri only**
  If you want KeePassXC to follow the lifecycle of **just** your Niri compositor (start/stop/restart), use:

  ```bash
  systemctl --user add-wants niri.service keepassxc.service
  ```

  ([Debian Manpages][2])

* **Tie to any graphical session**
  If you prefer KeePassXC to launch whenever **any** graphical session is active (not just Niri), include in your unit:

  ```ini
  [Install]
  WantedBy=graphical-session.target
  ```

  ([Arch Linux Forums][3])

---

## Key takeaway

You **can** use **either** approach to achieve the same “KeePassXC is wanted by X” effect—just pick the parent unit (`niri.service` vs. `graphical-session.target`) that best matches when you really want KeePassXC to come up.

[1]: https://unix.stackexchange.com/questions/579068/best-practice-for-wants-vs-wantedby-in-systemd-unit-files?utm_source=chatgpt.com "Best practice for Wants= vs WantedBy= in Systemd Unit Files"
[2]: https://manpages.debian.org/bullseye/systemd/systemctl.1.en.html?utm_source=chatgpt.com "systemctl (1) — systemd — Debian bullseye — Debian Manpages"
[3]: https://bbs.archlinux.org/viewtopic.php?id=247612&utm_source=chatgpt.com "How to get a 'graphical session'? / Newbie Corner / Arch Linux Forums"
