# Linux General Utilities

## sxhkd

Script to kill and refresh keybindings (shortcuts). Can be used in vim, after save file.[^5](gubasso/references)

```
killall sxhkd; setsid sxhkd &
```

With vim
```
autocmd BufWritePost *sxhkdrc !killall sxhkd; setsid sxhkd &
```

