# Opensuse Tumbleweed Installation Settings

## Booting

When setting up a new installation of openSUSE Tumbleweed, there are several booting settings to consider, particularly regarding Secure Boot, Trusted Boot, and updating NVRAM. Here are the recommendations based on current information:

### Secure Boot
- **Recommendation**: **Disable Secure Boot** during installation.
- **Reason**: While openSUSE Tumbleweed has made progress in supporting Secure Boot, there are ongoing issues that may require Secure Boot to be disabled, especially for installing firmware updates via `fwupd`[1]. Some users have reported boot issues when Secure Boot is enabled, resulting in a need to toggle it on and off to resolve boot errors[2].

### Trusted Boot
- ENABLE: It allows for LUKS to require just one password
- **Recommendation**: This setting is less commonly discussed in the context of openSUSE Tumbleweed installations. Generally, Trusted Boot is not a requirement for most users and can be left disabled unless specific security policies or requirements dictate otherwise.

### Update NVRAM
- **Recommendation**: **Disable updating NVRAM** during installation.
- **Reason**: By disabling the update of NVRAM, you can prevent the boot order from being overwritten during kernel or bootloader updates. This is particularly useful if you have a specific boot order preference, such as dual-booting with another operating system like Windows[5][6].

These settings help ensure a smoother installation and operation of openSUSE Tumbleweed, particularly in environments where firmware updates and boot order stability are important.

Citations:
[1] https://blog.paranoidpenguin.net/2024/03/opensuse-tumbleweed-needs-to-fix-secure-boot/
[2] https://forums.opensuse.org/t/insane-secure-boot-issue/174345
[3] https://www.reddit.com/r/openSUSE/comments/1cf1szv/tumbleweeds_installer_does_not_boot_with_secure/
[4] https://en.opensuse.org/openSUSE:Tumbleweed_installation
[5] https://forums.opensuse.org/t/grub-resets-efi-entries-order-at-every-startup/153608
[6] https://forums.opensuse.org/t/prevent-kernel-update-from-overwriting-efi-boot-order/151452
[7] https://forums.opensuse.org/t/esp-in-usb/138613
