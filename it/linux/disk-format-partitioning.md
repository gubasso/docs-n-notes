# Disk Formatting Partitioning

## USB flash installation medium

> https://wiki.archlinux.org/title/USB_flash_installation_medium

Identify the USB Drive

```sh
lsblk
# or
sudo fdisk -l
```

**Note:** To restore the USB drive as an empty, usable storage device after using the Arch ISO image, the ISO 9660 filesystem signature needs to be removed by running:

```sh
sudo wipefs --all /dev/disk/by-id/usb-_My_flash_drive_
```

...as root, before [repartitioning](https://wiki.archlinux.org/title/Repartition "Repartition") and [reformatting](https://wiki.archlinux.org/title/Reformat "Reformat") the USB drive.

Check/Set Partitioning

```sh
sudo parted -s /dev/sdX mklabel msdos mkpart primary fat32 0% 100%
```
- `-s`: Run in script mode, which suppresses interactive prompts.
- `mklabel msdos`: Creates a new MBR (DOS) partition table. You can replace `msdos` with `gpt` if you need a GPT partition table.
- `mkpart primary fat32 0% 100%`: Creates a primary partition starting from 0% to 100% of the disk space and labels it as FAT32. You can replace `fat32` with `ext4`, `ntfs`, etc., depending on the desired file system.

This single command will:

1. Create a new partition table.
2. Create a primary partition covering the entire disk.
3. Label it with the specified file system type.
After running this command, you can then format the partition if necessary using a tool like `mkfs` (e.g., `sudo mkfs.vfat /dev/sdX1` for FAT32). However, the `parted` command above is sufficient for creating the partition structure itself.

The parted command you used creates the partition but does not actually format it with a filesystem. To format the partition (which is necessary to make it usable for storing files), you need to run a command like mkfs.

```sh
sudo mkfs.vfat /dev/sdX1
```

Replace `/dev/sdX1` with the appropriate partition name. If you created an ext4 partition, you would use:

```sh
sudo mkfs.ext4 /dev/sdX1
```

This will format the partition you created with `parted` into the specified filesystem. After this step, your USB drive should be ready to use.

To check the partition format:

```sh
lsblk -f
```

List the usb drive:

```sh
ls -l /dev/disk/by-id/usb-*
```

(Do **not** append a partition number, so do **not** use something like `/dev/disk/by-id/usb-Kingston_DataTraveler_2.0_408D5C1654FDB471E98BED5C-0:0**-part1**` or `/dev/sdb**1**`):

- using [cat(1)](https://man.archlinux.org/man/cat.1):

```
cat path/to/archlinux-version-x86_64.iso > /dev/disk/by-id/usb-My_flash_drive
```

- using [cp(1)](https://man.archlinux.org/man/cp.1):

```
cp path/to/archlinux-version-x86_64.iso /dev/disk/by-id/usb-My_flash_drive
```

- using [dd](https://wiki.archlinux.org/title/Dd "Dd"):

```
dd bs=4M if=path/to/archlinux-version-x86_64.iso of=/dev/disk/by-id/usb-My_flash_drive conv=fsync oflag=direct status=progress
```

- using [tee](https://wiki.archlinux.org/title/Tee "Tee"):

```
tee < path/to/archlinux-version-x86_64.iso > /dev/disk/by-id/usb-My_flash_drive
```

- using [pv](https://archlinux.org/packages/?name=pv):

```
pv path/to/archlinux-version-x86_64.iso -Yo /dev/disk/by-id/usb-My_flash_drive
```

Executing:

```sh
sudo sync
```

...with root privileges after the respective command ensures buffers are fully written to the device before you remove it.
