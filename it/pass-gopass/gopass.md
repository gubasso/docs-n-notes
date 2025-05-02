## Gopass

This step-by-step guide is designed to help you get started with **gopass**, a Git-based password manager. You'll find everything from the initial setup to best practices for organization and sharing.

---

## Prerequisites

* Git installed and configured.
* An SSH key configured for accessing remote repositories.
* `gopass` installed (see [official installation guide](https://github.com/gopasspw/gopass#installation)).

---

## 1. Configuring the Editor

By default, `gopass edit` opens the editor defined in `$EDITOR`, or `$VISUAL` if `$EDITOR` is unset.

1. **Set environment variables**:

```bash
export EDITOR="nano"
export VISUAL="vim"
```

2. **Via gopass configuration**:

```bash
gopass config edit.editor "nano --rcfile ~/.config/gopass/nanorc"
```

### Make your editor secure

**For Vim/Neovim users**: disable swap and backup files for temporary gopass buffers:

```vim
au BufNewFile,BufRead /dev/shm/gopass.* setlocal noswapfile nobackup noundofile
```

- https://github.com/gopasspw/gopass/blob/master/docs/setup.md#securing-your-editor

**For NANO users**: disable backup files for temporary gopass buffers:

- [Nano Setup for Gopass](./nano-setup.md)

---

## 2. Creating or Cloning a Store

### 2.1 Creating a New Store

* **Default (personal)**:

```bash
gopass init
```

* **Additional store**:

```bash
gopass init --store my-company
```

> ⚠️ **Attention:** After initializing a new or existing store, navigate into its Git repository and run:
>
> ```bash
> git config --local --unset core.sshCommand
> ```
>
> This prevents conflicts when using multiple SSH keys across different stores.

### 2.2 Cloning an Existing Store

```bash
# Clone default store
gopass clone git@example.com/pass.git

# Clone into a custom mount point 'work'
gopass clone git@example.com/pass-work.git work
```

---

## 3. Basic Operations

### 3.1 Adding Passwords

* **Step-by-step**:

- Auto organizes

```bash
gopass new
```

* **Insert manually**:

```bash
gopass insert example.com/service
```

* **Generate a random password**:

```bash
gopass generate example.com/service
```

### 3.2 Editing an Entry

```bash
gopass edit example.com/service
```

### 3.3 Syncing with Remotes

* **All stores**:

```bash
gopass sync
```

* **Specific store**:

```bash
gopass sync --store my-company
```

### 3.4 Removing a Store/Mount

```bash
gopass mounts remove <store-name>
```

---

## 4. Password Generator

Customize generated passwords with flags:

```bash
# Example: 16 characters, allowing only specific symbols
gopass generate --length 16 --symbols "!@#$%" example.com/service
```

See the [character restrictions documentation](https://github.com/gopasspw/gopass/blob/master/docs/features.md#restricting-the-characters-in-generated-passwords).

---

## 5. Organization and Naming Conventions

Use clear, consistent hierarchies:

```
personal/
  email/
  finance/
work/
  project-x/
  infrastructure/
```

**Field aliases**:

* `password` (alias `p`)
* `username` (alias `u`)
* `url` (alias `l`)
* `comments` (alias `c`)
* `totp` (alias `t`)

**Example template**:

```yaml
password: <your-password>
username: <your-username>
url: https://<service>
totp: <your-totp-secret>
comments: |
  Any additional notes here.
```

---

## 6. Importing from Another Password Manager

Migrate from KeePassXC or similar:

```bash
# Example using a CSV exported from KeePassXC:
gopass import csv keepass-export.csv
```

For more formats, see the [pass-import tool](https://github.com/roddhjav/pass-import#readme).

---

## 7. Additional Resources

* **Team sharing and bootstrapping**:

  * [Storing team passwords with gopass](https://hceris.com/storing-passwords-with-gopass/)
  * [Batch bootstrapping](https://github.com/gopasspw/gopass/blob/master/docs/setup.md#batch-bootstrapping)
  * [Team usage cheatsheet](https://woile.github.io/gopass-cheat-sheet/)
* **Official documentation**: [https://github.com/gopasspw/gopass](https://github.com/gopasspw/gopass)

