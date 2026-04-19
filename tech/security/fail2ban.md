# Fail2Ban

<!-- toc -->

- [Instalation](#instalation)
  - [On Ubuntu/Debian:](#on-ubuntudebian)
  - [Check status](#check-status)
- [Basic configuration](#basic-configuration)
- [(optional) Config to send email alerts](#optional-config-to-send-email-alerts)
- [References / Guides](#references--guides)

<!-- tocstop -->

Use Fail2Ban for SSH Login Protection

## Instalation

### On Ubuntu/Debian:

```sh
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt install fail2ban
```

### Check status

- Check status (it should be disabled/inactive):

```sh
sudo systemctl status fail2ban.service
```

## Basic configuration

```sh
cd /etc/fail2ban
sudo cp jail.conf jail.local
```

If you changed the SSH default port (e.g. `Port 202`), edit the `[sshd]` section at `jail.local`[^1]:

**`/etc/fail2ban/jail.local`**
```
[sshd]
port = ssh,202
```

Run and check the config:

```sh
sudo systemctl enable fail2ban --now
sudo fail2ban-client status
```

---

## (optional) Config to send email alerts

- install sendmail

- https://www.linode.com/docs/guides/running-a-mail-server/#sending-email-on-linode

**`/etc/fail2ban/jail.local`**
```
destemail = myuseremail@email.com
sender = myuseremail@email.com
```

## References / Guides

- https://www.digitalocean.com/community/tutorials/how-to-protect-ssh-with-fail2ban-on-ubuntu-20-04

[^1]: https://serverfault.com/a/509730
