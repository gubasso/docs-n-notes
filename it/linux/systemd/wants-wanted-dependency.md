# Systemd: Wants/WantedBy dependency

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
