# Pass / Gopass

> passoword manager

<!-- toc -->

- [Editor gopass uses](#editor-gopass-uses)
- [!! ATENTION](#-atention)
- [Create a new store](#create-a-new-store)
- [Clone Existing Store](#clone-existing-store)
- [Basic Usage](#basic-usage)
  - [Adding Secrets](#adding-secrets)
  - [Edit a secret](#edit-a-secret)
  - [sync with remotes](#sync-with-remotes)
  - [delete / remove a store/mount](#delete--remove-a-storemount)
- [Password Generator](#password-generator)
- [Organization / Naming convention](#organization--naming-convention)
- [Import](#import)
- [Resources](#resources)

<!-- tocstop -->

## Editor gopass uses

By default, gopass invokes whatever editor is set in $EDITOR (or, if unset, falls back to $VISUAL) when you run gopass edit

```sh
export EDITOR="nano"
export VISUAL="some_other"
```

Or via `gopass config`

```sh
gopass config edit.editor "nano --rcfile ~/.config/gopass/nanorc"
```

- If using `nano`, check this: [[nano-setup-for-gopass]]
- If using `vim`/`neovim`:

```
" gopass security: https://github.com/gopasspw/gopass/blob/master/docs/setup.md#securing-your-editor
au BufNewFile,BufRead /dev/shm/gopass.* setlocal noswapfile nobackup noundofile
```

## !! ATENTION

After setup a new or existing store, run inside the git repo:

```sh
# at $HOME/.local/share/gopass/stores/my-store
git config --local --unset core.sshcommand
```

This will fix multiple ssh ids issues when syncing stores.

## Create a new store

- new password store

```sh
# personal
gopass init
# another store
gopass init --store my-company
```

## Clone Existing Store

```sh
gopass clone git@example.com/pass.git
gopass clone git@example.com/pass-work.git work # a work store
```

## Basic Usage

### Adding Secrets

```sh
gopass insert golang.org/gopher
gopass generate golang.org/gopher
```

### Edit a secret

```sh
gopass edit golang.org/gopher
```

### sync with remotes

```sh
# all
gopass sync
# just a store
gopass sync --store my-company
```

### delete / remove a store/mount

```sh
gopass mounts remove <store-name>
```

## Password Generator

- [Restricting the characters in generated passwords](https://github.com/gopasspw/gopass/blob/master/docs/features.md#restricting-the-characters-in-generated-passwords)

## Organization / Naming convention

- password-store organization / convention
  - https://github.com/browserpass/browserpass-extension#organizing-password-store
  - dir is caps letter / pass lower case

**fields / layout / template**

- default:
  - password: first, no key, or: (alias `p`)
  - username: (alias `u`)
  - url: (alias `l`)

- password: first, no key, or: (alias `p`)
  - `password:`
  - `pass:`
  - `secret:`
  - `key:`
- username: (alias `u`)
  - `username:`
  - `login:`
  - `user:`
- url: (alias `l`)
  - `url`
  - `link`
- notes/comments: free text: (alias `c`)
  - `comments:`
- totp: (alias `t`)
  - `totp`
- credit cards:
```
#:
exp:
cvc:
```

## Import

Import from another password manager (e.g. KeepassXC):

- https://github.com/roddhjav/pass-import#readme


## Resources

- Work with teams/company, share / sharing:
  - [Storing team passwords with gopass](https://hceris.com/storing-passwords-with-gopass/)
  - [Batch bootstrapping](https://github.com/gopasspw/gopass/blob/master/docs/setup.md#batch-bootstrapping)
  - [Team sharing](https://woile.github.io/gopass-cheat-sheet/)
- [GOPASS CHEAT SHEET](https://woile.github.io/gopass-cheat-sheet/)

