# Arch Linux Install Notes
> archlinux

**[2. Installation 2.2. Install essential packages](https://wiki.archlinux.org/title/installation_guide#Install_essential_packages)**

```
pacstrap /mnt <list of packages>
```

**[3. Configure the system 3.2. Chroot](https://wiki.archlinux.org/title/installation_guide#Chroot)**

- after chroot:
- execute reflector/paralleldownloads, same from session above: [2. Installation 2.1. Select the mirrors](https://wiki.archlinux.org/title/installation_guide#Select_the_mirrors)

**[3. Configure the system 3.3	Time zone](https://wiki.archlinux.org/title/installation_guide#Time_zone)**

```
timedatectl list-timezones | grep Sao_Paulo
```

**[3. Configure the system 3.4	Localization](https://wiki.archlinux.org/title/installation_guide#Localization)**

```
ls /usr/share/kbd/consolefonts/
```

```/etc/vconsole.conf
KEYMAP=br-abnt2
FONT=iso01-12x22
```

**[3. Configure the system 3.5	Network configuration](https://wiki.archlinux.org/title/installation_guide#Network_configuration)**

```/etc/hosts
127.0.0.1        localhost
::1              localhost
127.0.1.1        myhostname
```

- Install extra packages

```
pacman -Syu ([^1]: ## pacman list 1)
```

**[3. Configure the system 3.6	Initramfs](https://wiki.archlinux.org/title/installation_guide#Initramfs)**

- Before execute this session

```/etc/mkinitcpio.conf
HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)
```

```
mkinitcpio -P
```

**[3. Configure the system 3.8	Boot loader](https://wiki.archlinux.org/title/installation_guide#Boot_loader)**

```
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
```

- find encrypted partition uuid with command `blkid`
- copy uuid of /dev/sda2 (encrypted partition)

```/etc/default/grub
GRUB_CMDLINE_LINUX="cryptdevice=UUID=device-UUID:cryptlvm root=/dev/MyVolGroup/root"
```

```
grub-mkconfig -o /boot/grub/grub.cfg
```

- Before reboot

```
systemctl enable NetworkManager
```

## General Recommendations

**[1	System administration 1.1	Users and groups](https://wiki.archlinux.org/title/General_recommendations#Users_and_groups)**

- list shells /etc/shells

```
useradd -m gubasso -s /bin/zsh
passwd gubasso
gpasswd -a gubasso wheel
visudo
```

- swapfile arch wiki

https://wiki.archlinux.org/title/Zsh
https://archlinux.org/packages/extra/any/grml-zsh-config/

install paru
pacman -Syu && paru -Syu ([^1]: ## aur packages)

lock screen (sflock)

https://wiki.archlinux.org/title/Laptop
https://wiki.archlinux.org/title/Power_management#Power_management_with_systemd
https://wiki.archlinux.org/title/Power_management#Suspend_and_hibernate

touchpad touch click
mouse revert scroll

https://wiki.archlinux.org/title/List_of_applications

Arch Linux Monthly Install: January 2022
https://youtu.be/7btEUHjECAo

dropbox
keepassxc
load backup
.bashrc install cli programs (zsh)
vimrc install plugins
kalu for check updates
script reflector autoRun daily
https://wiki.archlinux.org/title/Uncomplicated_Firewall
https://github.com/sahib/rmlint
https://github.com/lahwaacz/Scripts/blob/master/rmshit.py
https://borgbackup.readthedocs.org/en/stable/

https://wiki.archlinux.org/title/List_of_applications


First shred the disk using the shred tool:
shred -v -n1 /dev/sdX




## Resources

[^1]: [LVM on LUKS Encryption Install](https://youtu.be/kD3WC-93jEk)

