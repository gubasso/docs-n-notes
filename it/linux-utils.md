# Linux General Utilities

- bleach bit: clear system and browser files
- dupeguru: find and clear duplicate files
- qdirstat: stats for files and directories, find big files and directories

## sxhkd

Script to kill and refresh keybindings (shortcuts). Can be used in vim, after save file.[^5](gubasso/references)

```
killall sxhkd; setsid sxhkd &
```

with vim

```
autocmd BufWritePost *sxhkdrc !killall sxhkd; setsid sxhkd &
```

- [Check if Directory is Mounted in Bash](https://www.baeldung.com/linux/bash-is-directory-mounted)
    - to use with gocryptfs, script to check if vault is already mounted

