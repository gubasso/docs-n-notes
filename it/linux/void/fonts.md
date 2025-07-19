# Fonts on Void

When you install fonts from Void’s repositories, **you don’t need to run `fc-cache -fv` yourself**—XBPS does it for you. However, if you drop font files into your local or system font directories by hand, you must rebuild the cache manually (or via `xbps-reconfigure`).

## 1. Fonts installed via XBPS

Void’s font packages include a **post-install hook** that:

1. Builds the `fonts.dir` and `fonts.scale` files under `/usr/share/fonts…`
2. Runs `fc-cache` to update fontconfig’s cache immediately after each package is installed ([github.com][1]).

You’ll see lines like:

```
Building /usr/share/fonts/TTF/fonts.dir...
Building /usr/share/fonts/TTF/fonts.scale...
Updating fontconfig's cache...
```

…in the `xbps-install` output. No further action is required.

## 2. Fonts installed manually

If you copy or symlink `.ttf`/`.otf` files into `/usr/share/fonts` or `~/.local/share/fonts`, fontconfig won’t notice them until you rebuild its cache. You have two options:

* **Run fc-cache directly**

  ```bash
  fc-cache -fv
  ```

  The `-f` flag forces rebuilding (even if up to date) and `-v` shows progress; this rescans all directories in your fontconfig config ([man.voidlinux.org][2]).

* **Reconfigure the fontconfig package**

  ```bash
  ln -s /usr/share/fontconfig/conf.avail/70-*.conf /etc/fonts/conf.d/
  xbps-reconfigure -f fontconfig
  ```

  This reruns fontconfig’s install scripts (including cache rebuild) system-wide ([docs.voidlinux.org][3]).

---

**Bottom line:**

* **XBPS-installed fonts:** no manual cache step needed.
* **Hand-installed fonts:** run `fc-cache -fv` or `xbps-reconfigure -f fontconfig`.

[1]: https://github.com/void-linux/xbps/issues/551 "Optimize \"Updating fontconfig's cache...\" · Issue #551 · void-linux/xbps · GitHub"
[2]: https://man.voidlinux.org/fc-cache "fc-cache (1) - Void Linux manpages"
[3]: https://docs.voidlinux.org/config/graphical-session/fonts.html "Fonts - Void Linux Handbook"
