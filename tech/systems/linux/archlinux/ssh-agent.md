# SSH Agent on Arch Linux

On **current Arch**, you typically **do not need to create**
`~/.config/systemd/user/ssh-agent.service`.

The **official `openssh` package ships systemd _user_ units**:

- `/usr/lib/systemd/user/ssh-agent.service`
- `/usr/lib/systemd/user/ssh-agent.socket` ([Arch Linux][1])

A common gotcha is checking it as a _system_ unit (`systemctl status ssh-agent.service`) instead of
a _user_ unit (`systemctl --user …`). ([bbs.archlinux.org][2])

### Quick verification (on your machine)

```bash
pacman -Ql openssh | grep -E '/usr/lib/systemd/user/ssh-agent\.(service|socket)$'
systemctl --user cat ssh-agent.service
systemctl --user cat ssh-agent.socket
```

### Enable it (recommended: socket activation)

```bash
systemctl --user enable --now ssh-agent.socket
```

Then ensure clients can find the socket (e.g., `~/.config/environment.d/ssh-agent.conf`):

```conf
SSH_AUTH_SOCK=%t/ssh-agent.socket
```

If you need custom environment (e.g., `DISPLAY` for askpass from user services), prefer a drop-in
override instead of creating your own unit:

```bash
systemctl --user edit ssh-agent.service
```

[1]: https://archlinux.org/packages/core/x86_64/openssh/files/ "Arch Linux - openssh 10.2p1-2 (x86_64) - File List"
[2]: https://bbs.archlinux.org/viewtopic.php?id=290339 "[SOLVED] No ssh-agent.service systemd unit / System Administration / Arch Linux Forums"
