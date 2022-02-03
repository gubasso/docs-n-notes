# dwm

## Instalation

```
sudo pacman -Syu {[^2]### pacman dwm}
```

config.h
```
termcmd "alacritty"
```

(Bind the right Alt key to Mod4)
```
#define MODKEY Mod4Mask
```

compile: make && make install

$ cp /etc/X11/xinit/xinitrc ~/.xinitrc
run startx and check if it is ok

**Autostart X at login**

(e.g. ~/.bash_profile for Bash or ~/.zprofile for Zsh)

```
if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  exec startx
fi
```

**Starting**

~/bin/startdwm
while true; do
    # restart dwm without logging out or closing applications
    # Mod-Shift-Q
    # No error logging
    dwm >/dev/null 2>&1
done

~/.xinitrc
setxkbmap -model abnt2 -layout br
setxkbmap -option "caps:swapescape"
exec $HOME/bin/startdwm

end the X session, simply execute
killall xinit, or bind it to a convenient keybind

## References

[1]: [Dave's Visual Guide to dwm](https://ratfactor.com/dwm)
[2]: (./it/archlinux.md)
