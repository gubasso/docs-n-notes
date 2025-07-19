# Arch Linux Install

> Installation guide: https://wiki.archlinux.org/title/Installation_guide

## 1.5 Set the console keyboard layout and font

- Set bigger font

```
setfont solar24x32
```

## 1.9 Partition the disks

- Follow: [Partition Disk](../partition-disk.md)

## 2.1 Select the mirrors

```sh
reflector -c Brazil -c "United States" --verbose --latest 50 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

```/etc/pacman.conf
ParallelDownloads = 7
[multilib]
Include = /etc/pacman.d/mirrorlist
```

## 2.2 Install essential packages

- [Essential Packages](./essential-packages.txt)

## 3.6 Initramfs

- Continue at [LVM on LUKS: 4.4 Configuring mkinitcpio](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Configuring_mkinitcpio_3)

## 3.8 Boot loader

- Continue at [LVM on LUKS: 4.5 Configuring the boot loader](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Configuring_mkinitcpio_3)

Get "device-UUID" with command:

```sh
# /dev/sdaX is encrypted device
blkid -o value -s UUID /dev/sdaX
```

On Arch Linux most users add kernel parameters to `GRUB_CMDLINE_LINUX_DEFAULT`, like `cryptdevice=...`.

- See [Boot loader](./boot-loader.md)
