# Opensuse

> distro linux

<!-- toc -->

- [General](#general)
- [Install Guide](#install-guide)
- [Tumbleweed](#tumbleweed)
  - [After Install](#after-install)
- [Opensuse Server](#opensuse-server)

<!-- tocstop -->

## General

[Main:Dell Precision 5530 Setup](https://en.opensuse.org/Main:Dell_Precision_5530_Setup)

## Install Guide

> Version focused on Tumbleweed

- Download distro iso: https://www.opensuse.org/
- Check iso integrity (checksum)[^1]. Example:

```sh
sha256sum -c openSUSE-Tumbleweed-NET-x86_64-Snapshot20240813-Media.iso.sha256
```

- Verify the GPG signature (see [^1])

```sh
gpg --recv-keys 0xAD485664E901B867051AB15F35A2F86E29B700A4
gpg --fingerprint "openSUSE Project Signing Key <opensuse@opensuse.org>"
gpg --verify openSUSE-Tumbleweed-NET-x86_64-Snapshot20240815-Media.iso.sha256.asc openSUSE-Tumbleweed-NET-x86_64-Snapshot20240815-Media.iso
```

- [usb-flash-installation-medium](./usb-flash-installation-medium.md)

- [opensuse-tumbleweed-partition-table](./opensuse-tumbleweed-partition-table.md)
  - [SDB:Encrypted root file system](https://en.opensuse.org/SDB:Encrypted_root_file_system)
    - If swap partition: LUKS + LVM
      - or will have to type password twice
      - one for `/` and other for the swap partition

- [opensuse-tumbleweed-installation-settings](./opensuse-tumbleweed-installation-settings.md)

## Tumbleweed

- [swap-file-on-btrfs](/it/linux/btrfs-swapfile.md)

> https://en.opensuse.org/Portal:Tumbleweed

To keep Tumbleweed upgraded to the latest snapshot using zypper:

```sh
zypper dup
```

### After Install

```sh
sudo zypper refresh
sudo zypper dup
```

Add entire Packman repository:

http://packman.links2linux.org/mirrors

```txt
http://mirror.karneval.cz/pub/linux/packman/
rsync://mirror.karneval.cz/packman
http://ftp.fau.de/packman/
http://ftp.halifax.rwth-aachen.de/packman/
http://ftp.gwdg.de/pub/linux/misc/packman/
ftp://ftp.fau.de/packman/
ftp://ftp.halifax.rwth-aachen.de/packman/
ftp://ftp.gwdg.de/pub/linux/misc/packman/
rsync://ftp.halifax.rwth-aachen.de/packman
```

test speed

```sh
while read -r url; do echo -n "$url: "; curl -s -w '%{speed_download}\n' -o /dev/null "${url}suse/openSUSE_Tumbleweed/repodata/repomd.xml"; done < packman_mirrors.txt
```

```sh
zypper ar -cfp 90 http://ftp.gwdg.de/pub/linux/misc/packman/suse/\
openSUSE_Tumbleweed/ packman
zypper dup --from packman --allow-vendor-change
```

Use Zypper to Refresh Repositories:

Run the command zypper refresh --gpg-auto-import-keys. This command will refresh all repositories and automatically import any new GPG keys without prompting for user confirmation. This is a convenient way to ensure that all necessary keys are updated and trusted.


NVIDIA drivers that work with dkms (NVIDIA's modules will be automatically recompiled for each new kernel update):

```sh
zypper ar -f https://download.opensuse.org/\
repositories/home:/Bumblebee-Project:/nVidia:/latest/\
openSUSE_Tumbleweed/home:Bumblebee-Project:nVidia:latest.repo
zypper in dkms-nvidia
```


## Opensuse Server

**GENERAL NOTES:**

- zypper: opensuse zypper package manager (install from rpm too, as fedora)[^opsu2]
    - --non-interactive means that the command is run without asking anything
    - `sudo zypper rm --clean-deps PACKAGE_NAME` automatically want to remove any packages that become unneeded

**AFTER INSTALL:**[^opsu1]

things to do after install opensuse

1. Update System

`sudo zypper ref && sudo zypper up`

2. Add Community Repositories: opensuse site, additional packages repositories
    - Packman (install it) https://en.opensuse.org/Additional_package_repositories#Packman
    `sudo zypper ar -cfp 90 'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_$releasever/' packman`
    - After adding packman repository be sure to switch system package to those in packman as a mix of both can cause a variety of issues.
        - `sudo zypper dup --from packman --allow-vendor-change`
3. Install build essentials (`make`, etc...)
    ```
    sudo zypper install -y patterns-devel-base-devel_basis
    ```

---

[^1]: https://en.opensuse.org/SDB:Download_help#Checksums "SDB:Download help: Checksums"
