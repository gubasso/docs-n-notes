# Keychain

> ssh-agent, gpg-agent
>
> https://www.funtoo.org/Funtoo:Keychain

<!-- toc -->

- [Basic commands](#basic-commands)
- [gpg-agent](#gpg-agent)
- [Use `keychain` inside a script](#use-keychain-inside-a-script)

<!-- tocstop -->

## Basic commands

Simple command for `ssh-agent`:

```sh
keychain --eval --agents gpg gubasso@eambar.net
eval $(keychain --eval --agents ssh id_rsa)
eval `keychain --eval --agents ssh,gpg gubasso-android-ed25519 gubasso@cwnt.io`
```

The `--clear` option:

- every new login to your account should be considered a potential security breach until proven otherwise
- flushes all your private keys from ssh-agent's cache when you log in
- if you're an intruder, keychain will prompt you for passphrases rather than giving you access to your existing set of cached keys

- `--nogui`
  - Disable the graphical prompt and always enter your passphrase on the terminal
  - allows to copy-paste long passphrases from a password manager for example

- `--noask`
  - do not want to be immediately prompted for unlocking the keys but rather wait until they are needed

- `--agents ssh,gpg`

## gpg-agent

"omit the `--agents ssh` option"

## Use `keychain` inside a script

In a `cron` job, for example:

**`example-script.sh`**
```sh
#!/bin/sh
eval `keychain --noask --eval id_rsa`
```

- `--noask`: should not prompt for a passphrase if one is needed
