# Podman + libkrun (`crun --krun`) — notes and known issues

> Last updated: 2026-05-19. Host: Arch Linux rootless. Living document — append new findings here.
>
> Companion files in this folder:
>
> - [libkrun-crun-newline-mangling-upstream-issue.md](./libkrun-crun-newline-mangling-upstream-issue.md) — drafted upstream bug report, not yet filed.

## What this is

A reference of what works and what does not when running rootless `podman run --runtime krun` on Arch Linux. Use it to avoid re-discovering the same potholes. Each known-issue entry should record: minimal repro, package versions at first observation, upstream issue (if any), and a workaround.

## Environment baseline (latest observation)

| Component   | Version                                     |
| ----------- | ------------------------------------------- |
| Kernel      | 7.0.7-arch2-1                               |
| podman      | 5.8.2                                       |
| crun        | 1.27.1 (with `+LIBKRUN`, commit `3ec076b3`) |
| krun (Arch) | 1.27.1-1                                    |
| libkrun     | 1.18.0-1                                    |
| libkrunfw   | 5.3.0-1                                     |

The Arch `krun` package and the system `crun` binary are at the same upstream version because the `--krun` handler is built into `crun` itself when compiled with `+LIBKRUN`; the standalone `krun` symlink/wrapper is the same code path.

## Known issues

### KI-01 — `\n` mangled in `sh -c` payloads under `--runtime krun`

**Status:** classified 2026-05-19. Upstream report drafted, not yet filed.
**Severity:** blocks any caller that passes multi-line shell scripts via `podman run --runtime krun ... -c $'…\n…'`.
**First observed:** podman 5.8.2 / crun 1.27.1 / libkrun 1.18.0 / libkrunfw 5.3.0.

Newlines in a `sh -c` payload are delivered to the guest shell as a newline character *plus* a literal `n` retained on the next line. The first line executes correctly; every subsequent line is read as `n` + original-second-character + rest, so `trap` → `ntrap`, `exec` → `nexec`, etc.

Minimal repro:

```bash
podman run --rm --runtime krun --entrypoint /bin/sh \
  mcr.microsoft.com/devcontainers/base:debian \
  -c $'echo line1\necho line2'
# Actual:   line1
#           /bin/sh: 2: necho: not found
#           exit 127
# Expected: line1
#           line2
#           exit 0
```

Control (default `crun`) prints both lines and exits 0.

**Working hypothesis:** one-pass `\n` decode in the host→guest argv path (libkrun vsock + init/agent) that emits the newline but does not advance the input cursor past the escape sequence.

**Workaround:** never embed `\n` in a `-c` payload that crosses the host→guest boundary at container start. Pass commands as separate argv entries, or use `podman exec` against an already-running container with a fresh argv vector. The devcontainerctl direct adapter (`lib/dctl/runtime/krun.sh`) works because it never embeds multi-line scripts.

**Cascade symptoms to recognise:**

- `@devcontainers/cli`: `Shell server terminated (code: 1|255, signal: null)` followed by misleading `unable to find user <name>: no matching entries in passwd file` (because the in-container passwd probe also fails over the broken channel — regardless of which user is queried, including `root` which definitely exists).

**Upstream:** report drafted at [libkrun-crun-newline-mangling-upstream-issue.md](./libkrun-crun-newline-mangling-upstream-issue.md). File against `containers/crun` first (the `--krun` handler dispatches from there), mirror to `containers/libkrun`. Update this row with the issue URL after filing. <!-- TODO(upstream-url): replace this comment with the filed issue URL once the bug is reported. Search: TODO(upstream-url) -->

**Suspected sibling bugs (cross-reference when filing):**

- [containers/libkrun#273](https://github.com/containers/libkrun/issues/273) — `--` not forwarded correctly (argument-passing).
- [containers/podman#28067](https://github.com/containers/podman/issues/28067) — TUI character handling broken under krun (Enter/newlines).
- [containers/crun#1098](https://github.com/containers/crun/issues/1098) — `podman exec` into a krun'd container does not enter the VM (different bug, same handler).
- [containers/libkrun#104](https://github.com/containers/libkrun/issues/104) — `podman run` with krun drops env from image config (different bug, same handler).

### KI-02 — `@devcontainers/cli` cannot bring a container up under `--runtime krun`

**Status:** consequence of [KI-01](#ki-01--n-mangled-in-sh--c-payloads-under---runtime-krun); not a separate bug.
**First observed:** `@devcontainers/cli` 0.86.0 against podman 5.8.2 + crun 1.27.1 (`--krun`).

`devcontainer up --workspace-folder X --docker-path "$(command -v podman)"` fails because the CLI's keep-alive shim is a multi-line `sh -c` payload that trips KI-01. The container does get created (podman returns a container ID) but every subsequent in-container probe fails, including the user-lookup probe — so the CLI cascades into `unable to find user <name>` regardless of what `remoteUser` is set to.

**Workaround:** use `podman` directly with `--runtime krun` (single-line `-c` payloads only), and drive lifecycle through a custom adapter that calls `podman exec` with fresh argv vectors. The devcontainerctl `lib/dctl/runtime/krun.sh` adapter does exactly this.

## Working patterns (what *does* work)

- `podman run --rm --runtime krun <image> <single-argv-command>` — fine.
- `podman exec <running-container> <single-argv-command>` — fine (this is what the devcontainerctl direct adapter uses).
- `podman run --rm --runtime krun --entrypoint /bin/sh <image> -c 'echo single-line'` — fine (no `\n` in the payload).
- Default `crun` runtime — fine. Use it for any test that needs multi-line shell payloads but does not specifically require microVM isolation.

## Investigation log

- **2026-05-19** — Spike (devcontainerctl `docs/specs/sandbox-runtime/SPIKE-DEVCONTAINER-CLI-KRUN.md`) classified KI-01 by isolating the bug from `@devcontainers/cli`. Two-line `echo` script under raw `podman run --runtime krun` reproduces; same script under default `crun` is clean. Bug located in `crun --krun` / libkrun argv path, not in any caller. Spike status flipped from "blocked — pending classification" to "classified — pending upstream filing".
