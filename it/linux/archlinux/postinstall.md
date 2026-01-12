# Arch linux post install

> Follow: https://wiki.archlinux.org/title/General_recommendations

- Grant `super_user` root/sudo privileges: [[linux-general#sudo]]

```
EDITOR=vim visudo
```
or

```sh
sudo EDITOR=nvim visudo -f /etc/sudoers.d/local-sudoers
```

```
user_name   ALL=(ALL:ALL) ALL
%wheel      ALL=(ALL:ALL) ALL
Defaults passwd_timeout=0
Defaults timestamp_timeout=10
Defaults insults
# Comment or delete following:
# Defaults targetpw
# ALL       ALL=(ALL) ALL
```

- `alias sudo='sudo -v; sudo '`: Refreshing the timeout

## Pacman

```sh
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bkp
reflector -c Brazil -c "United States" --verbose --latest 50 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

```/etc/pacman.conf
ParallelDownloads = 7
[multilib]
Include = /etc/pacman.d/mirrorlist
```

## Graphical Interface

- NVIDIA drivers https://wiki.archlinux.org/title/NVIDIA
- Niri WM
  - https://wiki.archlinux.org/title/Niri
  - https://github.com/YaLTeR/niri/

## Nvidia pacman hook

- [pacman hook](https://wiki.archlinux.org/title/NVIDIA#pacman_hook)

## Niri/Nvidia config

- [nvidia-application-profiles-rc.d](https://wiki.archlinux.org/title/NVIDIA#nvidia-application-profiles-rc.d)
  - "For example, niri users can free up to ~2.5GiB of idle vram consumption with the following:"
