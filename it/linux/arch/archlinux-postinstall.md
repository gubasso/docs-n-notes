# Arch linux post install

- Follow: https://wiki.archlinux.org/title/General_recommendations

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
