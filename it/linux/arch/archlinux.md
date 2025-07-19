# Arch Linux

> archlinux

<!-- toc -->

- [Install](#install)
- [Packages / Pacman / AUR](#packages--pacman--aur)
- [General](#general)
- [Packages to install](#packages-to-install)
  - [pacstrap list](#pacstrap-list)
  - [pacman list 1](#pacman-list-1)
  - [pacman dwm](#pacman-dwm)
  - [aur packages](#aur-packages)
  - [fonts pacman](#fonts-pacman)
  - [fonts aur](#fonts-aur)
  - [optional packages (pacman)](#optional-packages-pacman)
- [References:](#references)

<!-- tocstop -->

## Install

- Easy install: [How To Install Arch Linux in 5 Minutes || BRAND NEW EASY Arch Linux Installation Guide 2023 - Ksk Royal](https://www.youtube.com/watch?v=e-4YOymosJo)

## Packages / Pacman / AUR

- system update / arch update:
  - https://github.com/Antiz96/arch-update
  - An update notifier & applier for Arch Linux that assists you with important pre / post update tasks.
Includes a dynamic & clickeable systray applet for an easy integration with any Desktop Environment / Window Manager.


```sh
paru -Sccd
```

## General


timezone
- [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

audio
how to reconize external sound card (usb adapter):
add user to `audio` group
audio card is reconized by `lsusb` but not by `aplay -l`
"The user need to log out and log in again for the effects to be applied."
[Sound card not detected by ALSA, but detected by kernel](https://unix.stackexchange.com/questions/214514/sound-card-not-detected-by-alsa-but-detected-by-kernel)

---

- [How to prevent the keyboard backlight from turning on when the laptop is woken from sleep?](https://askubuntu.com/questions/1028368/how-to-prevent-the-keyboard-backlight-from-turning-on-when-the-laptop-is-woken-f)
- [systemd.service - Service unit configuration : Example](https://jlk.fjfi.cvut.cz/arch/manpages/man/systemd.service.5#EXAMPLES)

```
[Unit]
Description=Turn off keyboard backlight as a default (after boot or resume)
After=multi-user.target
After=suspend.target
After=hibernate.target
After=hybrid-sleep.target
[Service]
# Type=oneshot
# RemainAfterExit=yes
ExecStart=/usr/bin/brightnessctl --device=dell* set 0
[Install]
WantedBy=multi-user.target
WantedBy=suspend.target
WantedBy=hibernate.target
WantedBy=hybrid-sleep.target
```

## Packages to install

1) create a text file with the list
2) run/create script with this structure: `sudo pacman -S $(awk '{print $1}'  input_file)`

install packages from a list https://wiki.archlinux.org/title/Pacman/Tips_and_tricks#Install_packages_from_a_list
```
pacman -S --needed - < pkglist.txt
```

## References:

[1]: https://unix.stackexchange.com/questions/587630/how-to-install-packages-with-pacman-from-a-list-contained-in-a-text-file#587698
