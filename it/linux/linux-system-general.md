# Linux General

> system settings

<!-- toc -->

- [Users management](#users-management)
- [Group management](#group-management)
- [sudo](#sudo)
  - [Edit config](#edit-config)
- [Update System](#update-system)
  - [Ubuntu/Debian](#ubuntudebian)
  - [Arch linux](#arch-linux)
  - [Opensuse Tumbleweed](#opensuse-tumbleweed)
- [Set Timezone](#set-timezone)
  - [Ubuntu/Debian](#ubuntudebian-1)
  - [Opensuse Tumbleweed](#opensuse-tumbleweed-1)
- [Set Hostname](#set-hostname)
- [Resources](#resources)

<!-- tocstop -->

## Users management

- Create/Add user

```sh
useradd -m user_name -s /bin/bash
```
- `-m/--create-home`
- The above useradd command will also automatically create a group called user_name and makes this the default group for the user archie. Making each user have their own group (with the group name same as the user name) is the preferred way to add users.

- Set a user password

```sh
passwd user_name
```

- Delete user (remove user)

```sh
userdel -r <user>
```
- `-r`: delete user's directories


## Group management

- Create/Add new group

```
groupadd <group_name>
```

- Add user to a group

```
usermod -aG <group or group-list> <user_name>
# example
usermod -aG wheel,sudo,ssh-user user_name
```

## sudo

### Edit config

To change `sudo` config:

- Option 1: Edit `sudoers` basic config with `visudo` command:

```
EDITOR=vim visudo
```

- Option 2 (better if available): edit a local config `sudoers` file

```
# file: /etc/sudoers.d/99-local-sudoers
<add your config>
```

## Update System

### Ubuntu/Debian

```sh
apt-get update -y && apt-get upgrade -y
# or
sudo apt-get update -y && sudo apt-get upgrade -y
# or
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
```

### Arch linux

```sh
pacman -S archlinux-keyring --noconfirm && pacman -Syyu --noconfirm
```

### Opensuse Tumbleweed

```
sudo zypper ref && sudo zypper dup -y
```
- `ref` = `refresh`

## Set Timezone

- `timedatectl list-timezones`
- `timedatectl set-timezone 'America/New_York'`
  - us central: America/Chicago
    - dallas/tx
  - us east: America/New York
    - atlanta/ga

### Ubuntu/Debian

`dpkg-reconfigure tzdata`

### Opensuse Tumbleweed

`yast2 timezone`

## Set Hostname

See [[dns#Fully qualified domain name (FQDN)]].

- command: `hostnamectl set-hostname example-hostname`
- edit `/etc/hosts`
  - `<ipv4> example-hostname.example.com example-hostname`
  - `<ipv6> example-hostname.example.com example-hostname`
- check if `etc/nsswitch.conf` has:
  - `hosts:          files dns`

## Resources

- [CompTIA Linux+ Exam Prep (XK0-005 revision) (IN PROGRESS) - Shawn Powers](https://www.youtube.com/playlist?list=PL78ppT-_wOmuwT9idLvuoKOn6UYurFKCp)
