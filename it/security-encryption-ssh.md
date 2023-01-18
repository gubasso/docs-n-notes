# SSH / Openssh

[toc]

Alias to connect to a server:

## Resources:

- [Secure Secure Shell](https://stribika.github.io/2015/01/04/secure-secure-shell.html)
  - awesome article about security ssh
  - a lot of best practice

## Unorganized

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

### Copying the public key to the remote server

If the remote username is the same of the local one:
```
ssh-copy-id remote-server.org
```

If different usernames:
```
ssh-copy-id username@remote-server.org
```

With different file names and ports:
```
ssh-copy-id -i ~/.ssh/id_ed25519.pub -p 221 username@remote-server.org
```

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

## Generate new ssh key:

Generate without comment:

```
ssh-keygen -f ~/.ssh/<myname>-ed25519 -t ed25519 -a 100 -C ''
ssh-keygen -t rsa -b 4096 -a 100 -C ''
```

Generate public key from private key:

```
ssh-keygen -f ~/.ssh/id_rsa -y > ~/.ssh/id_rsa.pub
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
$ ssh-keygen -y -f ~/.ssh/id_rsa > ~/.ssh/id_rsa.pub
Enter passphrase:
```

- `-y` option will read a private SSH key file and prints an SSH public key to stdout.

## ssh-agent

You can kill ssh-agent by running:

```
eval "$(ssh-agent -k)"
```

https://github.com/funtoo/keychain

"Keychain helps you to manage ssh and GPG keys in a convenient and secure manner. It acts as a frontend to ssh-agent and ssh-add, but allows you to easily have one long running ssh-agent process per system, rather than the norm of one ssh-agent per login session.

This dramatically reduces the number of times you need to enter your passphrase. With keychain, you only need to enter a passphrase once every time your local machine is rebooted. Keychain also makes it easy for remote cron jobs to securely "hook in" to a long running ssh-agent process, allowing your scripts to take advantage of key-based logins."



## References:

[^1]: [Generate public SSH key from private SSH key](https://blog.tinned-software.net/generate-public-ssh-key-from-private-ssh-key/)
[^2]: [SSH keys (ArchWiki)](https://wiki.archlinux.org/title/SSH_keys)



