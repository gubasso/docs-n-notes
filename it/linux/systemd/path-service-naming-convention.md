# Path <-> Service: Naming conventions

When you define two unit files with the same “base” name—one ending in `.path` and one ending in `.service`—systemd will automatically wire them together: as soon as the conditions in the `.path` unit are satisfied, it will queue the identically‑named `.service` for execution.

---

## 1. Naming conventions
- **Path watcher:** `fix-speaker-dock.path`
- **Action service:** `fix-speaker-dock.service`

By default, a `.path` unit will trigger the `.service` unit that shares its base name (`fix-speaker-dock`).

---

## 2. How a `.path` unit works
A `.path` unit lives in your user’s systemd namespace and has a stanza like:

```ini
[Path]
PathExists=/dev/snd/by-id/usb-Lenovo_ThinkPad_Thunderbolt_4_Dock_USB_Audio_…-00
```

1. When you **enable** and **start** `fix-speaker-dock.path`, systemd registers an in‑kernel watch (via inotify) on that filesystem path.
2. If that file **already exists**, or as soon as it **appears**, systemd considers the `.path` unit “activated.”

---

## 3. Triggering the service
- **Implicit `Unit=` link:** Because you didn’t override it, systemd assumes you want to run `fix-speaker-dock.service`.
- **Activation:** On the path event, systemd does the equivalent of:
  ```bash
  systemctl --user start fix-speaker-dock.service
  ```
  behind the scenes.

If you ever needed to trigger a differently named unit, you could add under `[Path]`:

```ini
Unit=some-other-name.service
```

—but since you stuck to the same base name, no extra wiring is necessary.

---

### Summary

- **Base name match** makes systemd pair your `.path` and `.service`.
- **PathExists** (or other `Path*=` directives) tells systemd *when* to fire.
- Behind the scenes it simply calls `start` on the matching `.service`.

That’s why enabling `fix-speaker-dock.path` is all you need—systemd takes care of invoking `fix-speaker-dock.service` the moment your dock’s audio device shows up.
