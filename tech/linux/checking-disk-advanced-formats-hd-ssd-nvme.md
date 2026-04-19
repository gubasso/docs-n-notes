# Checking Disks Advanced Format

## Summary

To verify that your Advanced Format HDDs are presenting the best logical sector size, you can inspect the kernel’s block device queue settings via sysfs or use the `lsblk` utility to display both logical and physical sector sizes for each device ([superuser.com][1], [pieterbakker.com][2]). For NVMe SSDs, the `nvme-cli` package provides the `nvme id-ns` (Identify Namespace) command, which lists all supported LBA formats along with a “Relative Performance” metric so you can see which logical block size offers the best throughput ([man.archlinux.org][3], [wiki.archlinux.org][4]). You can pinpoint the currently active format and its data size directly in the command’s output under the “LBA Format” entries ([unix.stackexchange.com][5]). Additionally, before creating partitions, running `parted /dev/sdX print` or `fdisk -l /dev/sdX` will show the device’s logical and physical sector settings as reported by partitioning tools ([wiki.archlinux.org][6], [wiki.archlinux.org][7]).

---

## Checking Advanced Format HDDs

### 1. Using `lsblk`

Run:

```bash
lsblk -o NAME,SIZE,PHY-SEC,LOG-SEC
```

This outputs each block device’s name, total size, physical sector size (`PHY-SEC`) and logical sector size (`LOG-SEC`) ([pieterbakker.com][2]). Ensure that `LOG-SEC` ≥ `PHY-SEC` (e.g., 4096B/4096B) to avoid translation overhead ([wiki.archlinux.org][4]).

### 2. Inspecting sysfs

Each block device exposes its sector sizes under `/sys/block`. For `/dev/sdX`, check:

```bash
cat /sys/block/sdX/queue/logical_block_size
cat /sys/block/sdX/queue/physical_block_size
```

These files report the logical and physical block sizes in bytes as the kernel sees them ([superuser.com][1]).

### 3. Via Partitioning Tools

Before partitioning, you can confirm sector sizes with:

```bash
sudo parted /dev/sdX print
```

or

```bash
sudo fdisk -l /dev/sdX
```

Both commands will display a line similar to “Sector size (logical/physical): 512B/4096B” or “4096B/4096B”, indicating whether the drive is optimally configured ([wiki.archlinux.org][6], [wiki.archlinux.org][7]).

---

## Checking NVMe SSDs

### 1. Install and Use `nvme-cli`

First, install the utility:

```bash
sudo pacman -S nvme-cli
```

Then issue an Identify Namespace command:

```bash
sudo nvme id-ns /dev/nvme0n1 | grep -E "LBA Format|Relative Performance"
```

or with human-readable output:

```bash
nvme id-ns -H /dev/nvme0n1 | grep "Relative Performance"
```

This shows each supported LBA format, its data size (e.g., 512 bytes or 4096 bytes), and a relative performance rating (0=best, higher=worse) ([wiki.archlinux.org][4], [man.archlinux.org][3]).

### 2. Interpreting the Output

A sample snippet might look like:

```
LBA Format  0 : Data Size: 512 bytes  – Relative Performance: 0x2 Good (in use)
LBA Format  1 : Data Size: 4096 bytes – Relative Performance: 0x1 Better
```

Here, “Data Size” is your logical sector size. The active format is marked “(in use)”, and the lower the “Relative Performance” value, the faster that format performs ([unix.stackexchange.com][5]).

### 3. Confirm with `lsblk` (Optional)

After selecting or formatting to a new logical block size, re-run `lsblk -o NAME,PHY-SEC,LOG-SEC` to verify that `LOG-SEC` matches the intended setting (e.g., both 4096) ([unix.stackexchange.com][8]).

---

## Next Steps

* **If the sizes are mismatched or suboptimal** on an HDD, you’ll need to back up data and repartition/format so that `LOG-SEC` and `PHY-SEC` align (usually 4096 bytes on Advanced Format drives) ([wiki.archlinux.org][4]).
* **For NVMe SSDs**, changing the FLBAS (formatted LBA size) often requires a secure erase or vendor-specific format operation. ArchWiki recommends doing this *before* partitioning, since changing LBA size destroys all data on the namespace ([wiki.archlinux.org][9]).

[1]: https://superuser.com/questions/121252/how-do-i-find-the-hardware-block-read-size-for-my-hard-drive "How Do I Find The Hardware Block Read Size for My Hard Drive?"
[2]: https://pieterbakker.com/optimal-disk-alignment-with-parted/ "Optimal Disk Alignment for Partitioning with Parted"
[3]: https://man.archlinux.org/man/nvme-id-ns.1.en "nvme-id-ns (1) — Arch manual pages"
[4]: https://wiki.archlinux.org/title/Advanced_Format "Advanced Format - ArchWiki"
[5]: https://unix.stackexchange.com/questions/683269/how-to-understand-the-output-of-the-nvme-command "How to understand the output of the nvme command?"
[6]: https://wiki.archlinux.org/title/Parted "Parted - ArchWiki"
[7]: https://wiki.archlinux.org/title/Fdisk "fdisk - ArchWiki"
[8]: https://unix.stackexchange.com/questions/725394/nvme-ssd-should-fs-block-size-be-the-physical-reported-sector-or-the-logical-on "NVMe SSD: Should fs block size be the physical reported sector or the ..."
[9]: https://wiki.archlinux.org/title/Solid_state_drive/Memory_cell_clearing "Solid state drive/Memory cell clearing - ArchWiki"
