# Server / VPS
> $it $server $vps $linux

[toc]

# Related
> `# Server / VPS`

- [# Home Server](./it/server-vps-home_server.md)

# Resources
> `# Server / VPS`

- https://www.linode.com/docs/guides/platform/get-started/
- https://www.linode.com/docs/guides/using-your-systems-hosts-file/
- https://www.linode.com/docs/guides/using-fail2ban-to-secure-your-server-a-tutorial/
- https://www.linode.com/docs/guides/running-a-mail-server/
- How to Secure a VPS https://youtu.be/Nuv1mPuHFvg

# General
> `# Server / VPS`

- https://dokku.com/
    - dokku vs caprover https://www.mskog.com/posts/heroku-vs-self-hosted-paas

to logout the server
- `<C-d>` or type `logout`

find my server/host ip address: `ifconfig`

"PRO TIP - any time you make changes to authentication settings on a system - ssh, pam, sudoers, and so on - open a second root terminal to that system and leave it open until AFTER you verify your changes worked correctly, so you don't get locked out of your system."

- proxmox: OS for bare metal manage VMs

# Setup a server / vps / domain name / security measures
> `# Server / VPS`

- deploy a server / vps (linode, vutr, etc...)
    - enable ipv6
    - update system
      - arch linux
        - `pacman -S archlinux-keyring --noconfirm && pacman -Syyu --noconfirm`
      - ubuntu: `apt update && apt upgrade`
      - opensuse: `sudo zypper ref && sudo zypper dup -y`
    - set timezone:
      - `timedatectl list-timezones`
      - `timedatectl set-timezone 'America/New_York'`
        - us central: America/Chicago
          - dallas/tx
      - for ubuntu/debian:
        - `dpkg-reconfigure tzdata`
      - for opensuse:
        - `yast2 timezone`
    - set hostname:
      - Descriptive and/or Structured (e.g. [purpose]-[number]-[environment] / `web-01-prod`)
      - part of a FQDN (e.g. `web-01-prod.example.com`)
        - full-qualified-domain-name
      - command: `hostnamectl set-hostname example-hostname`
    - `/etc/hosts`
      - FQDN: `example-hostname.example.com`
      - `<ipv4> example-hostname.example.com example-hostname`
      - `<ipv6> example-hostname.example.com example-hostname`
    - `etc/nsswitch.conf`
      - `hosts:          files dns`

- dns records: (e.g. epik / linode dns)
  - A (ipv4) , AAAA (ipv6)
  - FQDN: `example-hostname.example.com`
  - https://www.linode.com/docs/guides/dns-manager/
  - https://www.linode.com/docs/guides/configure-your-linode-for-reverse-dns/
  - (wait to dns propagate)
  - https://dnschecker.org

- access server with `ssh root@landchad.net` or with ip address
- or `ssh -p 202 root@ip`, when specify the port number

## manage security
> `# / ## Setup a server / vps / domain name / security measures`

### change original root password
> `# / ## / ### manage security`

```
passwd root
```

### add a new user and set a password [^l1]
> `# / ## / ### manage security`

**`Arch Linux`**
```
useradd -m user_name -s /bin/bash
passwd user_name
```

- `-m/--create-home`
- The above useradd command will also automatically create a group called user_name and makes this the default group for the user archie. Making each user have their own group (with the group name same as the user name) is the preferred way to add users.

### create and add to group wheel
> `# / ## / ### manage security`

```
groupadd wheel
groupadd sudo
groupadd ssh-user
usermod -aG wheel,sudo,ssh-user user_name
```

### visudo: full root privileges
> `# / ## / ### manage security`

- gain full root privileges [^l2]

`EDITOR=vim visudo`
or
**`/etc/sudoers.d/99-local-sudoers`**
```
user_name   ALL=(ALL) ALL
%wheel      ALL=(ALL) ALL
Defaults passwd_timeout=0
Defaults timestamp_timeout=10
# Comment or delete following:
# Defaults targetpw
# ALL       ALL=(ALL) ALL
```

### make commands easier at server
> `# / ## / ### manage security`

- change user: `su username`

- make it easier to work with commands
```
~/.bashrc
---
set -o vi
alias sudo='sudo -v; sudo '
alias s='systemctl'
alias ss='sudo systemctl'
alias d='sudo docker'
```

- `alias sudo='sudo -v; sudo '`: Refreshing the timeout[^l2].1

- test: exit and try to access ssh with new user `ssh user_name@landchad.net`

### Harden SSH Access
> `# / ## / ### manage security`

(more secure way to access the server)

- config at **my local machine**: Agent forwarding [^l3]
    - SSH agent forwarding allows you to use your local keys when connected to a server. It is recommended to only enable agent forwarding for selected hosts.
        - for `ssh-agent`
```
at local (my cpu): ~/.ssh/config
---
Host myserver.com
    ForwardAgent yes
```

- requisites: have a ssh identity / key pair
- run at local computer:
  - `ssh-copy-id -i [private_identity_file] user_name@landchad.net`
  - to copy local ssh credential to the server
- test if login works `ssh user@host`

- at host (remote), edit

- Better way to configure sshd_config: https://www.reddit.com/r/openSUSE/comments/o9f7ru/ssh_config_on_tumbleweed/

At server, run the commands to enable just the strong type of keys:

```
cd /etc/ssh
sudo rm ssh_host_*key*
sudo ssh-keygen -t ed25519 -f ssh_host_ed25519_key -N "" < /dev/null
sudo ssh-keygen -t rsa -b 4096 -f ssh_host_rsa_key -N "" < /dev/null
```

check for:
```
sudo mkdir -p /etc/ssh/sshd_config.d/
```

add include at beginning:
**`/etc/ssh/sshd_config`**
```
Include /etc/ssh/sshd_config.d/*.conf
```
- Check configs at original **`/etc/ssh/sshd_config`**.
- Check if `sshd_config` has the `Include /etc/ssh/sshd_config.d/*.conf`
At `sshd_config`:
  - remove: `Protocol...` and `HostKey` lines...

```
sudo mkdir -p /etc/ssh/sshd_config.d
```
**`/etc/ssh/sshd_config.d/99-local-sshd.conf`**
```
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
AllowAgentForwarding yes
Port 202
UsePAM no
AllowGroups ssh-user
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
Protocol 2
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
```
- check applyed configs:

```
sudo systemctl restart sshd && sudo sshd -T
```

-  `PermitRootLogin`[^l3][^pn1]
- add users to `ssh-user` group

- check if port 202 will be unbloced https://docs.cloudron.io/security/#securing-ssh-access
(to just update a config, may run `systemctl reload sshd`)
- set config, run `systemctl restart sshd`


At server: (can be configured at client too, within `~/.ssh/config`)

check for:
```
sudo mkdir -p /etc/ssh/ssh_config.d/
```

add include at beginning:
**`/etc/ssh/ssh_config`**
```
Include /etc/ssh/ssh_config.d/*.conf
```

**`/etc/ssh/ssh_config.d/99-local-ssh_config.conf`**
```
# Github needs diffie-hellman-group-exchange-sha1 some of the time but not always.
#Host github.com
#    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1
Host *
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
UseRoaming no
```

### Fail2Ban
> `# / ## / ### manage security`

Use Fail2Ban for SSH Login Protection

- install fail2ban
- install sendmail

```
systemctl enable fail2ban --now
systemctl enable sendmail --now
```

```
cd /etc/fail2ban
sudo cp fail2ban.conf fail2ban.local
sudo cp jail.conf jail.local
```

Check configs with:
```
sudo fail2ban-client status
```

Change configs in `*.local`

- https://www.linode.com/docs/guides/running-a-mail-server/#sending-email-on-linode

**`/etc/fail2ban/jail.local`**
```
destemail = myuseremail@email.com
sender = myuseremail@email.com
```


## Other steps
> `# / ## Setup a server / vps / domain name / security measures`

- install and setup a firewall (e.g. ufw): [Firewall](articles/it-firewall.md)

# VPS Use Cases

**what else do from here?**

- webserver?
- host a backup?
- host some application?

# Nginx: Load balancer / reverse proxy

If using with SSL/Let's encrypt/certbot:...
Better to **NOT** use with docker/container...

Simpler if it is installed directly on system.

- [Nginx installation and config](./nginx.md)
- [certbot](./nginx-certbot.md)

# References

[^1]: [Setting up a Website and Email Server in One Sitting (Internet Landchad) - Luke Smith](https://www.youtube.com/watch?v=3dIVesHEAzc) $server $vps $host


