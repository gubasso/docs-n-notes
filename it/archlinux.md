



## Packages to install

1) create a text file with the list
2) run/create script with this structure: `sudo pacman -S $(awk '{print $1}'  input_file)` [^1]

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
nerd-fonts-complete

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

### aur packages

apulse
brave-bin
librewolf-bin
asdf-vm

### optional packages (pacman)

starship

## References:

[1]: https://unix.stackexchange.com/questions/587630/how-to-install-packages-with-pacman-from-a-list-contained-in-a-text-file#587698
