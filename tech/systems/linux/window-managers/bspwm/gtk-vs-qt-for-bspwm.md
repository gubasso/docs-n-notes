# GTK vs Qt for bspwm

**Short answer: Prioritize GTK, but support both.**

| Factor             | GTK                        | Qt                  |
| ------------------ | -------------------------- | ------------------- |
| WM ecosystem fit   | Native feel                | Works fine          |
| Theming ease       | lxappearance               | Needs qt5ct/qt6ct   |
| Dependencies       | Lighter                    | Pulls more libs     |
| Your current stack | thunar, lxappearance, rofi | -                   |
| App quality        | Good                       | Often more polished |

## Recommendation

```text
Primary: GTK apps
- File manager: thunar (GTK)
- Image viewer: feh, gpick (GTK)
- Settings: lxappearance (GTK)

Support Qt for specific apps you need:
- Keep qt5ct/qt6ct installed
- Set QT_QPA_PLATFORMTHEME=qt5ct
- Use kvantum for Qt theming consistency
```

### Why GTK-first for WM setups

1. Most bspwm/i3/WM tooling is GTK or toolkit-agnostic
2. Simpler theming (one place: lxappearance)
3. Fewer dependencies
4. The "riced WM" aesthetic community leans GTK

### But don't avoid Qt entirely

Some Qt apps are simply better:

- KeePassXC (Qt) > alternatives
- qBittorrent (Qt)
- OBS (Qt)
- Some pro tools

Just install `qt5ct`, `qt6ct`, and optionally `kvantum` to make Qt apps match your GTK theme.
