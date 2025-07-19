# Void Linux

- set bigger font

```
setfont solar24x32
```

- [connect to internet using `wpa_cli -i interface`](../connect-to-internet-using-wpa-cli-i-interface.md)


## Partition

[Tip: Check that your NVMe drives and Advanced Format hard disk drives are using the optimal logical sector size before partitioning.][^2]

## General skeleton

*UEFI/GPT*

`/dev/sda1    2048    264191    262144  128M EFI System`

- `/boot/efi`
  - type: `EFI System`
  - filesystem: `vfat`
  - Size: 1 GB[^3]
  - Partition type GUID: `C12A7328-F81F-11D2-BA4B-00A0C93EC93B`
  - Code: `EF00`

`/dev/sda2  264192 100663262 100399071 47.9G Linux filesystem`

- (swap)
  - Size: 1,5x RAM[^1]
  - For 64GB RAM -> 96GB swap
- `/` (root)
  - type: `Linux Filesystem`
  - code: `8300`


### Full Disk Encryption[^4]

#### Create a single physical partition on the disk using cfdisk, marking it as bootable.

UEFI systems will need the disk to have a GPT disklabel and an EFI system partition. The required size for this may vary depending on needs, but 100M should be enough for most cases. For an EFI system, the partition layout should look like the following.

```
# fdisk -l /dev/sda
Disk /dev/sda: 48 GiB, 51539607552 bytes, 100663296 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: EE4F2A1A-8E7F-48CA-B3D0-BD7A01F6D8A0

Device      Start       End   Sectors  Size Type
/dev/sda1    2048    264191    262144  128M EFI System
/dev/sda2  264192 100663262 100399071 47.9G Linux filesystem
```

In this example:

- `/dev/sda1`: taken up by the EFI Partition
- `/dev/sda2`: encrypted volume

#### [Encrypted volume configuration](https://docs.voidlinux.org/installation/guides/fde.html#encrypted-volume-configuration)

(...) follow page instructions (...)

#### [System installation](https://docs.voidlinux.org/installation/guides/fde.html#system-installation)

UEFI systems will have a slightly different package selection...

```sh
xbps-install -Sy -R https://repo-default.voidlinux.org/current -r /mnt base-system cryptsetup grub-x86_64-efi lvm2 \
  NetworkManager neovim
```
### Post Install

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
