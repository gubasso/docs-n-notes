# Reinstall Arch Linux on Existing LUKS + LVM (UEFI + GRUB)

Scope: reuse an existing LUKS container and LVM layout on an existing encrypted partition (no
repartitioning, no new `luksFormat`, no new VG/LVs). Example layout:

```text
<disk>
├─<efi-partition>           /boot (EFI system partition)
└─<luks-partition>  crypto_LUKS
   └─<luks-mapper-name>
      ├─<vg>-root           /
      └─<vg>-swap           [SWAP]
```

Adjust names if your `VG/LV` identifiers differ.

Host-specific values for the `nova` machine live in dotfiles `_docs/hosts/nova/reinstall-guide.md`.

---

## 0. Pre-install checklist

1. Backup any important data from `/` (including `/home` if it lives on `<vg>-root`).
2. Download the latest Arch ISO and write it to USB (see
   [USB flash installation medium](https://wiki.archlinux.org/title/USB_flash_installation_medium)).
3. Ensure the firmware boots in UEFI mode (no Legacy/CSM).

---

## 1. Boot ISO and prepare environment

1. Boot from the Arch ISO (UEFI).

2. Verify UEFI and disks:

   ```bash
   lsblk
   ```

3. Connect to the network (via `iwctl`, `wifi-menu` wrapper, or wired) as described in the Arch
   installation guide. ([Arch Wiki][1])

---

## 2. Unlock existing LUKS container and activate LVM

1. Open the LUKS container (do **not** run `luksFormat`):

   ```bash
   cryptsetup open /dev/<luks-partition> <luks-mapper-name>
   ```

   `<luks-mapper-name>` is the name of the opened container mapper.

2. Activate LVM:

   ```bash
   vgchange -ay
   lvdisplay    # optional, to confirm <vg>-root and <vg>-swap
   ```

   LVM activation and the `lvm2` tooling requirement match the "Install Arch Linux on LVM" guidance.
   ([Arch Wiki][2])

3. Confirm layout:

   ```bash
   lsblk
   ```

   You should now see `/dev/<vg>/root` and `/dev/<vg>/swap` (or equivalent mapper paths).

---

## 3. Recreate filesystems (keep encryption + LVM)

1. Recreate `/boot` (EFI system partition, FAT32 as per UEFI recommendations):
   ([linuxconfig.org][3])

   ```bash
   mkfs.fat -F32 /dev/<efi-partition>
   ```

2. Recreate the root filesystem inside the existing LV:

   ```bash
   mkfs.ext4 /dev/<vg>/root   # or /dev/mapper/<vg>-root
   ```

3. (Optional) Re-initialise swap LV header:

   ```bash
   mkswap /dev/<vg>/swap
   ```

   This matches common LVM-on-LUKS full-disk encryption workflows. ([Gist][4])

---

## 4. Mount target filesystems

1. Mount root:

   ```bash
   mount /dev/<vg>/root /mnt
   ```

2. Mount `/boot` (EFI system partition):

   ```bash
   mount --mkdir /dev/<efi-partition> /mnt/boot
   ```

3. Enable swap:

   ```bash
   swapon /dev/<vg>/swap
   ```

---

## 5. Install base system

Use `pacstrap` to install a minimal system into `/mnt`. ([Arch Linux Manual Pages][5])

```bash
pacstrap -K /mnt base linux linux-firmware lvm2 cryptsetup grub efibootmgr networkmanager
```

- `-K` initializes a new keyring in the target.
- `lvm2` is required so mkinitcpio can include the `lvm2` hook from inside the chroot.
  ([Arch Wiki][2])

---

## 6. Generate fstab and chroot

1. Generate `fstab` using UUIDs:

   ```bash
   genfstab -U /mnt >> /mnt/etc/fstab
   ```

   This mirrors the standard installation workflow. ([linuxconfig.org][3])

2. Enter the new system:

   ```bash
   arch-chroot /mnt
   ```

---

## 7. Basic system configuration

Inside the chroot:

1. Timezone and clock:

   ```bash
   ln -sf /usr/share/zoneinfo/<your-timezone> /etc/localtime
   hwclock --systohc
   ```

2. Locale:

   ```bash
   echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
   locale-gen
   echo "LANG=en_US.UTF-8" > /etc/locale.conf
   ```

3. Hostname:

   ```bash
   echo "<hostname>" > /etc/hostname
   ```

4. vconsole:

   ```bash
   pacman -S terminus-font
   cat > /etc/vconsole.conf << 'EOF'
   KEYMAP=us
   FONT=ter-v32b
   EOF
   ```

   - Later on:
     - "US International with AltGr dead keys": quotes/tilde/apostrophe behave normally, and only
       become dead keys when you press Right-Alt/AltGr with them
     - [US AltGr-International Keymap for Arch Linux TTY (Wayland/KDE Independent)](./keymap-us-altgr-intl.md)

5. Root password:

   ```bash
   passwd
   ```

These steps follow the structure of the official installation guide. ([Arch Wiki][1])

---

## 8. Configure initramfs (mkinitcpio) for encrypted LVM root

1. Ensure `lvm2` and `cryptsetup` are installed inside the chroot (already done with `pacstrap`
   above). ([Arch Wiki][2])

2. Edit `/etc/mkinitcpio.conf` and set a **systemd-based** hooks line suitable for an encrypted root
   plus LVM, based on the upstream mkinitcpio template and current guidance for mkinitcpio ≥ v40:
   ([GitHub][6])

   ```bash
   nano /etc/mkinitcpio.conf
   ```

   Example `HOOKS` line:

   ```text
   HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt lvm2 filesystems fsck)
   ```

   - `sd-encrypt` handles unlocking the LUKS root.
   - `lvm2` must appear **before** `filesystems` to ensure LVs are available when the root
     filesystem is mounted. ([Arch Wiki][2])

3. Regenerate initramfs:

   ```bash
   mkinitcpio -P
   ```

---

## 9. Configure GRUB for encrypted root on LVM

1. Confirm the UUID of your LUKS partition:

   ```bash
   blkid /dev/<luks-partition>
   ```

   Copy the `UUID="..."` value.

   ```bash
   blkid -s UUID -o value /dev/<luks-partition> > /tmp/<luks-partition>.uuid
   ```

2. Edit `/etc/default/grub`:

   ```bash
   nano /etc/default/grub
   ```

   Set (or append to) `GRUB_CMDLINE_LINUX`:

   ```text
   GRUB_CMDLINE_LINUX="cryptdevice=UUID=<luks-uuid>:<luks-mapper-name> root=/dev/<vg>/root"
   ```

   - `cryptdevice=UUID=…:<luks-mapper-name>` tells the initramfs which encrypted device to unlock
     and what mapped name (`/dev/mapper/<luks-mapper-name>`) to use. ([wiki.parabola.nu][7])
   - `root=/dev/<vg>/root` points to the decrypted LVM logical volume that holds the root
     filesystem, matching the form described for LVM-backed encrypted roots. ([Arch Wiki][8])

3. Install GRUB for UEFI:

   ```bash
   grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=<bootloader-id> --recheck
   ```

4. Generate GRUB config:

   ```bash
   grub-mkconfig -o /boot/grub/grub.cfg
   ```

   This flow matches current UEFI + GRUB install practices documented in recent Arch installation
   and LVM guides. ([linuxconfig.org][3])

---

## 10. Finalize and reboot

1. Enable NetworkManager (optional but common):

   ```bash
   systemctl enable NetworkManager
   ```

2. Exit chroot and cleanly unmount:

   ```bash
   exit
   umount -R /mnt
   swapoff /dev/<vg>/swap
   cryptsetup close <luks-mapper-name>
   ```

3. Reboot:

   ```bash
   reboot
   ```

On next boot:

- The initramfs/systemd early boot will prompt for the LUKS passphrase on `/dev/<luks-partition>`.
- After unlocking, LVM will activate `<vg>-root`; the kernel will mount `root=/dev/<vg>/root` and
  continue into your fresh Arch system, using the same encrypted LUKS + LVM structure you had
  before.

- [Postinstall](./postinstall.md)

[1]: https://wiki.archlinux.org/title/Installation_guide?utm_source=chatgpt.com "Installation guide - ArchWiki"
[2]: https://wiki.archlinux.org/title/Install_Arch_Linux_on_LVM?utm_source=chatgpt.com "Install Arch Linux on LVM - ArchWiki"
[3]: https://linuxconfig.org/arch-linux-installation-easy-step-by-step-guide?utm_source=chatgpt.com "Arch Linux Installation Guide: Easy Step-by-Step Instructions"
[4]: https://gist.github.com/jkauppinen/3c437abe64206cafbac45ff2fdd0c478?utm_source=chatgpt.com "Arch linux installation with full disk encryption via dm-crypt + LUKS ..."
[5]: https://man.archlinux.org/man/pacstrap.8?utm_source=chatgpt.com "pacstrap (8) — Arch manual pages"
[6]: https://github.com/archlinux/mkinitcpio/blob/master/mkinitcpio.conf?utm_source=chatgpt.com "mkinitcpio/mkinitcpio.conf at master · archlinux/mkinitcpio · GitHub"
[7]: https://wiki.parabola.nu/Dm-crypt/System_configuration?utm_source=chatgpt.com "dm-crypt/System configuration - ParabolaWiki - Parabola GNU/Linux-libre"
[8]: https://wiki.archlinux.org/title/Dm-crypt/System_configuration?utm_source=chatgpt.com "dm-crypt/System configuration - ArchWiki"
