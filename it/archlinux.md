# Arch Linux
> archlinux

<!-- vim-markdown-toc GFM -->

* [General](#general)
* [Packages to install](#packages-to-install)
    * [pacstrap list](#pacstrap-list)
    * [pacman list 1](#pacman-list-1)
    * [pacman dwm](#pacman-dwm)
    * [aur packages](#aur-packages)
    * [fonts pacman](#fonts-pacman)
    * [fonts aur](#fonts-aur)
    * [optional packages (pacman)](#optional-packages-pacman)
* [References:](#references)

<!-- vim-markdown-toc -->

## General

audio
how to reconize external sound card (usb adapter):
add user to `audio` group
audio card is reconized by `lsusb` but not by `aplay -l`
"The user need to log out and log in again for the effects to be applied."
[Sound card not detected by ALSA, but detected by kernel](https://unix.stackexchange.com/questions/214514/sound-card-not-detected-by-alsa-but-detected-by-kernel)

---

- [How to prevent the keyboard backlight from turning on when the laptop is woken from sleep?](https://askubuntu.com/questions/1028368/how-to-prevent-the-keyboard-backlight-from-turning-on-when-the-laptop-is-woken-f)
- [systemd.service - Service unit configuration : Example](https://jlk.fjfi.cvut.cz/arch/manpages/man/systemd.service.5#EXAMPLES)

```
[Unit]
Description=Turn off keyboard backlight as a default (after boot or resume)
After=multi-user.target
After=suspend.target
After=hibernate.target
After=hybrid-sleep.target
[Service]
# Type=oneshot
# RemainAfterExit=yes
ExecStart=/usr/bin/brightnessctl --device=dell* set 0
[Install]
WantedBy=multi-user.target
WantedBy=suspend.target
WantedBy=hibernate.target
WantedBy=hybrid-sleep.target
```



## Packages to install

1) create a text file with the list
2) run/create script with this structure: `sudo pacman -S $(awk '{print $1}'  input_file)`

install packages from a list https://wiki.archlinux.org/title/Pacman/Tips_and_tricks#Install_packages_from_a_list
```
pacman -S --needed - < pkglist.txt
```


### pacstrap list

base
base-devel
linux
linux-headers
linux-firmware
lvm2
networkmanager
network-manager-applet
vim
neovim
nano
man-db
man-pages
texinfo
intel-ucode
mtools
dosfstools
gvfs
openssh
reflector
rsync
alacritty
tmux
sudo
zsh
zsh-completions
bash-completion
kbd
git
xdg-utils
xdg-user-dirs

### pacman list 1

grub
efibootmgr
dialog
os-prober
sof-firmware
alsa-utils
alsa-plugins
alsa-firmware
alsa-ucm-conf
pulseaudio
pulseaudio-alsa
pulseaudio-bluetooth
pulseaudio-equalizer
pulseaudio-jack
pulseaudio-lirc
pulseaudio-zeroconf
bluez
bluez-utils
pulseaudio-bluetooth
avahi
nss-mdns
cups
mesa
lib32-mesa
xf86-video-intel
vulkan-intel
mesa-utils
htop
wget
pcmanfm
fzf
rg
maim
exa
bat
xclip
fd
rmtrash
libreoffice-fresh
libreoffice-extension-texmaths
libreoffice-extension-writer2latex
hunspell
hunspell-en_us
hyphen
hyphen-en
libmythes
mythes-en
firefox


### pacman dwm

xorg
xorg-xinit
xorg-xrandr
xorg-xsetroot
xorg-xlsfonts
xorg-xev
pamixer
nitrogen
libinput
picom
sxhkd
brightnessctl
acpi

### aur packages

apulse
brave-bin
librewolf-bin
asdf-vm
mons
hunspell-pt-br
hyphen-pt-br
mythes-pt-br
libreoffice-extension-languagetool

### fonts pacman

search for nerd-fonts
```
pacman -Ssq nerd-fonts
```

nerd-fonts-complete
ttf-caladea
ttf-carlito
ttf-dejavu
ttf-liberation
ttf-linux-libertine-g
ttf-inconsolata
ttf-font-awesome
noto-fonts
noto-fonts-emoji
adobe-source-code-pro-fonts
adobe-source-sans-fonts
adobe-source-serif-fonts


### fonts aur

ttf-gentium-basic
ttf-ms-fonts
ttf-twemoji-color

### optional packages (pacman)

starship
zathura
mupdf

## References:

[1]: https://unix.stackexchange.com/questions/587630/how-to-install-packages-with-pacman-from-a-list-contained-in-a-text-file#587698
