# Debian packaging

<!-- toc -->

- [Pre-Requisites](#pre-requisites)
- [General](#general)
- [Overview](#overview)
- [Resources](#resources)

<!-- tocstop -->

## Pre-Requisites

**Follow: [Packaging Pre-Requisites]**

- You MUST have a Debian unstable (`sid`)
- For arch linux: Option 1: Systemd Nspawn and Debspawn
  - follow:
    - https://wiki.debian.org/Packaging/Pre-Requisites/nspawn
    - https://wiki.archlinux.org/title/Systemd-nspawn#Create_a_Debian_or_Ubuntu_environment

At [Packaging Pre-Requisites: nspawn] `Install required packages and enable networking service`...
Setup the root filesystem using mmdebstrap

```sh
sudo debootstrap --include=systemd-container,auto-apt-proxy,sudo unstable /var/lib/machines/debian-sid
```

At [Arch wiki: nspawn Debian or Ubuntu]:
Set the root password, run _systemd-nspawn_ without the `-b` option:

```sh
# host
sudo systemd-nspawn -D /var/lib/machines/debian-sid
# in debian-sid, as root
passwd
logout
```

Install dependencies and utilities:

```sh
apt-get update -y && apt-get upgrade -y
apt-get install -y neovim sudo debconf locales
```

Follow the steps to setup users and groups from [[server-vps]].

Follow the steps to setup hostname and hosts [[server-vps]].


Boot into the container / login in the machine:

```sh
sudo systemd-nspawn --bind=/home/gubasso/Projects:/home/sid/Projects -b -D /var/lib/machines/debian-sid
```

- -b option will boot the container (i.e. run systemd as PID=1), instead of just running a shell
- -D specifies the directory that becomes the container's root directory.

The container can be powered off by running `poweroff`.

At [Packaging Pre-Requisites]: Configuring locales
- but follows this [Setup locale]


## General

- Software available to all users

```
/usr/local/bin/
```

- Where apt/package managers installs 99% of software / packages

```
/usr/bin
```

- System related software/utilities
- System essential distribution files

```
/bin
```

- Generate the package:

```
# at $HOME/debpkgs
> ls
my-program_version_architecture

# run this command referencing my-program_version_architecture directory
> dpkg-deb --build my-program_version_architecture
```

- To install a package

```
dpkg -i my-program_version_architecture.deb
```

- To search if the `.deb` is already installed

```
gdebi my-program_version_architecture.deb
```

> What is a metapackage?

It doesn't install a debian package itself. It is a debian package with a set of dependencies, that install all of the dependencies.

## Overview

- Package metadata

```
$HOME/debpkgs/my-program_version_architecture/DEBIAN/control
```

- Pre / Post instalation scripts

```
$HOME/debpkgs/my-program_version_architecture/DEBIAN/preinst
$HOME/debpkgs/my-program_version_architecture/DEBIAN/postinst
  # postinst needs permission to be set to 755
```

Inside our package directory: `MYPKG=$HOME/debpkgs/my-program_version_architecture`

```
# at $MYPKG
> ls
DEBIAN
usr

> cd usr
# at $MYPKG/usr
> ls
bin
share

> cd bin
# at $MYPKG/usr/bin
> ls
my_binary_file

> cd ..
> cd share
# at $MYPKG/usr/share
> ls
applications
icons

> cd icons
# at $MYPKG/usr/share/icons
> ls
my_program-icon.xpm

> cd ..
> cd applications
# at $MYPKG/usr/share/applications
> ls
my_program.desktop
```


## Resources

- [Playlist: make debian package - socool sun](https://www.youtube.com/playlist?list=PLcTpn5-ROA4wd3dBSW7j1m1MKFhDjqZk1)
- [A beginner's guide to debian packaging - DebConf Videos](https://www.youtube.com/watch?v=fr_5n2hJ2eU)

[Packaging Pre-Requisites]: https://wiki.debian.org/Packaging/Pre-Requisites "Debian wiki: Packaging Pre-Requisites"
[Packaging Learn]: https://wiki.debian.org/Packaging/Learn "Debian wiki: Packaging Learn"
[Building Tutorial]: https://wiki.debian.org/BuildingTutorial "Debian wiki: Building Tutorial"
[Packaging Pre-Requisites: nspawn]: https://wiki.debian.org/Packaging/Pre-Requisites/nspawn "Debian wiki: Packaging Pre-Requisites nspawn"
[Arch wiki: nspawn Debian or Ubuntu]: https://wiki.archlinux.org/title/Systemd-nspawn#Create_a_Debian_or_Ubuntu_environment "Arch wiki: systemd-nspawn: Create a Debian or Ubuntu environment"
[Setting up Sid Development Environment for Debian Packaging]: https://wiki.abrahamraji.in/creating-a-sid-env.html "Abraham's Braindump: Setting up Sid Development Environment for Debian Packaging"
[Simple Packaging Tutorial: The Long Version]: https://wiki.abrahamraji.in/simple-packaging-tutorial.html "Abraham's Braindump: Simple Packaging Tutorial: The Long Version"
[Setup locale]: https://wiki.archlinux.org/title/installation_guide#Localization "Arch wiki: Installation guide: 3.4 Localization"
