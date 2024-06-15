# Pass / Gopass

> passoword manager

<!-- toc -->

- [Start](#start)
- [Generator](#generator)
- [Organization / Naming convention](#organization--naming-convention)
- [Import](#import)
- [Basic usage](#basic-usage)
  - [Adding Secrets](#adding-secrets)
  - [Edit a secret](#edit-a-secret)
- [Resources](#resources)

<!-- tocstop -->

vim/neovim config:

```
" gopass security: https://github.com/gopasspw/gopass/blob/master/docs/setup.md#securing-your-editor
au BufNewFile,BufRead /dev/shm/gopass.* setlocal noswapfile nobackup noundofile
```

## Start

- new password store

```sh
# personal
gopass init
# another store
gopass init --store my-company
```

- add git remote

```sh
gopass git remote add origin git@gh.com/Woile/keys.git
gopass git remote add --store my-company origin git@gh.com/Woile/keys.git
```

- sync with remotes

```sh
# all
gopass sync
# just a store
gopass sync --store my-company
```

## Generator

- [Restricting the characters in generated passwords](https://github.com/gopasspw/gopass/blob/master/docs/features.md#restricting-the-characters-in-generated-passwords)

## Organization / Naming convention

- password-store organization / convention
  - https://github.com/browserpass/browserpass-extension#organizing-password-store
  - dir is caps letter / pass lower case

**fields / layout / template**

- password: first, no key, or: (alias `k`)
  - `password:`
  - `pass:`
  - `secret:`
  - `key:`
- username: (alias `n`)
  - `username:`
  - `login:`
  - `user:`
- url: (alias `l`)
  - `url`
  - `link`
- notes/comments: free text: (alias `c`)
  - `comments:`
- credit cards:
```
#:
exp:
cvc:
```

## Import

Import from another password manager (e.g. KeepassXC):

- https://github.com/roddhjav/pass-import#readme

## Basic usage

### Adding Secrets

```sh
gopass insert golang.org/gopher
gopass generate golang.org/gopher
```

### Edit a secret

```sh
gopass edit golang.org/gopher
```

## Resources

- Work with teams/company, share / sharing:
  - [Storing team passwords with gopass](https://hceris.com/storing-passwords-with-gopass/)
  - [Batch bootstrapping](https://github.com/gopasspw/gopass/blob/master/docs/setup.md#batch-bootstrapping)
  - [Team sharing](https://woile.github.io/gopass-cheat-sheet/)
- [GOPASS CHEAT SHEET](https://woile.github.io/gopass-cheat-sheet/)


