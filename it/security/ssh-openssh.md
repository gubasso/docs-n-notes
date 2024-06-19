# SSH / Openssh

<!-- toc -->

- [Basic access](#basic-access)
- [Resources:](#resources)
- [Copying the public key to the remote server](#copying-the-public-key-to-the-remote-server)
- [Config Server](#config-server)
- [Config Client](#config-client)
  - [Managing multiple keys/identities[^2]](#managing-multiple-keysidentities2)
  - [Naming Conventions](#naming-conventions)
  - [Unorganized](#unorganized)
- [Generate new ssh key](#generate-new-ssh-key)
- [Generate public SSH key from private SSH key[^1]](#generate-public-ssh-key-from-private-ssh-key1)
- [ssh-agent](#ssh-agent)
  - [Agent forwarding](#agent-forwarding)
  - [Tools for ssh-agent](#tools-for-ssh-agent)

<!-- tocstop -->

## Basic access

Examples:

```sh
ssh root@<fqdn>
ssh -p 202 root@<ip-address>
```

- access without loading config from `.ssh/config`

```sh
ssh -v -F /dev/null -o PreferredAuthentications=password <user>@<server>
```

- force to use one specific key[^4]:

```sh
ssh -v -p 22 -F /dev/null -o IdentitiesOnly=yes -i ~/.ssh/<private_key>
```

## Resources:

- [Secure Secure Shell](https://stribika.github.io/2015/01/04/secure-secure-shell.html)
  - awesome article about security ssh
  - a lot of best practice

## Copying the public key to the remote server

From `local`[^3]:

```
# if local user_name is the same of server's
ssh-copy-id <server>
# if different user names
ssh-copy-id <server_user_name>@<server>
# if want to specify the identityfile and/or ports
ssh-copy-id -i <private_identity_file> -p 221 <user_name>@<server>
```

## Config Server

- check applied configs, run command:

```
sudo systemctl restart sshd && sudo sshd -T
```

- Just update config:

```
systemctl reload sshd
```

- Set config:

```
systemctl restart sshd
```

## Config Client

### Managing multiple keys/identities[^2]

**`~/.ssh/config`**
```
Match host=SERVER1
   IdentitiesOnly yes
   IdentityFile ~/.ssh/id_rsa_IDENTITY1

Match host=SERVER2,SERVER3
   IdentitiesOnly yes
   IdentityFile ~/.ssh/id_ed25519_IDENTITY2
```

### Naming Conventions

`[project/service]-[role/purpose]-[tier]-[location]-[user]`

1. **Project/Service**: The name of the project or service the server is associated with.
2. **Role/Purpose**: The role or primary function of the server (e.g., web, db, git).
3. **Tier**: The environment or stage (e.g., prod, staging, dev).
4. **Location**: If applicable, the geographical location or data center.
5. **User**: The primary user or role accessing the server.
6. **Uniqueness**

### Unorganized

**`~/.ssh/config`**
```
host gitolit
    user git
    hostname a.long.server.name.or.annoying.IP.address
    port 22
    identityfile ~/.ssh/id_rsa
```

- `port` and `identityfile` lines are needed only if you have non-default values
- `ssh gitolite` = `ssh git@a.long.server.name`
- `git clone gitolite:reponame` = `git clone git@a.long.server.name:reponame`

Or to manage multiple keys access:

**`~/.ssh/config`**
```
host gitolite
    user git
    hostname gitolite.mydomain.com
    port 22
    identityfile ~/.ssh/sitaram

host gitolite-sh
    user git
    hostname gitolite.mydomain.com
    port 22
    identityfile ~/.ssh/id_rsa
```

---

Example of sending a command through ssh:

```
ssh gubasso@projects.cwnt.io 'mkdir -p cadelab-api-backend'
```

- Persistent ssh connection:
    - https://eternalterminal.dev/
    - https://www.tomshardware.com/amp/how-to/persistent-ssh-connections-linux-eternal-terminal

OpenSSH Full Guide - Everything you need to get started! [https://youtu.be/YS5Zh7KExvE]

https://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/
https://askubuntu.com/questions/4830/easiest-way-to-copy-ssh-keys-to-another-machine

https://www.ssh.com/ssh/protocol/
https://www.ssh.com/ssh/key/
https://www.ssh.com/ssh/keygen/
https://www.ssh.com/iam/ssh-key-management/
https://www.ssh.com/products/universal-ssh-key-manager/
https://www.ssh.com/ssh/authorized_keys/
https://www.ssh.com/ssh/config/
https://www.ssh.com/ssh/sshd/
https://www.ssh.com/ssh/sshd_config/
https://www.ssh.com/ssh/command/
https://www.ssh.com/ssh/openssh/
https://www.ssh.com/ssh/copy-id

https://infosec.mozilla.org/guidelines/openssh
https://stribika.github.io/2015/01/04/secure-secure-shell.html

## Generate new ssh key

Generate without comment:

```
ssh-keygen -f ~/.ssh/<myname>-ed25519 -t ed25519 -a 100 -C ''
ssh-keygen -t rsa -b 4096 -a 100 -C ''
```


## Generate public SSH key from private SSH key[^1]

**Check for pub key:**

With the public key missing, the following command will show you that there is no public key for this SSH key.

```
$ ssh-keygen -l -f ~/.ssh/id_rsa
test is not a public key file.
```
- `-l` option instructs to show the fingerprint in the public key while the
- `-f` option specifies the file of the key to list the fingerprint for.

**generate the missing public key again from the private key:**


```
ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub
Enter passphrase:
```
- `-y` option will read a private SSH key file and prints an SSH public key to stdout.

## ssh-agent

You can kill ssh-agent by running:

```
eval "$(ssh-agent -k)"
```

### Agent forwarding

SSH agent forwarding allows you to use your local keys when connected to a server. It is recommended to only enable agent forwarding for selected hosts.

Setup to use `ssh-agent` to remote access a server:

```
at local (my cpu): ~/.ssh/config
---
# By host
Host <fqdn>
    ForwardAgent yes

# or for everybody
ForwardAgent yes
  Host XXX
    <configs>
    ...
  Host YYY
    <configs>
    ...
  ...
```



### Tools for ssh-agent

ssh-agent and gpg-agent: https://github.com/funtoo/keychain


[^1]: [Generate public SSH key from private SSH key](https://blog.tinned-software.net/generate-public-ssh-key-from-private-ssh-key/)
[^2]: [SSH keys (ArchWiki)](https://wiki.archlinux.org/title/SSH_keys)
[^3]: `local`: your local machine, notebook, computer...
[^4]: https://superuser.com/questions/772660/howto-force-ssh-to-use-a-specific-private-key "How to force ssh to use a specific private key?"
