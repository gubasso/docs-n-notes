# Zsh

<!--toc-->

## gubasso's config

### Starship

- Very, very fast to load.

### zinit: Plugin manager

- https://github.com/zdharma-continuum/zinit
- [This Zsh config is perhaps my favorite one yet.](https://www.youtube.com/watch?v=ud7YxC33Z3w)

```sh
zinit zstatus
```

##### Plugins

```sh
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
```

### Startup files

> https://wiki.archlinux.org/title/Zsh#Startup/Shutdown_files

```
1) `/etc/zsh/zshenv`: First zsh file to load
2) `$ZDOTDIR/.zshenv`: Second zsh file to load
  2.1) `/etc/ambarconfig/env.sh`
  2.2) `$XDG_CONFIG_HOME/shell_env_vars`
3) `$ZDOTDIR/.zprofile`
  3.1) `$HOME/.profile`
4) `$ZDOTDIR/.zshrc`
  4.1) `$XDG_CONFIG_HOME/shell_alias`
```

### Login Shell vs Non-Login Shell in Zsh

Before we dive into whether the files you listed are loaded in a login or non-login shell, let's clarify the difference between the two:

1. **Login Shell:**

- A **login shell**  is the first shell session you start when you log in to a computer. This can be through a terminal, SSH session, or a console login. When you start a new session in these ways, you are initiating a login shell.
- A login shell reads specific configuration files in a defined order:
  - `/etc/zsh/zshenv`
  - `$ZDOTDIR/.zshenv`
  - `/etc/zsh/zprofile`
  - `$ZDOTDIR/.zprofile`
  - `/etc/zsh/zshrc`
  - `$ZDOTDIR/.zshrc`
  - `/etc/zsh/zlogin`
  - `$ZDOTDIR/.zlogin`
- When a login shell exits, it reads:
  - `$ZDOTDIR/.zlogout`
  - `/etc/zsh/zlogout`

2. **Non-Login Shell:**

- A **non-login shell**  is any shell session that is started by another shell (e.g., opening a new terminal tab or window) without logging in again.
- A non-login shell typically reads fewer configuration files, such as:
  - `/etc/zsh/zshenv`
  - `$ZDOTDIR/.zshenv`
  - `/etc/zsh/zshrc`

### Analyzing the Loaded Files

Now, let’s look at the list of files you provided and determine if they belong to a login shell or a non-login shell.

#### List of Files and Their Order:

1. **`/etc/zsh/zshenv`:**
  - **Loaded in Both:**  Always loaded in both login and non-login shells. This file is read first and is used to set environment variables.

2. **`$ZDOTDIR/.zshenv`:**
  - **Loaded in Both:**  Also loaded in both login and non-login shells after `/etc/zsh/zshenv`.

3. **`/etc/ambarconfig/env.sh`:**
  - **Not Standard, Custom Configuration:**  This is not a standard zsh configuration file. If this is sourced within `$ZDOTDIR/.zshenv`, it would still be loaded in both login and non-login shells because it’s being included by a file that’s loaded in both cases.

4. **`$ZDOTDIR/.zprofile`:**
  - **Loaded in Login Shell Only:**  Loaded only in login shells. This file is typically used for commands that should run only once, like setting the PATH or other environment variables.

5. **`$HOME/.profile`:**
  - **Loaded in Login Shell Only:**  This is a traditional shell configuration file typically sourced by `$ZDOTDIR/.zprofile` if it exists and is configured to do so.

6. **`$XDG_CONFIG_HOME/shell_alias`:**
  - **Custom Configuration:**  If this file is sourced within `.profile` or `.zprofile`, it will be loaded in a login shell.

7. **`$XDG_CONFIG_HOME/shell_env_vars`:**
  - **Custom Configuration:**  Similarly, if this file is sourced within `.profile` or `.zprofile`, it will be loaded in a login shell.

8. **`$ZDOTDIR/.zshrc`:**
  - **Loaded in Both:**  This file is loaded in both login and non-login shells. It’s used for shell-specific settings, aliases, functions, and other configurations that need to be present in every interactive shell.

### Conclusion

- **Login Shell Files in Your List:**
  - `$ZDOTDIR/.zprofile`
  - `$HOME/.profile`
  - `$XDG_CONFIG_HOME/shell_alias` (if sourced in `.profile` or `.zprofile`)
  - `$XDG_CONFIG_HOME/shell_env_vars` (if sourced in `.profile` or `.zprofile`)

- **Files Loaded in Both Login and Non-Login Shells:**
  - `/etc/zsh/zshenv`
  - `$ZDOTDIR/.zshenv`
  - `/etc/ambarconfig/env.sh` (assuming it’s sourced in `.zshenv`)
  - `$ZDOTDIR/.zshrc`

## General

fast plugin manager: https://github.com/zdharma-continuum/zinit

- Found existing alias for "cd ..". You should use: "cd.."
- color suggestion (gree ok, red not ok)
- autosuggestions like fish
- https://starship.rs/ - Starship Prompt
- pacman install: `zsh-completions`

### Oh My Posh: A prompt theme engine for any shell

- https://ohmyposh.dev/
- [We may have killed p10k, so I found the perfect replacement.](https://www.youtube.com/watch?v=9U8LCjuQzdc)
- https://github.com/dreamsofautonomy/zen-omp
  - `zen.toml`

```zsh
eval "$(oh-my-posh init zsh --config $XDG_CONFIG_HOME/ohmyposh/zen.toml)"
```

## References:

[^1]: [zsh - create a minimal config (autosuggestions, syntax highlighting etc..) no oh-my-zsh required](https://www.youtube.com/watch?v=bTLYiNvRIVI)
