# Global environment variables in Void / Wayland / Window Manager

## Summary

On Void Linux, the `/etc/env.d` directory is not used by default to populate environment variables for user sessions or runit services, as it is a Gentoo-specific mechanism. Instead, Void relies on shell initialization scripts (e.g., `/etc/profile.d/*.sh`), the PAM environment file (`/etc/environment`), and runit’s own per-service `envdir` functionality to manage environment variables. Therefore, placing a file at `/etc/env.d/99-nvidia-gbm` will **not** make `GBM_BACKEND=nvidia-drm` globally available in a Wayland/Niri session. Instead, you should use one of the following approaches:

---

## `/etc/env.d` Is Gentoo-Specific

Gentoo introduced `/etc/env.d` to centralize environment variable definitions and uses the `env-update` command to regenerate `/etc/profile` and `/etc/profile.env` from them ([wiki.gentoo.org][1], [wiki.gentoo.org][2]). Most other distributions, including Void Linux, do **not** implement this directory.

---

## How Void Linux Loads Environment Variables

### Shell Login Scripts (`/etc/profile.d`)

Void’s default `/etc/profile` sources all `*.sh` scripts in `/etc/profile.d`, applying them only to **login shells** ([linuxtopia.org][3]). However, graphical login managers like GDM on Void have been reported **not** to source `/etc/profile.d` scripts, so you may not see these variables in a desktop session ([github.com][4]).

### PAM Environment (`/etc/environment`)

The standard Linux mechanism for setting system-wide variables for all PAM-based logins is `/etc/environment`, which consists of simple `KEY=value` lines (without `export`) and is processed by the `pam_env` module at login ([askubuntu.com][5]).

### Runit Services and `envdir`

Runit-managed services can load environment variables via an `envdir` directory under each service (i.e., `/etc/sv/<service>/env` or `~/.config/service/<service>/env`) using `chpst -e` ([docs.voidlinux.org][6], [unix.stackexchange.com][7]). For user-level services started by Turnstile under runit, `TURNSTILE_ENV_DIR` points to a shared envdir containing variables exported by the session manager ([docs.voidlinux.org][6]).

### Wayland Sessions

Void’s Wayland handbook notes that, outside desktop environments like GNOME or KDE, certain applications may require manually exported environment variables to choose the correct backend ([docs.voidlinux.org][8]). The session manager (e.g., Turnstile with elogind) will set up basic variables like `XDG_RUNTIME_DIR`, but additional ones must come from your shell or service envdir ([docs.voidlinux.org][9]).

---

## Recommended Approaches for `GBM_BACKEND=nvidia-drm`

Depending on your needs, choose one of the following:

1. **User Login Shell**
   Create `/etc/profile.d/99-nvidia-gbm.sh` containing:

   ```sh
   export GBM_BACKEND=nvidia-drm
   ```

   and then log out and back in (or source it in your shell). Note that this only affects login shells and terminals, not necessarily your graphical session ([askubuntu.com][10]).

2. **PAM Environment**
   Add the line `GBM_BACKEND=nvidia-drm` to `/etc/environment`. This ensures all PAM-based logins (including display managers using `pam_env`) receive the variable ([askubuntu.com][5]).

3. **Service-Level Envdir**
   If you start Niri WM via a runit service (e.g., under `~/.config/service/niri`), create `~/.config/service/niri/env/GBM_BACKEND` with:

   ```
   nvidia-drm
   ```

   Then ensure the service’s `run` script invokes `chpst -e "$TURNSTILE_ENV_DIR"` or similar to load it ([docs.voidlinux.org][6]).

4. **Compositor Launch Wrapper**
   If you launch Niri via a script, wrap it:

   ```sh
   #!/bin/sh
   export GBM_BACKEND=nvidia-drm
   exec niri
   ```

   and point your login command to this wrapper. This is the most straightforward way to guarantee the variable is set exactly where it’s needed ([docs.voidlinux.org][9]).

---

## Conclusion

Placing `GBM_BACKEND=nvidia-drm` in `/etc/env.d/99-nvidia-gbm` on Void Linux will **not** work, because Void does not source `/etc/env.d`. Instead, use `/etc/profile.d` for shells, `/etc/environment` for PAM logins, runit’s `envdir` for service-specific variables, or a dedicated launch wrapper script for your Wayland/Niri session.

[1]: https://wiki.gentoo.org/wiki//etc/env.d?utm_source=chatgpt.com "/etc/env.d - Gentoo Wiki"
[2]: https://wiki.gentoo.org/wiki/Handbook%3AX86/Working/EnvVar?utm_source=chatgpt.com "Handbook:X86/Working/EnvVar - Gentoo Wiki"
[3]: https://www.linuxtopia.org/online_books/introduction_to_linux/linux_The_profile.d_directory.html?utm_source=chatgpt.com "Linux - The profile.d directory"
[4]: https://github.com/void-linux/void-packages/issues/8613?utm_source=chatgpt.com "GDM doesnt load profile file · Issue #8613 · void-linux/void-packages"
[5]: https://askubuntu.com/questions/65563/how-do-i-set-an-environment-variable-at-boot-time-via-a-script?utm_source=chatgpt.com "How do I set an environment variable at boot time (via a script)?"
[6]: https://docs.voidlinux.org/config/services/user-services.html?utm_source=chatgpt.com "Per-User Services - Void Linux Handbook"
[7]: https://unix.stackexchange.com/questions/186431/possible-to-pass-env-vars-into-chpst-without-envdir?utm_source=chatgpt.com "Possible to pass env vars into chpst without envdir?"
[8]: https://docs.voidlinux.org/config/graphical-session/wayland.html?utm_source=chatgpt.com "Wayland - Void Linux Handbook"
[9]: https://docs.voidlinux.org/config/session-management.html?utm_source=chatgpt.com "Session and Seat Management - Void Linux Handbook"
[10]: https://askubuntu.com/questions/866161/setting-path-variable-in-etc-environment-vs-profile?utm_source=chatgpt.com "Setting PATH variable in /etc/environment vs .profile"
