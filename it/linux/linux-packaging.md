# Linux Packaging


## Debian packages

### General

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

### Overview

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


- [Playlist: make debian package - socool sun](https://www.youtube.com/playlist?list=PLcTpn5-ROA4wd3dBSW7j1m1MKFhDjqZk1)

