# Isolated AI Dev Environment Automated Wrappers

> Prerequisites: For the necessary background, see [Isolated AI Dev Environment with `systemd-nspawn` (`dev-sandbox`)](./isolated-ai-dev-environment-with-systemd-nspawn-dev-sandbox.md)

Since writing the original [walkthrough](./isolated-ai-dev-environment-with-systemd-nspawn-dev-sandbox), I implemented three small wrapper scripts that automate the workflows described here. They cover three operational models (persistent machine, one-shot session, and per-project containers).

**Scripts**
- **`dev-sandbox`** — long-lived `systemd-nspawn` machine (persistent rootfs, multi-terminal attach)
  Link: *https://github.com/gubasso/dotfiles/blob/master/bin/.local/bin/dev-sandbox*
- **`dev-sandbox-oneshot`** — one-shot `systemd-nspawn` entry into an existing rootfs (single session)
  Link: *https://github.com/gubasso/dotfiles/blob/master/bin/.local/bin/dev-sandbox-oneshot*
- **`dev-container`** — rootless Podman, per-project persistent containers (multi-terminal attach)
  Link: *https://github.com/gubasso/dotfiles/blob/master/bin/.local/bin/dev-container*

### Quick comparison

| Dimension | dev-sandbox | dev-sandbox-oneshot | dev-container |
|---|---|---|---|
| Core model | systemd-nspawn, persistent rootfs | systemd-nspawn, single-session | Podman, per-project containers |
| Primary goal | Long-lived, stable dev machine with repeatable multi-terminal attach and project binds | Fast, minimal “enter once” experience using an existing rootfs and direct nspawn exec | Rootless, per-project isolated containers with multi-terminal attach and per-project config volume |
| Isolation model | One machine (“dev-sandbox”) with a persistent rootfs under `/var/lib/machines/dev-sandbox` | Same rootfs location model, but does not manage lifecycle; just enters | One container per project path (plus optional base shell container); container state per project |
| Host requirements | `machinectl`, `systemd-run`, `systemd-nspawn`, `zypper`, `rpm`, `sudo`, etc. | `systemd-nspawn` + rootfs already provisioned; minimal host-side orchestration | Rootless `podman` + `rsync` (unless `--no-sync`), `readlink`, etc. |
| Persistence scope | Highest: rootfs persists across reboots; machine can be enabled; consistent base environment | High (rootfs persists), but script itself is not the lifecycle manager | Medium: container persists per project, but changes are scoped to that project container (not shared across projects); image rebuilds affect new containers |
| Multi-terminal support | Yes: `systemd-run -M ... --pty` enables many concurrent shells into the same running machine | No (by design): “one terminal session at a time” workflow | Yes: re-run script to `podman exec -it` into the same container (concurrent terminals supported) |
| Project mount behavior | Per-invocation bind to `/workspace/<basename>` with collision checks and mountpoint validation | Per-invocation bind to `/workspace/<project-name>` | Per-project bind mount into `/workspace/<basename>` (RW) for project mode |
| Basename collision handling | Explicit collision detection; expects consistent mapping per basename; rejects ambiguous bindings | No collision management beyond what systemd-nspawn does for bind args | Avoids basename collisions via per-project container naming (`<basename>-<hash(path)>`) while mountpoint path stays `/workspace/<basename>` |
| User identity strategy | Mirrors host username + UID/GID inside container (may delete conflicting users/groups by policy) | Uses fixed users (e.g., `dev`) and optionally root; no UID/GID mirroring | Uses `--userns=keep-id` + `--user UID:GID`; no in-container user creation required (identity mapping via Podman) |
| Host config strategy | Sync host `~/.config` into rootfs `/home/<hostuser>/.config` on each attach (rsync, potentially privileged write) | Bind-mount dotfiles read-only into `/opt/host-dotfiles*`; does not sync host `~/.config` | Sync host `~/.config` one-way into a *per-container* volume (merge semantics, no deletes); symlinks dereferenced |
| Typical “safe AI tooling” posture | Strong: tools installed in container; host exposure mediated via binds and user mapping | Strong but simpler: read-only dotfiles + optional project bind; minimal orchestration | Strong: rootless containers reduce host privilege; per-project isolation limits blast radius |
| Lifecycle operations | Full: provision rootfs, manage machine start/stop/status/setup, enable machine | Minimal: requires rootfs exists; no provision/start/stop management | Container lifecycle: create/start/stop/rm/list; image build/rebuild support |
| Best fit | Daily driver sandbox machine; stable baseline; frequent multi-terminal workflows across many projects | Quick “jump in” single session when rootfs already exists; simpler mental model | Per-project environments; rootless workflow; easy isolation across many projects; acceptable that state differs between projects |
