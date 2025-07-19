# d-bus, elogind, turnstile, seatd, XDG_RUNTIME_DIR

## D-Bus

D-Bus (Desktop Bus) is a lightweight, language- and platform-agnostic IPC (inter-process communication) system that lets applications talk to one another in a standardized, message-oriented way. It consists of:

* **A bus daemon** (one per system, one per user session) that brokers messages
* **Clients** (applications or services) that connect to the bus, register names (“well-known” or unique), expose objects and interfaces, and send or receive method calls, signals or property updates

There are two main buses:

1. **System bus** (`/usr/bin/dbus-daemon --system`)
   • Runs as root, for system-level services (e.g. udev, logind, NetworkManager)
   • Provides interfaces like `org.freedesktop.login1` (power, lid, user sessions) and `org.freedesktop.UPower` (battery)
2. **Session bus** (`dbus-launch` or `dbus-run-session`)
   • Launched per‐user when you log in (via your display manager or manually)
   • Used by your desktop apps: panels, notifications, media players, clipboard managers, etc.

Applications talk over D-Bus rather than rolling their own socket paths, text files or signals—so you get a consistent API, automatic activation, authentication and permission controls.

---

## Practical examples

### 1. Controlling volume / media playback

Many media players (e.g. **MPV**, **Spotify**, **vlc**) expose a D-Bus interface. A panel widget or hotkey daemon can call:

```bash
# Pause/resume playback in Spotify
dbus-send \
  --session \
  --dest=org.mpris.MediaPlayer2.spotify \
  /org/mpris/MediaPlayer2 \
  org.mpris.MediaPlayer2.Player.PlayPause
```

No need to parse MPV’s stdin pipe or hack Spotify’s window—it’s a well-defined method call.

### 2. Network status & notifications

**NetworkManager** publishes its state on the system bus under `org.freedesktop.NetworkManager`. A simple watcher can subscribe to its “StateChanged” signals and pop up notifications:

```bash
dbus-monitor --system "type='signal',interface='org.freedesktop.NetworkManager'"
```

When you roam between Wi-Fi networks, your tray icon (or a custom script) sees the signal and updates itself immediately.

### 3. Battery & power events

The `org.freedesktop.UPower` and `org.freedesktop.login1` services talk on the system bus. For example, when your battery hits a critical threshold UPower emits a `PropertiesChanged` signal:

```bash
# In Python (using pydbus)
bus = pydbus.SystemBus()
upower = bus.get("org.freedesktop.UPower", "/org/freedesktop/UPower")
def on_props(interface, changed, invalid):
    if changed.get("Percentage", 100) < 5:
        bus.get("org.freedesktop.login1", "/org/freedesktop/login1").Suspend(True)
upower.PropertiesChanged.connect(on_props)
```

Without D-Bus, you’d have to poll `/sys/class/power_supply/…` and race-detect lid-close—messy and inefficient.

---

## A real-world “laptop problem” solved by D-Bus

On Void Linux with Niri WM you might boot with no desktop environment. If you don’t launch a session bus, GUI apps (GTK, Waybar, notifications) won’t see things like your network status, battery alarms or media keys. Worse, some apps **refuse** to start if they can’t register on the session bus (they assume it’s there).

**Solution:**

1. **Enable the system bus:**

   ```bash
   ln -s /etc/sv/dbus /var/service/   # runit on Void
   reboot
   ```
2. **Start your WM under a session bus:**

   ```bash
   exec dbus-run-session -- sway
   ```

   Now Waybar can query `org.freedesktop.UPower` for icons, notifications-daemon works, and your GTK apps find their settings daemon on the session bus.

---

## An automation handled by D-Bus

### Automatic suspend on lid close

1. **logind** (part of systemd, but also available standalone) listens on the system bus at `org.freedesktop.login1`.
2. It watches for **ACPI events** (`LID_CLOSE`, `LID_OPEN`), then emits a `PrepareForSleep(boolean)` signal.
3. A compositor or power manager (e.g., `nwg-shell` or a custom script) subscribes to that signal:

   ```bash
   dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'"
   ```
4. On `true`, the handler calls:

   ```bash
   dbus-send --system \
     --dest=org.freedesktop.login1 \
     /org/freedesktop/login1 \
     org.freedesktop.login1.Manager.Suspend boolean:true
   ```
5. The machine cleanly suspends—no ugly polling loops or root-owned scripts in `/etc/acpi`.

Because D-Bus provides signals, method calls and well-known names, each piece stays loosely coupled and replaceable, yet works together seamlessly.

---

## elogind

Below is a deep-dive into **elogind**, its role on a modern Linux laptop, and how you can leverage it for practical session- and power-management tasks.

---

## What is elogind?

`elogind` is the standalone implementation of **systemd-logind**—the daemon that tracks user sessions, seats (VTs, graphics devices, input devices), and handles power events (suspend, hibernate, shutdown). It exposes a D-Bus interface (`org.freedesktop.login1`) so desktop environments, Wayland compositors, login managers and other user-land tools can:

* **Register/track sessions** (who’s logged in, on which VT/seat).
* **Manage seats** (grant exclusive access to `/dev/dri/*` and `/dev/input/*` for rootless graphics).
* **Handle power-button, lid-close and idle events**, and invoke suspend/hibernate/shutdown.
* **Enforce Inhibitors** (apps can temporarily block suspend/screensaver while playing video or burning DVDs).

Because it doesn’t depend on the rest of systemd, it’s a drop-in for distros like Void or other “init freedom” systems—just make sure the **system D-Bus** is running and the `elogind` service is enabled.

---

## Practical examples

### 1. Listing and locking your session

```bash
# List all current sessions:
loginctl list-sessions

# Lock your current session:
loginctl lock-session $XDG_SESSION_ID
```

Behind the scenes, `loginctl` is calling methods on the `org.freedesktop.login1.Manager` D-Bus interface, so you don’t have to write your own D-Bus stanzas.

---

### 2. Running a Wayland compositor as non-root

Wayland compositors (e.g. Sway, river, Niri WM) need exclusive access to input and GPU devices. With elogind:

1. You log in via a getty or display manager that registers your session with logind.
2. The compositor opens `/dev/dri/card0` and `/dev/input/event*`—elogind makes sure your unprivileged process is allowed to do so, without ever running as `root`.

Without elogind, you’d need a root-helper or setuid binary to grant those permissions—elogind handles it for you.

---

### 3. Inhibiting suspend for critical work

Say you’re burning a large ISO to USB or streaming a movie. Your burning tool or media player can grab an inhibitor lock so that an idle timeout or accidental lid-close doesn’t suspend the machine mid-job:

```c
// Pseudocode using libsystemd
sd_bus_call_method(bus,
                   "org.freedesktop.login1",
                   "/org/freedesktop/login1",
                   "org.freedesktop.login1.Manager",
                   "Inhibit",
                   NULL,
                   &reply,
                   "sssss",
                   "handle-power-key",   // what you’re inhibiting
                   "MyBurnApp",
                   "Burning ISO",
                   "block");
```

---

## A real-world “laptop problem” solved by elogind

**Problem:** On a fresh Void + Niri WM install, you boot to a VT login, start sway manually, and discover:

* **No auto-suspend** on lid close
* **Cannot open** `/dev/input/event*` as your user, so the compositor crashes
* **No session tracking**, so `loginctl` shows zero sessions

**Solution with elogind:**

1. **Enable system D-Bus** (e.g. `ln -s /etc/sv/dbus /var/service/ && reboot`).
2. **Enable and start elogind** (`ln -s /etc/sv/elogind /var/service/`).
3. **Launch your WM under the session bus**:

   ```bash
   exec dbus-run-session -- sway
   ```

   Now your compositor can open devices, lid events trigger suspend, and `loginctl` correctly shows your session.

---

## An automation handled by elogind

### Automatic suspend after idle

Instead of writing cron-jobs or polling `/proc` yourself, you can configure elogind to suspend or lock automatically:

1. Edit `/etc/elogind.conf` (uncomment or add):

   ```ini
   [Login]
   # After 10 minutes of inactivity, suspend the machine:
   IdleAction=suspend
   IdleActionSec=10min

   # Suspend when lid closes (unless docked):
   HandleLidSwitch=suspend
   HandleLidSwitchDocked=ignore
   ```
2. Restart the service:

   ```bash
   sv restart elogind
   ```

Now elogind watches keyboard/mouse activity and lid-close events itself—when the system has been idle for 10 minutes (no keypress, mouse, or touchscreen), it will automatically invoke the same D-Bus `Suspend` method it exposes to everyone else. Your laptop cleanly sleeps without any extra scripts.

---

By centralizing session, seat and power event management under a single, D-Bus-driven daemon, **elogind** keeps your user-land tools decoupled, secure, and vastly simplifies both one-off commands (`loginctl`, `dbus-send`) and ongoing automations (idle suspend, inhibitor locks, rootless graphics).

---

## turnstile

**Turnstile** is a minimal, flexible session manager designed to supervise per-user services (including graphical sessions, background daemons, and even a D-Bus session bus) without tying you to a monolithic init system. It can operate alongside elogind for login/power events, or stand on its own if you prefer lighter seat and power managers (e.g., seatd for seat/device ACLs and acpid for ACPI events).

---

## Key features & how it works

1. **Per-user service supervision**

   * Turnstile uses a straightforward directory layout under your home (e.g. `~/.config/turnstile/services/`) to define which services should start when you log in and stop when you log out.
   * Each service has its own manifest: executable, environment, restart policies, dependencies, etc.

2. **Built-in session bus**

   * You can enable an internal D-Bus session daemon by dropping a small unit file into your turnstile services directory—no more wrapping `dbus-run-session`.
   * If you *are* using elogind, simply disable turnstile’s own runtime-dir management (`manage_rundir=no` in `/etc/turnstile/turnstiled.conf`) so they don’t conflict.

3. **Clean startup & teardown**

   * On login, turnstile starts all user services in the correct order, monitors them, and restarts if they crash (subject to your policy).
   * On logout, it shuts down everything cleanly—no orphaned processes or leftover sockets.

---

## Practical examples

### 1. Launching your window manager + related daemons

Create `~/.config/turnstile/services/niri.toml`:

```toml
[service]
exec = ["dbus-run-session", "niri"]     # start your WM under its own session bus
restart = "on-failure"
```

Create `~/.config/turnstile/services/waybar.toml`:

```toml
[service]
exec = ["waybar"]
after = ["niri"]                        # ensures WM is up first
```

Create `~/.config/turnstile/services/notifications.toml`:

```toml
[service]
exec = ["dunst"]
after = ["dbus-session"]                # make sure D-Bus is running
```

Now when you log in (e.g. via a simple login shell that invokes `turnstile-session`), everything starts in the right order, is supervised, and is torn down on logout.

### 2. Running a D-Bus session without wrapping

Instead of:

```bash
exec dbus-run-session -- sway
```

you can let turnstile spawn the session bus itself. Drop `dbus-session.toml` into your services folder:

```toml
[service]
exec = ["dbus-daemon", "--session", "--address=system"]
pid-file = "/run/user/%U/dbus-session.pid"
provides = ["dbus-session"]
```

Then in your compositor’s service file, add:

```toml
after = ["dbus-session"]
env = { DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/%U/dbus-session.pid" }
```

All your GTK apps, panels, and daemons see a live session bus automatically.

---

## A real-world laptop problem solved by Turnstile

**Problem:** On Void + Niri WM you manually start Sway and dozens of scripts—each with different shell-wrapping, DBUS invocation, and ad-hoc restart logic. If one daemon dies (e.g. your notification daemon crashes), you lose notifications for the rest of your session until your next reboot or manual restart.

**Turnstile solution:**

1. **Supervision** – every service you define is automatically restarted on failure.
2. **Dependency ordering** – you declare “after = \[‘dbus-session’]” or “after = \[‘niri’]” instead of hand-rolling sleeps or wrapper scripts.
3. **Clean teardown** – logout kills *all* your user daemons, so you never end up with stale runtime directories or orphaned listeners.

---

## An automation handled by Turnstile

### Auto-restarting a crashed network-status monitor

Suppose you have a small script `nm-watcher.sh` that listens to NetworkManager over D-Bus and updates a status file for Waybar. Instead of starting it in your `.xinitrc` or a shell script, define:

```toml
# ~/.config/turnstile/services/nm-watcher.toml
[service]
exec = ["bash", "/home/you/scripts/nm-watcher.sh"]
after = ["dbus-session"]
restart = "always"
restart-delay = "5s"
```

* **What happens:** If `nm-watcher.sh` crashes (perhaps due to an unexpected DBus signal), Turnstile waits 5 seconds and relaunches it automatically.
* **Why it’s better:** No cron, no manual supervision, and the file for Waybar is *always* up to date. As soon as you log out, all of Turnstile’s services stop cleanly.

---

By decoupling individual user services into simple manifest files, handling dependencies, supervision, and even spawning your D-Bus session, **Turnstile** brings rock-solid reliability and minimal boilerplate to your Void Linux + Niri WM setup.

---

## seatd

Below is a deep dive into **seatd**, what it does, and how it can simplify seat/device management on a Wayland-based laptop.

---

## What is seatd?

`seatd` is a minimal “seat manager” for Linux: it listens for udev events and dynamically grants or revokes access to input and GPU devices on a per-seat basis. Unlike **elogind**, it does **only** seat/device ACLs—no session tracking, no power management. It’s ideal for wlroots-based compositors (Sway, river, Niri WM) on distros that avoid systemd.

Key points:

* Runs as a system daemon: manages `_seatd` group membership, device ACLs via udev.
* Users in the `_seatd` group can open `/dev/input/event*` and `/dev/dri/card*` for whichever seat they’re on.
* Provides `seatd-run`: a wrapper that launches a program with the right seat permissions (and environment).

---

## Practical examples

### 1. Install, enable, and add your user to `_seatd`

```bash
# Install seatd (on Void Linux):
sudo xbps-install -Sy seatd

# Enable the seatd service under runit:
sudo ln -s /etc/sv/seatd /var/service/

# Add yourself to the seatd group:
sudo usermod -aG _seatd $USER

# Reboot or re-login so your group change takes effect.
```

### 2. Launch your Wayland compositor with seatd-run

Rather than starting Sway (or Niri WM) as root or wrestling with udev rules:

```bash
# Start your compositor with seat permissions:
exec seatd-run sway
```

`seatd-run` does two things automatically:

1. Ensures your process is in the right `_seatd` group.
2. Exports `XDG_RUNTIME_DIR` to a seat-specific path (e.g. `/run/user/1000/seat0`), so you don’t need `dbus-run-session`.

### 3. Multi-seat setups

If you have multiple seats (e.g. two displays + keyboards on a demo box), seatd will create `seat0`, `seat1`,… and you can launch a second session:

```bash
# On the second VT or via SSH:
export SEAT=seat1
exec seatd-run --id seat1 river
```

Each compositor instance only sees the input devices and GPU assigned to its seat.

---

## A laptop problem solved by seatd

**Problem:** On Void Linux + Niri WM, you boot to a VT, log in on tty1, then manually start `sway`. It immediately crashes:

```
Error opening /dev/input/event0: Permission denied
```

You try `sudo sway` (unsafe!), or manually write udev rules for each device, or preload a setuid helper binary. It’s a pain to maintain.

**seatd solution:**

1. Install and enable `seatd`.
2. Add your user to `_seatd`.
3. Start Sway with `seatd-run sway`.

Now Sway (and all its child processes) automatically have access to your laptop’s keyboard, touchpad and NVIDIA device—no root, no custom udev hacks.

---

## An automation handled by seatd

### Dynamic device-ACL automation

As you plug and unplug USB devices (gamepads, drawing tablets, additional keyboards), seatd’s udev rules fire automatically:

1. **udev event**: you plug in `/dev/input/event12`.
2. **seatd’s udev rule** matches it and assigns it to the current seat (e.g. `seat0`).
3. **seatd daemon** adjusts the ACLs so your unprivileged compositor can read from `event12` immediately—without any polling or manual scripts.

That end-to-end flow—from physical device insertion to compositor input—happens automatically, with zero shell scripts or cron jobs. Seatd’s sole focus on seats and device ACLs makes it blazingly simple, reliable, and perfect for lean Wayland setups.


---


## elogind vs seatd

If you already have **elogind** running, you generally **do not** need to install **seatd**—elogind already takes care of:

* Granting your logged-in user access to the correct `/dev/input/*` and `/dev/dri/*` devices
* Tracking which seat (seat0, seat1, etc.) you’re on
* Working with your PAM/login setup so any process you launch (e.g. your Wayland compositor) can open those devices without extra wrappers

In practice, that means:

1. You log in (say via a getty, SSH, or a display manager)
2. elogind registers your session and adjusts device ACLs for you
3. You can simply `exec sway` (or `exec seatd-run sway` if you were using seatd) and it “just works”

---

### When you might still reach for seatd

* **You want an even lighter footprint**: seatd only does seats/device ACL; elogind also tracks sessions, inhibits, idle actions, etc.
* **You aren’t using elogind**: on a system without any logind-style service, seatd + acpid is the minimal combo to get seat ACLs and power events.

But if you’ve already enabled and rely on elogind, installing seatd is **redundant**—it won’t hurt, but it won’t add anything you’re not already getting from elogind.


---

## elogind vs turnstile

Below is a concise comparison showing that **elogind** can indeed manage your **XDG\_RUNTIME\_DIR** just like **turnstile**, along with how each does it and how to avoid conflicts.

## Summary

Both **elogind** and **turnstile** will automatically create and export `XDG_RUNTIME_DIR` (typically `/run/user/$UID`) when you log in.

* **elogind** uses the `pam_systemd` PAM module to mount a per-user tmpfs, create `/run/user/$UID`, and set `XDG_RUNTIME_DIR` on login ([man7.org][1]).
* **turnstile** runs its own PAM module (`pam_turnstile.so`) plus a daemon (`turnstiled`) to create and manage the runtime directory and export the environment variable ([deepwiki.com][2]).
  If you enable both on the same system, you should **disable** turnstile’s `manage_rundir` to avoid clobbering ([man.voidlinux.org][3]).

---

## What is XDG\_RUNTIME\_DIR?

`XDG_RUNTIME_DIR` is the per-user directory for non-essential runtime files (sockets, named pipes, etc.), normally located at `/run/user/$UID`. Programs like D-Bus, PulseAudio, Wayland compositors and others rely on it being present and properly owned ([docs.voidlinux.org][4], [askubuntu.com][5]).

---

## How turnstile manages `XDG_RUNTIME_DIR`

1. **PAM integration**: On login, `pam_turnstile.so` tells the `turnstiled` daemon to:

   * Create `/run/user/$UID` (or your configured path)
   * Set ownership and permissions (0700)
   * Export `XDG_RUNTIME_DIR` into your session environment ([deepwiki.com][2], [deepwiki.com][6]).
2. **Configuration**: In `/etc/turnstile/turnstiled.conf` you can toggle

   ```ini
   manage_rundir = yes
   ```

   to on or off; turning it **off** avoids clashes if another service (like elogind) also manages the dir ([man.voidlinux.org][3]).
3. **Service supervision**: `turnstiled` ensures the directory persists for the lifetime of your session (and any “linger” services) and cleans it up on logout.

---

## How elogind manages `XDG_RUNTIME_DIR`

1. **PAM module**: `pam_systemd.so` (shipped with elogind) is invoked on each login. It:

   * Mounts or creates a new tmpfs at `/run/user/$UID` with quotas
   * Sets ownership to the logging-in user
   * Exports `XDG_RUNTIME_DIR` and initializes `$XDG_SESSION_ID` ([man7.org][1], [manpages.debian.org][7]).
2. **Service integration**: elogind’s `user@.service` instance is started per-user and tied to that directory. When your last session ends, the tmpfs is torn down.
3. **Distribution docs**: Most non-systemd distros use elogind exactly for this purpose—handling runtime directories in the same way systemd-logind does ([wiki.gentoo.org][8]).

---

## Avoiding conflicts when using both

If you choose to run **turnstile** alongside **elogind**, turn off turnstile’s runtime-dir management:

```ini
# /etc/turnstile/turnstiled.conf
manage_rundir = no
```

This lets elogind own `/run/user/$UID`, while turnstile continues supervising your per-user services without stomping on the directory ([deepwiki.com][9], [man.voidlinux.org][3]).

---

## Conclusion

Yes—**elogind** can fully replace **turnstile** for automatic `XDG_RUNTIME_DIR` setup. Both solutions accomplish the same core task via a PAM module + daemon, but if you’re already running elogind, there’s no need to install turnstile solely for handling the runtime directory. Just ensure only one of them manages `XDG_RUNTIME_DIR` to avoid conflicts.

[1]: https://www.man7.org/linux/man-pages/man8/pam_systemd.8.html "pam_systemd (8) — Linux manual page - man7.org"
[2]: https://deepwiki.com/chimera-linux/turnstile "chimera-linux/turnstile | DeepWiki"
[3]: https://man.voidlinux.org/turnstiled.conf "turnstiled.conf (5) - Void Linux manpages"
[4]: https://docs.voidlinux.org/config/session-management.html "Session and Seat Management - Void Linux Handbook"
[5]: https://askubuntu.com/questions/872792/what-is-xdg-runtime-dir "command line - What is XDG_RUNTIME_DIR? - Ask Ubuntu"
[6]: https://deepwiki.com/chimera-linux/turnstile/5.2-environment-variables "Environment Variables | chimera-linux/turnstile | DeepWiki"
[7]: https://manpages.debian.org/testing/elogind/user-runtime-dir%40.service.5.en.html "user-runtime-dir@.service (5) — elogind — Debian testing — Debian Manpages"
[8]: https://wiki.gentoo.org/wiki/Configuring_a_system_without_elogind "Configuring a system without elogind - Gentoo Wiki"
[9]: https://deepwiki.com/chimera-linux/turnstile/5-configuration "Configuration | chimera-linux/turnstile | DeepWiki"

---

Elogind and Turnstile overlap heavily on **session/login tracking**, **seat/device ACL**, **power management**, and **runtime-dir setup**, but **only Turnstile** provides built-in, service-manager-agnostic **per-user service supervision**. Elogind is the standalone “logind” extracted from systemd, exposing the standard `org.freedesktop.login1` D-Bus API and handling seats, multi-seat, idle/inhibit logic, power keys, and XDG\_RUNTIME\_DIR via its PAM integration turn7view0turn2view0turn8search11. Turnstile, by contrast, is explicitly built to **spawn, supervise and tear down** your per-user service manager (Dinit, runit, etc.) on login/logout, with pluggable backends and restart policies turn4view0turn5view0. If all you need is logind-style session and seat management, Elogind suffices; but for Turnstile’s **automatic user-service orchestration**, you still need Turnstile (or a systemd-user instance managed by systemd itself).

---

## Elogind’s core functionality

### Session & seat/device ACL

Elogind tracks sessions and seats (VTs, input/output devices) and dynamically grants ACLs so unprivileged processes can open `/dev/input/*` and `/dev/dri/*` without root turn7view0. It implements “seat” semantics just like systemd-logind, exposing seat switching and device management over D-Bus turn8search11.

### Power management & idle/inhibition

It monitors power-button and lid-switch events and handles suspend/hibernate directly (using systemd-sleep code), and enforces inhibitor locks for applications turn9view0.

### Runtime directory & D-Bus environment

Via its `pam_elogind.so` module, Elogind creates and exports `XDG_RUNTIME_DIR=/run/user/$UID` on login, mounts the tmpfs, and sets up the D-Bus session bus address in the environment turn2view0.

---

## Turnstile’s unique service-management features

### Per-user service supervision

Turnstile goes beyond session tracking: it **launches**, **monitors**, and **restarts** your per-user service manager and its services (e.g., your WM, notification daemon, custom scripts) in a service-manager-agnostic way turn4view0turn5view0. When you log out, it cleanly tears everything down (or lingers if configured).

### Pluggable backends & session persistence

You drop simple manifest files into `~/.config/turnstile/services/`, declare dependencies (`after = ["dbus-session"]`, etc.), and let Turnstile handle ordering, environment, and PID tracking. It even supports a “linger” mode so services outlive a logout turn5view0.

---

## Systemd user manager as an alternative

On a **systemd-based** system, `systemd-logind` can spawn a **per-user** `systemd --user` instance (via `user@.service`) to manage user units turn1search0turn1search1. If you run **Elogind** under systemd and enable lingering (`loginctl enable-linger`), you effectively get a per-user service manager—so you could skip Turnstile **if** you’re content with systemd’s user services.

---

## Conclusion

* **Elogind** fully covers **session**, **seat/device ACL**, **power events**, **D-Bus**, and **XDG\_RUNTIME\_DIR** setup turn7view0turn2view0turn9view0.
* **Turnstile** adds **pluggable, supervised per-user service management**, dependency ordering, and session persistence—functionality **Elogind alone does not provide** turn4view0turn5view0.
* On a non-systemd distro, use **Turnstile** for per-user services; on a systemd distro, you can rely on **Elogind + systemd-user** instead.

