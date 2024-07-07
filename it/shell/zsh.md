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
3) `$ZDOTDIR/.zprofile`
  3.1) `$HOME/.profile`
    3.1.1) `$XDG_CONFIG_HOME/shell_alias`
    3.1.2) `$XDG_CONFIG_HOME/shell_env_vars`
4) `$ZDOTDIR/.zshrc`

function src() {
  source $ZDOTDIR/{.zshenv,.zshrc,.zprofile}
}
```

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
