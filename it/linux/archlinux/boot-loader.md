# Boot loader

## TL;DR (what happens next)

1. **Mount or confirm the EFI System Partition (ESP) is mounted** at `/efi` (or `/boot/efi`).
2. **Run `grub-install`** – with different flags depending on UEFI *vs.* legacy BIOS.
3. **Add your kernel parameters** (`cryptdevice=… root=…`, plus anything like `quiet`) in `/etc/default/grub`.
4. \*\*Ensure the `encrypt` and `lvm2` hooks (and any others you need) are in `/etc/mkinitcpio.conf`, then rebuild the initramfs.
5. **Generate `grub.cfg`** with `grub-mkconfig`.
6. (Optional but wise) **Install the CPU microcode package** (`intel-ucode` or `amd-ucode`) and list it as the *first* `initrd` in the GRUB entry.
7. **Reboot, enter your LUKS passphrase, and enjoy Arch.** ([Arch Linux Wiki][1], [Arch Linux Wiki][1], [Arch Linux Wiki][1], [Arch Linux Wiki][2], [Arch Linux Wiki][3])

---

## 1. Mount the ESP (UEFI machines only)

When following the Installation Guide, after formatting your partitions you are instructed to mount the ESP directly at `/boot` inside the new system (`/mnt/boot` on the live medium):

```bash
mount /dev/<ESP-partition> /boot  # or /efi, or /boot/efi – pick one and be consistent
```

The ESP must be mounted *inside the chroot* before you run `grub-install`, because that command copies `grubx64.efi` into `$ESP/EFI/<ID>/` and writes a NVRAM entry via `efibootmgr`. ([Arch Linux Wiki][1])

---

## 2. Run **`grub-install`**

### • UEFI systems

```bash
grub-install --target=x86_64-efi \
             --efi-directory=/boot \
             --bootloader-id=GRUB
```

This copies the GRUB EFI binary to `$ESP/EFI/GRUB/` and creates the `GRUB` boot entry in firmware. ([Arch Linux Wiki][1], [Arch Linux Wiki][1])

### • Legacy BIOS (MBR) systems

```bash
grub-install --target=i386-pc /dev/sdX
```

Replace `/dev/sdX` with the *entire* disk (not a partition). ([Arch Linux Wiki][1], [Arch Linux Wiki][4])

> **Tip:** If you are uncertain which firmware mode you booted in, use `ls /sys/firmware/efi` – an existing directory means UEFI. Otherwise you are in BIOS/CSM mode.

---

## 3. Add kernel parameters in **`/etc/default/grub`**

Open the file and append the parameters to `GRUB_CMDLINE_LINUX_DEFAULT` —for everyday boots—or to `GRUB_CMDLINE_LINUX` if you also want them applied to fallback/rescue entries:

```bash
GRUB_CMDLINE_LINUX_DEFAULT="quiet cryptdevice=UUID=<device-UUID>:cryptlvm root=/dev/MyVolGroup/root"
```

After saving, these options will be injected into every menu entry when you regenerate `grub.cfg` (next step). ([Arch Linux Wiki][1], [Arch Linux Wiki][5])

---

## 4. Re-create the initramfs with the right hooks

Edit `/etc/mkinitcpio.conf`:

```bash
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems fsck)
```

At minimum you need **`encrypt`** (to unlock LUKS) and **`lvm2`** (if root sits in an LVM LV). Then rebuild:

```bash
mkinitcpio -P        # or mkinitcpio -g /boot/initramfs-linux.img
```

([Arch Linux Wiki][2], [Arch Linux Wiki][6])

---

## 5. Generate the GRUB menu

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

This scans `/etc/default/grub`, all installed kernels, microcode images, and creates a complete menu. Re-run it any time you change kernels or GRUB settings. ([Arch Linux Wiki][5])

---

## 6. Add early-microcode (optional but recommended)

Install the appropriate package **inside the chroot**:

```bash
pacman -S intel-ucode      # Intel
pacman -S amd-ucode        # AMD
```

`grub-mkconfig` will automatically prepend `/boot/intel-ucode.img` or `/boot/amd-ucode.img` as the first `initrd` line so the microcode loads before the main kernel. ([Arch Linux Wiki][3], [Arch Linux Wiki][7])

---

## 7. Final checks & reboot

* Verify the new NVRAM entry: `efibootmgr -v` (UEFI only).
* Confirm that `/boot` (and `/efi` if separate) contain `grub` directories.
* Exit the chroot, unmount, `reboot`.

At the GRUB screen you should be prompted for the LUKS passphrase; afterward, the system should switch to your root LV and continue booting normally. If anything fails, use the fallback entry (it omits `autodetect`) or the live USB’s *arch-chroot* environment to fix typos in kernel parameters or hooks. ([Arch Linux Wiki][8])

---

[1]: https://wiki.archlinux.org/title/GRUB?utm_source=chatgpt.com "GRUB - ArchWiki"
[2]: https://wiki.archlinux.org/title/Dm-crypt/System_configuration?utm_source=chatgpt.com "dm-crypt/System configuration - ArchWiki"
[3]: https://wiki.archlinux.org/title/Microcode?utm_source=chatgpt.com "Microcode - ArchWiki"
[4]: https://wiki.archlinux.org/title/GRUB/Tips_and_tricks?utm_source=chatgpt.com "GRUB/Tips and tricks - ArchWiki"
[5]: https://wiki.archlinux.org/title/Kernel_parameters?utm_source=chatgpt.com "Kernel parameters - ArchWiki"
[6]: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system?utm_source=chatgpt.com "dm-crypt/Encrypting an entire system - ArchWiki"
[7]: https://wiki.archlinux.org/title/User%3AAlad/Beginners%27_guide?utm_source=chatgpt.com "User:Alad/Beginners' guide - ArchWiki"
[8]: https://wiki.archlinux.org/title/GRUB/EFI_examples?utm_source=chatgpt.com "GRUB/EFI examples - ArchWiki"
