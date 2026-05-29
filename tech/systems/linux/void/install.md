# Void Linux

- set bigger font

```bash
setfont solar24x32
```

- Wi-Fi (wpa_supplicant): <https://docs.voidlinux.org/config/network/wpa_supplicant.html>

## Partition

See: <https://docs.voidlinux.org/installation/live-images/partitions.html>

## [System installation](https://docs.voidlinux.org/installation/guides/fde.html#system-installation)

UEFI systems will have a slightly different package selection...

```sh
xbps-install -Sy -R https://repo-default.voidlinux.org/current -r /mnt base-system cryptsetup grub-x86_64-efi lvm2 \
  NetworkManager neovim
```

## Post Install

- [Install and configure NetworkManager](./networkmanager-install-and-configure-on-void.md)
- [Setup NetworkManager DNS resolv](./networkmanager-choosing-the-right-dns-strategy-for-void-linux-symlink-openresolv-or-systemd-resolved.md)

### [Cron](https://docs.voidlinux.org/config/cron.html)

- [Choosing CRON Daemon for Void](./choosing-cron-daemon-for-void.md)
- Choice for now: `dcron`

### [Date and Time](https://docs.voidlinux.org/config/date-time.html)

- NTP client choice: Chrony[^5]

### Windows Manager

- Dependencies:
  - elogind, turnstile, dinit (make turnstile declarative)

#### Fonts

- [Fonts on Void](./fonts.md)

### After Window Manager

- mpv, vlc
- exec niri --session
  - can use this to start a session (without the need to wrap it on a d-bus explicitly, because
    turnstile started a dbus session for the user before login)

#### Battery / TLP

- <https://docs.voidlinux.org/config/power-management.html>

#### Firewall

- <https://docs.voidlinux.org/config/network/firewalls.html>

#### updates

- rustup update

#### Misca

- splash screen plymouth?

### To doc

---

[^5]: ./choose-ntp-clients-on-void-linux.md "Choose NTP Clients on Void Linux"
