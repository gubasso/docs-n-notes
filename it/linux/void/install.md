# Void Linux

- set bigger font

```
setfont solar24x32
```

- [connect to internet using `wpa_cli -i interface`](../connect-to-internet-using-wpa-cli-i-interface.md)


## Partition

See: [Partition Disk](../partition-disk.md)

## [System installation](https://docs.voidlinux.org/installation/guides/fde.html#system-installation)

UEFI systems will have a slightly different package selection...

```sh
xbps-install -Sy -R https://repo-default.voidlinux.org/current -r /mnt base-system cryptsetup grub-x86_64-efi lvm2 \
  NetworkManager neovim
```
## Post Install

- [Install and configure NetworkManager](./networkmanager-install-and-configure-on-void.md)
- [Setup NetworkManager DNS resolv](./networkmanager-choosing-the-right-dns-strategy-for-void-linux-symlink-openresolv-or-systemd-resolved.md)
- [Custom keymap Caps Lock ESC switch](./custom-keymap-caps-lock-esc-switch.md)

#### [Cron](https://docs.voidlinux.org/config/cron.html)

- [Choosing CRON Deamon for Void](./choosing-cron-deamon-for-void.md)
- Choice for now: `dcron`

#### [Date and Time](https://docs.voidlinux.org/config/date-time.html)

- NTP client choice: Chrony[^5]

### Windown Manager

- Dependencies:
  - elogind, turnstile, dinit (make turnstile declarative)

#### Fonts

- [Fonts on Void](./fonts.md)

### After Window Manager

- mpv, vlc
- exec niri --session
  - can use this to start a session (without the need to wrap it on a d-bus explicitily, because turnstile started a dbus session for the user before login)

#### Battery / TLP

- https://docs.voidlinux.org/config/power-management.html

#### Firewall

- https://docs.voidlinux.org/config/network/firewalls.html

#### updates

- rustup update

#### Misca

- splash screen plymouth?


### To doc


---

[^1]: https://docs.voidlinux.org/installation/live-images/partitions.html
[^2]: ../checking-disk-advanced-formats-hd-ssd-nvme.md
[^3]: https://wiki.archlinux.org/title/EFI_system_partition#Create_the_partition
[^4]: https://docs.voidlinux.org/installation/guides/fde.html
[^5]: ./choose-ntp-clients-on-void-linux.md "Choose NTP Clients on Void Linux"
