# dwm

`dwm` is a small X11 tiling window manager from suckless. It is configured by editing C source,
rebuilding, and installing the resulting binary.

<!-- toc -->

- [Source and build](#source-and-build)
- [Autostart patch](#autostart-patch)
- [Status bar](#status-bar)
- [Applying patches](#applying-patches)
- [Ricing inspiration](#ricing-inspiration)
- [References](#references)

<!-- tocstop -->

## Source and build

dwm source usually lives in a user-managed source checkout. The binary installs to `/usr/local/bin/`
by default.

```bash
cd ~/src/dwm
sudo make clean install
```

Install the X11 build dependencies required by your distribution before compiling.

## Autostart patch

The `autostart` patch runs two scripts on each dwm start:

- `~/.local/share/dwm/autostart_blocking.sh`
- `~/.local/share/dwm/autostart.sh`

Use this when you want WM-coupled daemons, such as a hotkey daemon or compositor, to start and stop
with the dwm session.

## Status bar

The native dwm bar uses the X root-window name, typically set with `xsetroot -name`. Tools such as
`dwmblocks` or `slstatus` can provide dynamic status output.

Signal handling for `dwmblocks`:

```bash
kill -39 "$(pidof dwmblocks)" # signal 5 + 34 = 39
pkill -RTMIN+5 dwmblocks
```

For an optional external bar setup, see [polybar integration](./polybar-dwm-integration.md).

## Applying patches

Use version control to control changes before applying a patch:

```bash
patch < some_patch.diff
git apply some_patch.diff
```

If `patch` fails, it generates `.rej` files showing rejected hunks.

## Ricing inspiration

Reference setups for visual/style inspiration:

- [maxhu08/dwm-rev1](https://github.com/maxhu08/dwm-rev1?tab=readme-ov-file) - dotfiles and theming
  inspiration
- [r/unixporn: dwm my daily driver](https://www.reddit.com/r/unixporn/comments/1nmvdcu/dwm_my_daily_driver/) -
  screenshot and workflow inspiration

## References

- [Arch Wiki: dwm](https://wiki.archlinux.org/title/Dwm)
- [suckless.org/dwm](https://dwm.suckless.org/)
