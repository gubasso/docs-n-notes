# Opensuse

> distro linux

<!-- toc -->

- [Opensuse Server](#opensuse-server)

<!-- tocstop -->

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
