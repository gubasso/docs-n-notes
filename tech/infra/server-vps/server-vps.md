# Server / VPS

<!--TOC-->

- [Create a VPS / Deploy a server](#create-a-vps--deploy-a-server)
- [Initial setup](#initial-setup)
- [Setup users and groups](#setup-users-and-groups)
- [Make commands easier at server](#make-commands-easier-at-server)
- [Security steps](#security-steps)
  - [Harden SSH Access](#harden-ssh-access)
  - [Fail2Ban](#fail2ban)
  - [Setup a firewall](#setup-a-firewall)
- [Related](#related)
- [Resources](#resources)
- [General](#general)

<!--TOC-->

## Create a VPS / Deploy a server

- From a provider: Linode, Vultr, Digital Ocean, Hostinger, Etc...

  - enable ipv6

- connect to server (generally first login is with password)[^2]

## Initial setup

- [linux-general update system](../../systems/linux/linux-system-general.md#update-system)
- [dns setup a DNS](../../infra/networking/dns.md#setup-a-dns)
- (optional) [linux-general set timezone](../../systems/linux/linux-system-general.md#set-timezone)
- [linux-general set hostname](../../systems/linux/linux-system-general.md#set-hostname)
- test: Access server with FQDN[^2]

## Setup users and groups

- (optional) change original root password

```
passwd root
```

- Add new `super_user` and set a password:
  [linux-general users management](../../systems/linux/linux-system-general.md#users-management)
- Create groups and add the `super_user` to them:
  [linux-general group management](../../systems/linux/linux-system-general.md#group-management)

```
groupadd wheel
groupadd sudo
groupadd ssh-user
usermod -aG wheel,sudo,ssh-user super_user
```

- Grant `super_user` root/sudo privileges:
  [linux-general sudo](../../systems/linux/linux-system-general.md#sudo)

```
EDITOR=vim visudo
```

or **`/etc/sudoers.d/99-local-sudoers`**

```
user_name   ALL=(ALL:ALL) ALL
%wheel      ALL=(ALL:ALL) ALL
Defaults passwd_timeout=0
Defaults timestamp_timeout=10
# Comment or delete following:
# Defaults targetpw
# ALL       ALL=(ALL) ALL
```

## Make commands easier at server

- change user: `su super_user`

- make it easier to work with commands

```
~/.bashrc
---
set -o vi
alias n='nvim'
alias sudo='sudo -v; sudo '
alias s='systemctl'
alias ss='sudo systemctl'
alias d='sudo docker'
```

- `alias sudo='sudo -v; sudo '`: Refreshing the timeout

- test open other terminal (or exit) and try to access ssh with new user

  - `ssh super_user@<fqdn>`

## Security steps

### Harden SSH Access

Steps to setup a more secure way to access the server.

**At `local`[^3]:**

- setup agent forwarding:
  [ssh-openssh ssh-agent](../../systems/security/ssh/ssh-openssh.md#ssh-agent)
- Select a `local` ssh identity (key pair) or create a new one[^4]
- Copy this identity to server:
  [ssh-openssh copy public key](../../systems/security/ssh/ssh-openssh.md#copying-the-public-key-to-the-remote-server)
- test if login works: `ssh super_user@<fqdn>`
  - it should not ask for the password

**At `server`[^5]:**

Change user to `root`:

```
sudo su
```

Check if config file has (or add at the beginning) the following line:

**`/etc/ssh/sshd_config`**

```
Include /etc/ssh/sshd_config.d/*.conf
```

**`/etc/ssh/sshd_config.d/99-local-sshd.conf`** (create dir and file if needed)

```
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
# if using gitolite at this server, must have `usepam yes`
UsePAM no
AllowAgentForwarding yes
Port 202
AllowGroups ssh-user
```

- if will be a [gitolite](../../tools/git/gitolite.md) server (see
  [gitolite setup](../../tools/git/gitolite.md#setup)):
  - `usepam yes`
- check applied configs
  ([ssh-openssh config server](../../systems/security/ssh/ssh-openssh.md#config-server)), run
  command:

```sh
# as root
systemctl restart sshd && sshd -T
# as super_user
sudo systemctl restart sshd && sudo sshd -T
```

### Fail2Ban

Change user to `super_user`:

```
su super_user
```

Install and config [fail2ban](../../systems/security/fail2ban.md).

### Setup a firewall

See [firewall](../../infra/networking/firewall.md).

- Install `ufw`
- Run commands to config `ufw` to SSH access at port 202

```sh
sudo ufw default deny
sudo ufw default allow outgoing
sudo ufw allow 202
sudo ufw limit 202
sudo ufw enable
```

Check status

```sh
sudo ufw status
sudo systemctl status ufw
```

## Related

- [# Home Server](./server-vps-home_server.md)

## Resources

- https://www.linode.com/docs/guides/platform/get-started/
- https://www.linode.com/docs/guides/using-your-systems-hosts-file/
- https://www.linode.com/docs/guides/using-fail2ban-to-secure-your-server-a-tutorial/
- https://www.linode.com/docs/guides/running-a-mail-server/
- How to Secure a VPS https://youtu.be/Nuv1mPuHFvg

## General

- https://dokku.com/
  - dokku vs caprover https://www.mskog.com/posts/heroku-vs-self-hosted-paas

to logout the server

- `<C-d>` or type `logout`

find my server/host ip address: `ifconfig`

"PRO TIP - any time you make changes to authentication settings on a system - ssh, pam, sudoers, and
so on - open a second root terminal to that system and leave it open until AFTER you verify your
changes worked correctly, so you don't get locked out of your system."

- proxmox: OS for bare metal manage VMs

[^2]: Access server with ssh
    [ssh-openssh basic access](../../systems/security/ssh/ssh-openssh.md#basic-access)

[^3]: `local`: your local machine, notebook, computer...

[^4]: [ssh-openssh generate new ssh key](../../systems/security/ssh/ssh-openssh.md#generate-new-ssh-key)

[^5]: `server`: remote machine, host, vps...
