# User services in void linux with: elogind, runit, turnstile, dinit

## Solving this problem:

1) After the system starts, I already am at tty1. I mean that I want niri to autostart after login, only if I am at tty1. I have this rule setup at .profile, but I want to know if turnstile/dinit/elogind can manage that instead of .profile

2) Let's focus on turnstile + dinit to make the declarative units
   a) computer starts and I am at tty1 ready for login (it already is set)
   b) type user/password -> correctly logged in. I need to setup niri to start automatically (.profile is already doing this, can I do this with turnstile/dinit/elogind instead?
   c) setup the startup sequence rules with turnstile/dinit/elogind: niri -> waybar -> keepassxc/nextcloud

## Solution

* **turnstile** injects a *per‑login* instance of **dinit** as soon as PAM finishes authenticating you;
* dinit then enforces the graph **niri → waybar → {keepassxc, nextcloud}** with true readiness signalling, not arbitrary sleeps;
* niri starts only when you log in on **tty 1**, thanks to the `XDG_VTNR` variable that elogind (or logind‑compatible PAM) exports.

## Setup

### Enable the stack

```sh
sudo xbps-install -Sy turnstile dinit inotify-tools
sudo ln -s /etc/sv/turnstiled /var/service
sv status turnstiled # make sure the service is running
```

### Tell turnstile to use dinit (not the default runit backend)

Open `/etc/turnstile/turnstiled.conf` and make sure you have

```ini
backend = dinit
```

```sh
sudo sv restart turnstiled     # or: sv down/up turnstiled
```

### Check PAM: is `pam_turnstile.so` in the session stack?

Turnstile’s PAM module is what signals the daemon to start the per-user dinit when you log in ([Artix Linux Forum][5]).

You need **one** line like the following in either `/etc/pam.d/login` **or** the common file inherited by it (`system-login` on Void):

```
session   optional   pam_turnstile.so
```

Void’s `turnstile` package normally installs this line automatically; confirm it wasn’t removed ([Artix Linux Forum][4]).

### Log out and back in (or switch VTs)

At every new login turnstile should now spawn a user instance:

```bash
pgrep -xu "$USER" dinit            # should print a PID
ls -l /run/user/$(id -u)/dinitctl  # control socket should exist
```

If those two checks pass, `dinitctl list` or `dinitctl enable boot` will work with no extra flags ([GitHub][6], [Davmac][7]).

### User‑mode dinit base directory

```sh
mkdir -p ~/.config/dinit.d ~/.local/state/dinit
echo 'log-dir = $HOME/.local/state/dinit' > ~/.config/dinit.d/config
```

dinit looks here automatically when turnstile starts it.([wiki.artixlinux.org][3], [GitHub][4])

### Service files

```
~/.config/dinit.d
├── boot
├── niri
│   ├── service
│   └── niri-wrapper.sh
├── waybar
│   └── service
├── keepassxc
│   └── service
└── nextcloud
    └── service
```

#### `boot` (milestone that comes up immediately)

```ini
type        = internal
depends-on  = niri
```

Everything else fans out from here.([about boot file][3])

#### `niri-wrapper.sh`

```sh
#!/bin/sh
# Launch niri only on tty1 and signal readiness via FD 3
if [ "$XDG_VTNR" != "1" ]; then
  exit 0            # session on another VT → do nothing, still succeed
fi

SOCK="$XDG_RUNTIME_DIR/wayland-1"
niri &                  # compositor in background
pid=$!

# inotifywait blocks until the socket actually appears – no polling loop
inotifywait -q -e create "$(dirname "$SOCK")" --format '' "${SOCK}" >&3
# newline written to FD 3 tells dinit “service is READY” (see ready‑notification)
wait $pid               # keep wrapper alive so dinit can supervise niri
```

Check how this `inotifywait` command works ([inotify][14])

#### `niri/service`

```ini
type              = process
command           = $SERVICE_DIR/niri-wrapper.sh
ready-notification = fd:3             # event‑driven readiness
logfile           = $HOME/.local/state/dinit/niri.log
restart           = true
```

Because `elogind`/PAM exports `XDG_VTNR`, the test is trivial.([freedesktop.org][5])

#### `waybar/service`

```ini
type         = process
depends-on   = niri
command      = waybar
logfile      = $HOME/.local/state/dinit/waybar.log
restart      = true
```

#### `keepassxc/service`  (identical for nextcloud)

```ini
type         = process
depends-on   = waybar
command      = keepassxc
logfile      = $HOME/.local/state/dinit/keepassxc.log
restart      = true
```

### How *depends‑on* really works in dinit

1. When a service lists `depends-on = X`, dinit *recursively* activates **X** first.
2. It waits until **X** reaches the **started** state.

   * For *process* services **without** a readiness hook the state flips as soon as the `exec()` succeeds.([wiki.artixlinux.org][3])
   * If `ready-notification` is set, dinit blocks until the child **writes one byte** to the provided pipe (FD 3 in our wrapper). This is identical to the s6 readiness model—no fixed timeout, no polling.([GitHub][6], [GitHub][6])
   * For `bgprocess`, readiness is implicit when the forking parent exits.([GitHub][7])
   * For `scripted`, the service is *ready* when the script exits with 0.([GitHub][8])
3. After the dependency graph is satisfied dinit spawns the dependents; if any dependency later crashes, dinit also stops/restarts the dependents according to policy.([GitHub][9], [GitHub][10])

***No arbitrary delay is ever inserted***—readiness is event‑driven, giving you systemd‑style determinism without the sleeper loops.

---

### Enabling, testing, controlling

Dinit launches the `boot` service automatically if you don’t name another initial service.

```sh
# first login after creating the files
dinitctl list                 # view graph and state
dinitctl log niri             # tail compositor logs
dinitcheck niri #checks for logs
```

If you switch to tty2 and log in, `$XDG_VTNR` will be 2; `niri-wrapper.sh` exits 0, so no compositor or children start, yet the session still succeeds.

---

### Why not leave this in `.profile`?

* With turnstile + dinit every program runs under supervision and gains auto‑restart and logging.([Void Linux Documentation][11])
* The dependency graph is declarative and version‑controlled—no shell `if … then …` spaghetti.
* `elogind` still handles seat/VT switching and power keys; turnstile merely *adds* user‑service orchestration.([Void Linux Documentation][2])

### Troubleshooting tips

| Symptom             | Check                                                                                                                                   |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Waybar never starts | `dinitctl status niri` to confirm it reported **started**; if not, inspect `$XDG_RUNTIME_DIR/wayland-1` path.                           |
| Services not found  | Ensure `boot` service is **enabled**; user dinit won’t traverse the graph otherwise.                                                    |
| Need extra env vars | Add `env-file = $HOME/.config/dinit.d/env` to any service; dinit substitutes them at load time.([wiki.artixlinux.org][3], [GitHub][12]) |

#### If dinit **is** running but dinitctl still cannot find the socket

Occasionally the backend places the socket under `/run/turnstiled/$UID/dinitctl`; this was seen after recent updates on Artix/turnstile ([Artix Linux Forum][8]). Two quick cures:

* **Point dinitctl at it explicitly**

  ```bash
  dinitctl -p /run/turnstiled/$(id -u)/dinitctl list
  ```

* **Or create a symlink** (works around old clients that look only in `$XDG_RUNTIME_DIR`):

  ```bash
  ln -s /run/turnstiled/$(id -u)/dinitctl ~/.dinitctl
  ```

Either method makes `dinitctl` happy without touching backend code.

With these units in place your Void system boots directly to a login prompt on tty1; after you authenticate, turnstile + dinit bring up niri and the rest in a strictly ordered, fully supervised chain—no sleeps, no races, and nothing cluttering your `.profile`.

[1]: https://github.com/chimera-linux/turnstile?utm_source=chatgpt.com "GitHub - chimera-linux/turnstile: Independent session/login tracker"
[2]: https://docs.voidlinux.org/config/session-management.html?utm_source=chatgpt.com "Session and Seat Management - Void Linux Handbook"
[3]: https://wiki.artixlinux.org/Main/Dinit "Wiki | Main / dinit "
[4]: https://github.com/davmac314/dinit/blob/master/doc/getting_started.md?utm_source=chatgpt.com "dinit/doc/getting_started.md at master · davmac314/dinit"
[5]: https://www.freedesktop.org/software/systemd/man/249/pam_systemd.html?utm_source=chatgpt.com "pam_systemd - freedesktop.org"
[6]: https://github.com/davmac314/dinit/discussions/252?utm_source=chatgpt.com "how to use ready-notification funciton? · davmac314 dinit - GitHub"
[7]: https://github.com/davmac314/dinit/discussions/313?utm_source=chatgpt.com "Wait for busybox syslogd to be ready · davmac314 dinit - GitHub"
[8]: https://github.com/davmac314/dinit/issues/231?utm_source=chatgpt.com "Improve service type documentation · Issue #231 · davmac314/dinit"
[9]: https://github.com/davmac314/dinit/discussions/316?utm_source=chatgpt.com "dinitctl start-or-restart · davmac314 dinit · Discussion #316"
[10]: https://github.com/davmac314/dinit/blob/master/README.md?utm_source=chatgpt.com "dinit/README.md at master · davmac314/dinit · GitHub"
[11]: https://docs.voidlinux.org/config/services/user-services.html?utm_source=chatgpt.com "Per-User Services - Void Linux Handbook"
[12]: https://github.com/davmac314/dinit/issues/39?utm_source=chatgpt.com "Variable substitution outside command paths · Issue #39 · davmac314/dinit"
[13]: ./dinit.md "Dinit"
[14]: ./inotifywait.md "inotifywait"

---

[1]: https://docs.voidlinux.org/config/session-management.html?utm_source=chatgpt.com "Session and Seat Management - Void Linux Handbook"
[2]: https://wiki.artixlinux.org/Main/Turnstile?utm_source=chatgpt.com "Wiki | Main / turnstile"
[3]: https://man.voidlinux.org/turnstiled.conf "turnstiled.conf(5) - Void Linux manpages"
[4]: https://forum.artixlinux.org/index.php/topic%2C6565.0.html "turnstile user dinit: In multiple cgroups, cannot determine cgroup root path"
[5]: https://forum.artixlinux.org/index.php/topic%2C6565.0.html?utm_source=chatgpt.com "turnstile user dinit: In multiple cgroups, cannot determine cgroup root ..."
[6]: https://github.com/davmac314/dinit/discussions/183?utm_source=chatgpt.com "Where best to start dinit from for user services? - GitHub"
[7]: https://davmac.org/projects/dinit/man-pages-html/dinitctl.8.html "DINITCTL(8)"
[8]: https://forum.artixlinux.org/index.php/topic%2C6908.0.html "[SOLVED] Problems with user instance after recent update"
[9]: https://github.com/chimera-linux/turnstile?utm_source=chatgpt.com "GitHub - chimera-linux/turnstile: Independent session/login tracker"
[10]: https://man.voidlinux.org/turnstiled.conf?utm_source=chatgpt.com "turnstiled.conf (5) - Void Linux manpages"
[11]: https://docs.voidlinux.org/config/session-management.html "Session and Seat Management - Void Linux Handbook"
[12]: https://deepwiki.com/chimera-linux/turnstile/4.1-dinit-backend?utm_source=chatgpt.com "Dinit Backend | chimera-linux/turnstile | DeepWiki"

