
## Summary

On Void’s `brave-bin` package there is **no built-in launcher** to parse `~/.config/brave-flags.conf`, so any flags placed there are simply **ignored** ([GitHub][1]). To get Brave to honor your flags on Void, you must emulate Arch’s **brave-launcher** approach—create a small shell wrapper that (1) reads your `brave-flags.conf`, (2) strips comments/blanks, and (3) execs the real `/opt/brave.com/brave/brave` binary with those flags ([Michael Abrahamsen][2]). Once that wrapper is in your `$PATH` (and your `.desktop` file points to it), your Wayland/VA-API/NVIDIA tweaks will apply on every launch ([Michael Abrahamsen][2]).

---

## Why `~/.config/brave-flags.conf` is ignored on Void

* The **Void** `brave-bin` package simply unpacks the upstream `.deb` into `/opt/brave.com/brave` and symlinks the binary; **it does not install** any wrapper script to load a flags file ([GitHub][1]).
* By contrast, the **Arch AUR** `brave` package ships a **`brave-launcher`** script that checks for `~/.config/brave-flags.conf`, filters out comments and empty lines, and appends those flags to the real binary ([Michael Abrahamsen][2]).
* Without that wrapper logic, your flags (e.g. `--ozone-platform=wayland`, VA-API, zero-copy, etc.) are **never** passed on Void ([GitHub][1]).

---

## How to implement an effective wrapper

1. **Create the launcher script**
   Save this as `~/bin/brave` (or `/usr/local/bin/brave` if you want it system-wide) **before** `/usr/bin` in your `PATH`:

   ```bash
   #!/usr/bin/env bash
   XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
   FLAGS_FILE="$XDG_CONFIG_HOME/brave-flags.conf"
   # Read flags, ignore blank lines and comments
   if [[ -f "$FLAGS_FILE" ]]; then
     USER_FLAGS=$(grep -vE '^\s*(#|$)' "$FLAGS_FILE" | xargs)
   fi
   # Exec the real Brave with your flags
   exec /opt/brave.com/brave/brave "$@" $USER_FLAGS
   ```

   ([Michael Abrahamsen][2]) ([Michael Abrahamsen][2])

2. **Make it executable & adjust your PATH**

   ```bash
   chmod +x ~/bin/brave
   export PATH="$HOME/bin:$PATH"
   ```

   Ensure `~/bin` precedes `/usr/bin` so your wrapper is used ([Arch Linux Forums][3]).

3. **Point your desktop shortcut to the wrapper**
   Edit your Brave `.desktop` entry (e.g. `/usr/share/applications/brave-browser.desktop` or `~/.local/share/applications/...`) and change:

   ```diff
   - Exec=/usr/bin/brave %U
   + Exec=$HOME/bin/brave %U
   ```

   This makes sure GUI-launched instances also pick up your flags ([Arch Linux Forums][3]).

---

## Alternative routes

* Installing **Brave via Flatpak** gives you a wrapper that reads flags from `~/.var/app/com.brave.Browser/config/brave-flags.conf` by default ([GitHub][4]).
* Using the **Arch AUR** `brave` package (or any distribution that supplies a `brave-launcher`) will automatically support `~/.config/brave-flags.conf` ([Michael Abrahamsen][2]).

---

## Verifying your flags

1. Open **`brave://version`** → check the **“Command Line”** field to see your flags listed ([GitHub][5]).
2. Go to **`brave://gpu`** and confirm **Ozone Platform = Wayland** (or inspect your VA-API flags under the command line) ([GitHub][5]).

With this wrapper in place (or by using a packaging format that includes one), Brave on Void will honor **all** of your custom Wayland, EGL and VA-API flags.

[1]: https://github.com/soanvig/brave-bin/blob/master/template "brave-bin/template at master · soanvig/brave-bin · GitHub"
[2]: https://michaelabrahamsen.com/posts/using-brave-browser-flags-in-linux/?utm_source=chatgpt.com "Michael Abrahamsen – Using Brave Browser flags in linux"
[3]: https://bbs.archlinux.org/viewtopic.php?id=304003&utm_source=chatgpt.com "[solved] Recently HEVC video won't play in browsers ... - Arch Linux Forums"
[4]: https://github.com/flathub/com.brave.Browser/issues/576?utm_source=chatgpt.com "Brave stopped working with OzonePlatform Wayland since 1.65.114"
[5]: https://github.com/flathub/com.brave.Browser/issues/59?utm_source=chatgpt.com "chrome-flags.conf not working · Issue #59 · flathub/com.brave.Browser"
