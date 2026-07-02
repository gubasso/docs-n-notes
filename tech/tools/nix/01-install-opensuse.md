# 01 — Host install (enable flakes; openSUSE / NixOS)

`nix develop` / flakes need a working install with the **new CLI** enabled. Enable the experimental
features once per user (or system-wide in `/etc/nix/nix.conf`):

```bash
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

Both tokens are required: `nix-command` unlocks the new verbs (`develop`, `flake`); `flakes` unlocks
flake evaluation.

## openSUSE (Tumbleweed) — RPM multi-user daemon

```bash
sudo zypper install nix
sudo systemctl enable --now nix-daemon.socket   # socket-activated daemon
sudo usermod -aG nix-users "$USER"               # RPM gates daemon access on this group
# re-login (or `newgrp nix-users`), then open a new shell
# point Nix at openSUSE's CA bundle (TLS for flake-input downloads):
echo 'ssl-cert-file = /etc/ssl/ca-bundle.pem' | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon
```

openSUSE specifics:

- State dir is `/var/lib/nix/...` (upstream uses `/nix/var/nix/...`).
- Access is **group-gated**: the daemon socket is `0660 root:nix-users` and the tmpfiles dir
  (`/usr/lib/tmpfiles.d/nix-daemon.conf`) is `0750 root:nix-users`. Being in `nix-users` is the
  native way in — do **not** `chmod` the socket/dir.
- **TLS / CA bundle** (the recurring gotcha): openSUSE ships its bundle at `/etc/ssl/ca-bundle.pem`,
  but Nix's compiled-in fallback probes the Debian/NixOS path
  (`/etc/ssl/certs/ca-certificates.crt`), which is absent. Without the `ssl-cert-file` line above,
  downloads fail with `curl` 77 (`Problem with the SSL CA cert …`). Setting it in the system-wide
  `/etc/nix/nix.conf` fixes both the client (flake eval) and the root daemon in one key. Ensure the
  bundle exists first:
  `sudo zypper install ca-certificates ca-certificates-mozilla && sudo update-ca-certificates`. See
  [NixOS/nix#3155](https://github.com/NixOS/nix/issues/3155).
- Verify: `nix store info` → `Store URL: daemon`; `nix config show | grep ssl-cert-file` →
  `/etc/ssl/ca-bundle.pem`.

> The **container** case is different: a single-user, daemonless install, no `nix-users` group. For
> a non-root user the per-user profile/state lives under `~/.local/state/nix` (XDG) — persist that
> dir (and `/nix`) to survive an ephemeral container home. The same `ssl-cert-file` gotcha recurs
> there.

## NixOS

Nix is the system; enable the new CLI + flakes declaratively:

```nix
# configuration.nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

`sudo nixos-rebuild switch`, then `nix develop` works out of the box — the daemon is native and the
socket is user-accessible by default (no group juggling).
