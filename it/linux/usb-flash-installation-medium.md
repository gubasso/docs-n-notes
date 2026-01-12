# USB flash installation medium

> https://wiki.archlinux.org/title/USB_flash_installation_medium
> https://docs.voidlinux.org/installation/live-images/prep.html

## Practical rule of thumb

* **Updating an already-working Arch ISO USB** (made via `dd`/`cp`/`cat` to the whole device):
  ✅ Just re-write the new ISO to the whole device. No `wipefs`, no `parted`, no `mkfs`.

* **Converting the stick back to normal storage**:
  ✅ `wipefs` + partition + format.


### Minimal “update” procedure (Write / `dd`)

1. Identify the device (verify carefully):

   ```sh
   lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN
   ls -l /dev/disk/by-id/usb-*
   ```

2. Unmount anything auto-mounted:

   ```sh
   sudo umount /dev/disk/by-id/usb-My_flash_drive* 2>/dev/null || true
   ```

3. Write the new ISO to the whole device (no `-partN`):

   ```sh
   sudo dd bs=4M if=/path/to/archlinux-x86_64.iso of=/dev/disk/by-id/usb-My_flash_drive \
     conv=fsync oflag=direct status=progress
   sudo sync
   ```

4. Replug the USB (recommended) so the kernel re-reads the new layout.

### When you would use `wipefs`/partitioning again

Only if you are **restoring the stick for normal storage use** (e.g., single FAT32 partition), or if the device has ended up with confusing remnants from other tooling and you want a clean “storage drive” layout. For simply updating the Arch installer, skip it.

### Small verification checks (optional)

After writing:

```sh
lsblk -f
sudo fdisk -l /dev/disk/by-id/usb-My_flash_drive
```

You should see the ISO’s hybrid layout (often multiple partitions / ISO9660-related entries). That is expected.

If you want, paste the output of `ls -l /dev/disk/by-id/usb-*` and `lsblk -f` (with the USB plugged in) and I’ll point to the exact `by-id` path you should use to avoid hitting the wrong disk.

## Steps from scratch

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
- Has to pop of a message with sucess

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
# updated
sudo mkfs.fat -F 32 /dev/disk/by-id/usb-My_flash_drive-partn
```

Replace `/dev/sdX1` with the appropriate partition name.

This will format the partition you created with `parted` into the specified filesystem. After this step, your USB drive should be ready to use.

To check the partition format:

```sh
lsblk -f
```

List the usb drive:

```sh
ls -l /dev/disk/by-id/usb-*
```

## Write

(Do **not** append a partition number, so do **not** use something like `/dev/disk/by-id/usb-Kingston_DataTraveler_2.0_408D5C1654FDB471E98BED5C-0:0**-part1**` or `/dev/sdb**1**`):

- using [cat(1)](https://man.archlinux.org/man/cat.1):

```
sudo cat path/to/archlinux-version-x86_64.iso > /dev/disk/by-id/usb-My_flash_drive
```

- using [cp(1)](https://man.archlinux.org/man/cp.1):

```
sudo cp path/to/archlinux-version-x86_64.iso /dev/disk/by-id/usb-My_flash_drive
```

- using [dd](https://wiki.archlinux.org/title/Dd "Dd"):

```
sudo dd bs=4M if=path/to/archlinux-version-x86_64.iso of=/dev/disk/by-id/usb-My_flash_drive conv=fsync oflag=direct status=progress
```

- using [tee](https://wiki.archlinux.org/title/Tee "Tee"):

```
sudo tee < path/to/archlinux-version-x86_64.iso > /dev/disk/by-id/usb-My_flash_drive
```

- using [pv](https://archlinux.org/packages/?name=pv):

```
sudo pv path/to/archlinux-version-x86_64.iso -Yo /dev/disk/by-id/usb-My_flash_drive
```

Executing:

```sh
sudo sync
```

...with root privileges after the respective command ensures buffers are fully written to the device before you remove it.

---

## When you *do* need wipefs/partitioning again

You only need the `wipefs` + `parted` + `mkfs` sequence when your goal is **not** “make it boot Arch”, but **restore the USB to normal storage use** (single FAT32/exFAT/ext4 partition, etc.), or if you intentionally want a custom partition scheme.

Also, do those steps if you previously did something like:

* **reformatted** it as a normal storage drive (FAT32/exFAT/ext4) and now want it bootable again, or
* built a **custom multiboot / persistence** layout that you want to recreate cleanly.

In those cases:

* `wipefs --all` is useful to remove confusing leftover signatures,
* then repartition + format as desired.

