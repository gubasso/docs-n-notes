# Firewall

> firewall, opsec, it

## Instalation

### On ubuntu/debian

```sh
sudo apt-get install ufw -y
```

## General setups

**setup a firewall ufw**[^pn1]
```
sudo ufw default deny
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw limit SSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```
- 'Nginx Full' allows http/https

**general ssh 202**
```
sudo ufw default deny
sudo ufw default allow outgoing
sudo ufw allow 202
sudo ufw limit 202
sudo ufw enable
```

```
sudo ufw default deny
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw limit SSH
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

**cloudron firewall list: https://docs.cloudron.io/security/#cloud-firewall**
```
sudo ufw default deny
sudo ufw default allow outgoing
sudo ufw allow 202
sudo ufw limit 202
sudo ufw allow 222
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 25
sudo ufw allow 465
sudo ufw allow 587
sudo ufw allow 993
sudo ufw allow 3478
sudo ufw allow 4190
sudo ufw allow 5349
sudo ufw allow 50000:51000/tcp
sudo ufw allow 50000:51000/udp
sudo ufw enable
```

- `ufw enable`: only needed once the first time you install the package[^fw1]

- check systemctl ufw status, start and enable `ufw.service`

`sudo ufw app list`: show list of installed apps, can allow or deny by app name
    - e.g. `sudo ufw allow "Nginx full"`

`sudo ufw allow 5000`: if want to test a service at hosted for outside access at port 5000
if want to remove this access after testing, for example: `sudo ufw delete allow 5000`

run `sudo ufw status` to check

**firewalld vs ufw**

- firewall: opensuse firewalld firewall-cmd[^opsu3]
- [Enable and Disable firewalld](https://firewalld.org/documentation/howto/enable-and-disable-firewalld.html)
    - checks if iptables are enabled and disables everything to make shure there will be no conflicts
    - then installs and enables firewalld
- replace firewalld with ufw
    0. How to switch firewalls from FirewallD to UFW[^fw2]
    1. Install UFW packages
    2. Enable UFW
    3. Disable firewalld
    4. Reboot
    5. Remove the firewalld packages

[^pn1]: [Python Flask Tutorial: Deploying Your Application (Option #1) - Deploy to a Linux Server - Corey Schafer](https://www.youtube.com/watch?v=goToXTC96Co)
[^fw1]: [Archwiki: Uncomplicated Firewall ufw](https://wiki.archlinux.org/title/Uncomplicated_Firewall)
[^opsu3]: [Masquerading and firewalls](https://doc.opensuse.org/documentation/leap/security/html/book-security/cha-security-firewall.html#)
[^fw2]: [How to switch firewalls from FirewallD to UFW](https://www.ctrl.blog/entry/firewalld-ufw-migration-tutorial.html)
