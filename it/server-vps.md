# Server / VPS
> $it $server $vps $linux

<!-- vim-markdown-toc GitLab -->

* [Related](#related)
* [General](#general)
* [Setup a server / vps / domain name / security measures](#setup-a-server-vps-domain-name-security-measures)
    * [manage security](#manage-security)
        * [change original root password](#change-original-root-password)
        * [add a new user and set a password [^l1]](#add-a-new-user-and-set-a-password-l1)
        * [create and add to group wheel](#create-and-add-to-group-wheel)
        * [visudo: full root privileges](#visudo-full-root-privileges)
* [Opensuse Server](#opensuse-server)
* [References](#references)

<!-- vim-markdown-toc -->

## Related

- [# Home Server](./it/server-vps-home_server.md) 

## General
> `# Server / VPS`

- https://dokku.com/
    - dokku vs caprover https://www.mskog.com/posts/heroku-vs-self-hosted-paas

- https://caprover.com/
    - CapRover is an extremely easy to use app/database deployment & web server manager for your NodeJS, Python, PHP, ASP.NET, Ruby, MySQL, MongoDB, Postgres, WordPress (and etc...) applications!
    - deploy application (cloudron like? heroku like?)
    - docker

to logout the server
- `<C-d>` or type `logout`

find my server/host ip address: `ifconfig`

"PRO TIP - any time you make changes to authentication settings on a system - ssh, pam, sudoers, and so on - open a second root terminal to that system and leave it open until AFTER you verify your changes worked correctly, so you don't get locked out of your system."


## Setup a server / vps / domain name / security measures
> `# Server / VPS`

- deploy a server / vps (linode, vutr, etc...)
    - enable ipv6
    - hostname: put the domain name with subdomain, like: projects.cwnt.io

- epik, dns host records 
    - External Hosts: A (ipv4) , AAAA (ipv6)
    - host field: subdomain you want
        - normal path: add one with blank host field and other with `www`
            - can add a `*` to... to redirect any subdomain
            - do * if the subdomain is set in the same host vps
    - repeat same pattern to A (ipv4) and AAAA (ipv6) (find ipv6 address at linode)
- (to setup a email server) at server host (e.g. linode) 
    - set ipv6 reverse dns: field `ipv6 number` to `landchad.net`

(wait to dns propagate)
DNS Checker - DNS Check Propagation Tool
https://dnschecker.org

- access server with `ssh root@landchad.net` or with ip address
- or `ssh -p 202 root@ip`, when specify the port number


### manage security 
$opsec


#### change original root password

```
passwd root
```

#### add a new user and set a password [^l1]

**`Arch Linux`**
```
useradd -m user_name -s /bin/bash
passwd user_name
```

- `-m/--create-home`
- The above useradd command will also automatically create a group called user_name and makes this the default group for the user archie. Making each user have their own group (with the group name same as the user name) is the preferred way to add users.

#### create and add to group wheel

```
groupadd wheel
groupadd sudo
usermod -aG wheel,sudo,audio username
```

#### visudo: full root privileges

- gain full root privileges [^l2]

```
EDITOR=vim visudo
---
USER_NAME   ALL=(ALL) ALL
%wheel      ALL=(ALL) ALL
Defaults passwd_timeout=0
Defaults timestamp_timeout=10
# Comment or delete following:
# Defaults targetpw
# ALL       ALL=(ALL) ALL
```

- make it easier to work with commands
```
~/.bashrc
---
set -o vi
alias sudo='sudo -v; sudo '
alias s='systemctl'
alias ss='sudo systemctl'
```

- `alias sudo='sudo -v; sudo '`: Refreshing the timeout[^l2].1
- test: exit and try to access ssh with new user `ssh user_name@landchad.net`

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
- run at local computer: `ssh-copy-id user_name@landchad.net`
    - to copy local ssh credential to the server
- test if login works `ssh user@host`

- at host (remote), edit 

- Better way to configure sshd_config: https://www.reddit.com/r/openSUSE/comments/o9f7ru/ssh_config_on_tumbleweed/

**`/etc/ssh/sshd_config.d/my_conf.conf`**
```
PermitRootLogin no
PubkeyAuthentication yes
UsePAM no
PasswordAuthentication no
ChallengeResponseAuthentication no
Port 202
AllowUsers gubasso ismael
AllowAgentForwarding yes
```
-  `PermitRootLogin`[^l3][^pn1]
- Check configs at original **`/etc/ssh/sshd_config`**.
- Check if `sshd_config` has the `Include /etc/ssh/sshd_config.d/*.conf`

- check if port 202 will be unbloced https://docs.cloudron.io/security/#securing-ssh-access
(to just update a config, may run `systemctl reload sshd`)
- set config, run `systemctl restart sshd`

- set hostname [^pn1]
```
hostnamectl set-hostname myhostname
```

**`/etc/hosts`**
```
# IP-Address  Full-Qualified-Hostname  Short-Hostname
  (ip address from vps)   myhostname
45.56.87.40     projects.cwnt.io        cadelab-linode
2600:3c01::f03c:92ff:fe46:471c  projects.cwnt.io        cadelab-linode
```

- `/etc/hostname` contains name of the machine, as known to applications that run locally.[^l5]
    - e.g. `myhostname`
- `/etc/hosts`: and DNS associate names with IP???addresses.[^l5]
    - `myhostname` may be mapped to whichever IP???address the machine can access itself, but mapping it to 127.0.0.1 is un??sthetic.
- Note that you can use both the /etc/hosts file and a DNS server for name resolution. The content of the hosts file will usually be used for lookups before DNS. If there is no match in the hosts file, then the DNS server will be used. [^l6]

- install and setup a firewall (e.g. ufw): [Firewall](articles/it-firewall.md)

Other resources:

- How to Secure a VPS https://youtu.be/Nuv1mPuHFvg

**what else do from here?**

- webserver?
- host a backup?
- host some application?

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

## References

[^1]: [Setting up a Website and Email Server in One Sitting (Internet Landchad) - Luke Smith](https://www.youtube.com/watch?v=3dIVesHEAzc) $server $vps $host


