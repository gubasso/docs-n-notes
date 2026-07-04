# Podman + libkrun (crun --krun): operational notes & known issues

> Last updated: 2026-05-19. Host: Arch Linux rootless. Living document — append new findings here.

This is the source of truth for what works and what does not when running rootless
`podman run --runtime krun` (libkrun via crun's `--krun` handler). Use it to avoid re-discovering
the same potholes. Each known-issue entry records a minimal repro, the package versions at first
observation, the upstream issue (if any), and a workaround.

Related notes in this shelf:
[50-native-orchestration-decision.md](./50-native-orchestration-decision.md) covers the
orchestration consequence of the newline bug documented below;
[20-decision-libkrun-linux.md](./20-decision-libkrun-linux.md) covers why libkrun is the chosen
Linux isolation backend; [90-references.md](./90-references.md) collects external references.

## Environment baseline

| Component   | Version                                     |
| ----------- | ------------------------------------------- |
| Kernel      | 7.0.7-arch2-1                               |
| podman      | 5.8.2                                       |
| crun        | 1.27.1 (with `+LIBKRUN`, commit `3ec076b3`) |
| krun (Arch) | 1.27.1-1                                    |
| libkrun     | 1.18.0-1                                    |
| libkrunfw   | 5.3.0-1                                     |

Full `crun --version` at first observation:

```text
crun version 1.27.1
commit: 3ec076b3b6714ec2f1a10533cf18d5605a6de637
spec: 1.0.0
+SYSTEMD +SELINUX +APPARMOR +CAP +SECCOMP +EBPF +CRIU +LIBKRUN +YAJL
```

Host is Arch Linux, rootless. Test image throughout is `mcr.microsoft.com/devcontainers/base:debian`
(public tag).

The Arch `krun` package and the system `crun` binary are at the same upstream version because the
`--krun` handler is built into `crun` itself when compiled with `+LIBKRUN`; the standalone `krun`
symlink/wrapper is the same code path. There is no separate `krun` runtime binary with an
independent version to track — `--runtime krun` dispatches into the `+LIBKRUN`-enabled crun.

## Known issues

### KI-01 — `\n` mangled in `sh -c` payloads under `--runtime krun`

**Status:** classified 2026-05-19. Upstream report drafted (see
[Upstream bug report](#upstream-bug-report-drafted-ready-to-file) below), not yet filed.
**Severity:** blocks any caller that passes a multi-line shell script via
`podman run --runtime krun ... -c $'…\n…'`. **First observed:** podman 5.8.2 / crun 1.27.1 / libkrun
1.18.0 / libkrunfw 5.3.0.

Newlines in a `sh -c` payload are delivered to the guest shell as a newline character _plus_ a
literal `n` retained at the start of the next line. The first line of the script executes correctly;
every subsequent line is read as `n` + original-first-character + rest, so `trap` → `ntrap`, `exec`
→ `nexec`, `echo` → `necho`, and so on. Default `crun` (no `--krun`) handles the exact same payload
correctly, so the bug is on the krun argv path, not in any caller's argv construction.

**Working hypothesis:** a one-pass `\n` decode somewhere in the host→guest argv path (libkrun
vsock + init/agent) emits the newline character but fails to advance the input cursor past the
escape sequence — so the next character is read again. The first line is delivered cleanly because
no escape precedes it; every subsequent line picks up the stray `n` from the preceding `\n` decode.

#### Minimal repro — two-line echo

```bash
# Krun — bug
podman run --rm --runtime krun --entrypoint /bin/sh \
  mcr.microsoft.com/devcontainers/base:debian \
  -c $'echo line1\necho line2'
echo "exit=$?"
```

Observed (after `podman rm -f` of any leftover container):

```text
line1
/bin/sh: 2: necho: not found
exit=127
```

`line1` runs correctly; `echo line2` is delivered as `necho line2` — the `\n` produced a newline
_and_ the leading `e` of the next line was consumed as if it were the `n` of the escape.

Control under default `crun` (same payload, no `--runtime krun`):

```bash
podman run --rm --entrypoint /bin/sh \
  mcr.microsoft.com/devcontainers/base:debian \
  -c $'echo line1\necho line2'
echo "exit=$?"
```

```text
line1
line2
exit=0
```

Clean. The bug is present only on the `--runtime krun` path.

#### Minimal repro — multi-line shim

A more realistic payload (the shape a devcontainer keep-alive shim uses) makes the mangling visible
across every line:

```bash
podman run --rm --runtime krun --entrypoint /bin/sh \
  mcr.microsoft.com/devcontainers/base:debian \
  -c $'echo Container started\ntrap "exit 0" 15\n\necho after-trap\nexec sleep 2' -
```

Observed:

```text
Container started
-: 2: ntrap: not found
-: 3: n: not found
-: 4: necho: not found
-: 5: nexec: not found
exit=127
```

Line 1 runs; every subsequent line is `n`-prefixed:

| Source line              | Delivered to shell                        |
| ------------------------ | ----------------------------------------- |
| `echo Container started` | `echo Container started` (line 1 — clean) |
| `trap "exit 0" 15`       | `ntrap "exit 0" 15`                       |
| `` (blank)               | `n`                                       |
| `echo after-trap`        | `necho after-trap`                        |
| `exec sleep 2`           | `nexec sleep 2`                           |

Under default `crun`, the same payload prints `Container started` then `after-trap` and exits 0
cleanly.

**Classification:** bug is in `crun --krun` / libkrun newline handling, not in any caller's argv
construction. A two-line `echo` script is sufficient; the multi-line shim shape is a more elaborate
trigger of the same bug, not a different bug.

**Workaround:** never embed `\n` in a `-c` payload that crosses the host→guest boundary at container
start. Pass commands as separate argv entries, or use `podman exec` against an already-running
container with a fresh argv vector. An adapter that only ever passes single-line or argv-vector
commands is immune (never embeds multi-line scripts).

**Upstream:** report drafted below in
[Upstream bug report](#upstream-bug-report-drafted-ready-to-file). File against `containers/crun`
first (the `--krun` handler dispatches from there), mirror to `libkrun/libkrun`. Update this section
with the issue URL after filing.

<!-- TODO(upstream-url): replace this comment with the filed issue URL once the bug is reported. Search: TODO(upstream-url) -->

### KI-02 — `@devcontainers/cli` cannot bring a container up under `--runtime krun`

**Status:** consequence of [KI-01](#ki-01--n-mangled-in-sh--c-payloads-under---runtime-krun); not a
separate bug. **First observed:** `@devcontainers/cli` 0.86.0 against podman 5.8.2 + crun 1.27.1
(`--krun`).

`devcontainer up --workspace-folder X --docker-path "$(command -v podman)"` fails because the CLI's
keep-alive shim is a multi-line `sh -c` payload that trips KI-01. The container does get created
(podman returns a container ID) but every subsequent in-container probe fails over the broken
channel.

The failure cascade is misleading. The CLI surfaces it as:

```text
Shell server terminated (code: 1|255, signal: null)
```

followed by:

```text
unable to find user <name>: no matching entries in passwd file
```

The user-lookup error is a red herring — the in-container passwd probe also runs over the broken
channel, so it fails regardless of which user is queried (including `root`, which definitely
exists), and regardless of what `remoteUser` is set to.

**Workaround:** use `podman` directly with `--runtime krun` (single-line `-c` payloads only), and
drive lifecycle through a custom adapter that calls `podman exec` with fresh argv vectors. See
[50-native-orchestration-decision.md](./50-native-orchestration-decision.md) for the orchestration
decision this forces. An adapter that only ever passes single-line or argv-vector commands does
exactly this and is immune by construction.

## Working patterns (what _does_ work)

- `podman run --rm --runtime krun <image> <single-argv-command>` — fine.
- `podman exec <running-container> <single-argv-command>` — fine (fresh argv vector, no embedded
  shell script). This is the production lifecycle path.
- `podman run --rm --runtime krun --entrypoint /bin/sh <image> -c 'echo single-line'` — fine (no
  `\n` in the payload).
- Default `crun` runtime — fine. Use it for any test that needs multi-line shell payloads but does
  not specifically require microVM isolation.

## Prior art / suspected sibling upstream issues

No public report of `@devcontainers/cli` + `podman --runtime krun` working end-to-end at the time of
investigation (web search, 2026-05-19). Closest upstream issues, all open at the time — cross-
reference when filing:

- [containers/crun#1098](https://github.com/containers/crun/issues/1098) — `podman exec` into a
  krun'd container does not enter the VM (3+ years open; different bug, same handler).
- [libkrun/libkrun#104](https://github.com/libkrun/libkrun/issues/104) — `podman run` with krun
  drops env from image config (different bug, same handler).
- [libkrun/libkrun#273](https://github.com/libkrun/libkrun/issues/273) — krun argument-passing bug
  (`--` not forwarded correctly); likely related root cause.
- [containers/podman#28067](https://github.com/containers/podman/pull/28067) — TUI character
  handling broken under krun (Enter/newlines not handled correctly); possibly the same root cause.
- [containers/podman#21083](https://github.com/containers/podman/pull/21083) — `--init` not
  supported under libkrun.
- [containers/podman#24618](https://github.com/containers/podman/pull/24618) — race condition with
  krun on Fedora 40.

Red Hat's public libkrun investment (2024–2026) targets AI/GPU isolation; no maintainer statement on
exec / lifecycle-hook semantics for the krun handler.

## Upstream bug report (drafted, ready to file)

Suggested title:

```text
podman --runtime krun: newline in 'sh -c' payload delivered as '\n' + literal 'n' prefix on next line
```

**Where to file.** Primary: <https://github.com/containers/crun/issues/new> (the `--krun` handler
lives here). Mirror: <https://github.com/libkrun/libkrun/issues/new> (the host→guest argv path runs
through libkrun's vsock + init/agent). Reference once filed: libkrun/libkrun#273 (argument-passing,
likely related root cause), containers/podman#28067 (TUI newlines, possibly same root cause),
containers/crun#1098 and libkrun/libkrun#104 (different bugs, same handler).

The body below is ready to paste into the issue.

---

### Summary

When running a container with `podman run --runtime krun`, newlines (`\n`) embedded in a multi-line
`sh -c` payload are mangled: the newline character is emitted to the guest shell, but the leading
character of the next line is then read as if the `n` of the `\n` escape were still pending — so
every line after the first is prefixed with a stray `n`.

The bug does not reproduce under the default `crun` runtime with the exact same command. It is
reproducible with a two-line `echo` script — no devcontainer tooling, no shim, no
`trap`/`exec`/`while` — so the bug is on the krun argv path, not in any specific caller.

### Environment

- Host: Arch Linux, kernel `7.0.7-arch2-1`, rootless

- `podman --version` → `podman version 5.8.2`

- `crun --version` →

  ```text
  crun version 1.27.1
  commit: 3ec076b3b6714ec2f1a10533cf18d5605a6de637
  spec: 1.0.0
  +SYSTEMD +SELINUX +APPARMOR +CAP +SECCOMP +EBPF +CRIU +LIBKRUN +YAJL
  ```

- `pacman -Q crun libkrun libkrunfw krun` →

  ```text
  crun 1.27.1-1
  libkrun 1.18.0-1
  libkrunfw 5.3.0-1
  krun 1.27.1-1
  ```

- Image: `mcr.microsoft.com/devcontainers/base:debian` (public tag; happy to paste a specific digest
  if maintainers ask).

### Minimal reproducer

Two-line shell script, run twice — once under krun, once under default crun:

```bash
# Krun — bug
podman run --rm --runtime krun --entrypoint /bin/sh \
  mcr.microsoft.com/devcontainers/base:debian \
  -c $'echo line1\necho line2'
echo "exit=$?"

# crun — control
podman run --rm --entrypoint /bin/sh \
  mcr.microsoft.com/devcontainers/base:debian \
  -c $'echo line1\necho line2'
echo "exit=$?"
```

### Expected

Both commands should produce:

```text
line1
line2
exit=0
```

### Actual

Under `--runtime krun`:

```text
line1
/bin/sh: 2: necho: not found
exit=127
```

Under default `crun`:

```text
line1
line2
exit=0
```

The second line of the script was delivered as `necho line2` (the leading `e` of `echo` is being
read as the second character; the `n` that should have completed the `\n` escape was instead
retained as a literal character at the start of line 2).

### Additional repro — multi-line shim

A more realistic payload (the shape `@devcontainers/cli` 0.86.0 uses for its container keep-alive
shim) makes the mangling visible across every line:

```bash
podman run --rm --runtime krun --entrypoint /bin/sh \
  mcr.microsoft.com/devcontainers/base:debian \
  -c $'echo Container started\ntrap "exit 0" 15\n\necho after-trap\nexec sleep 2' -
```

Output:

```text
Container started
-: 2: ntrap: not found
-: 3: n: not found
-: 4: necho: not found
-: 5: nexec: not found
exit=127
```

Every line after the first is prefixed with `n`:

| Source line              | Delivered to shell                        |
| ------------------------ | ----------------------------------------- |
| `echo Container started` | `echo Container started` (line 1 — clean) |
| `trap "exit 0" 15`       | `ntrap "exit 0" 15`                       |
| `` (blank)               | `n`                                       |
| `echo after-trap`        | `necho after-trap`                        |
| `exec sleep 2`           | `nexec sleep 2`                           |

Under default `crun`, the same payload prints `Container started` then `after-trap` and exits 0
cleanly.

### Hypothesis

Looks like a one-pass `\n` decode somewhere in the host→guest argv path (libkrun vsock + init/agent)
that emits the newline character but fails to advance the input cursor past the escape — so the next
character is read again. The first line is delivered correctly because no escape precedes it; every
subsequent line picks up the stray `n` from the preceding `\n` decode.

### Impact

Any caller that hands `podman --runtime krun` a multi-line `sh -c` payload fails. Notably:

- `@devcontainers/cli up` against `podman --runtime krun` cannot establish a container, because its
  keep-alive shim is a multi-line script. The CLI surfaces this as
  `Shell server terminated (code: 1|255, signal: null)` followed by misleading cascades like
  `unable to find user <name>: no matching entries in passwd file` (because all subsequent
  in-container probes also fail).
- Likely related: containers/podman#28067 (TUI character handling), libkrun/libkrun#273 (`--` not
  forwarded).

### Workaround

Pass commands as separate argv entries (no embedded newlines), or use `podman exec` with a fresh
argv vector against an already-running container. The bug only manifests when `\n` is present inside
the `-c` payload that crosses the host→guest boundary at container start.

### Notes for the maintainer

- I have not yet built `crun` / `libkrun` from source to bisect. Happy to do so if it would help —
  please point me at suspected files.
- Original investigation context: tried to use `@devcontainers/cli` as the lifecycle interpreter on
  top of `podman --runtime krun` for a sandboxed dev-environment tool. Spike write-up with full
  failure timeline and prior-art survey is available on request.

---

## Filing checklist (pre-submission)

- Before filing, run the repro one more time on the host and paste real version output into the
  `Environment` section above. Stale versions will get the report bounced.
- File against **containers/crun first** — that's where the `--krun` handler dispatches. If
  maintainers redirect to libkrun, mirror it there with a back-link.
- After filing, update the KI-01 status banner and the `TODO(upstream-url)` marker with the filed
  issue URL.
- If the maintainer asks for a smaller repro, try a one-character second line: `-c $'a\nb'` — likely
  produces `a` then `/bin/sh: 2: nb: not found`.

## Investigation log

- **2026-05-19** — An isolation spike classified KI-01 by isolating the bug from
  `@devcontainers/cli`. A two-line `echo` script under raw `podman run --runtime krun` reproduces;
  the same script under default `crun` is clean. Bug located in `crun --krun` / libkrun argv path,
  not in any caller. Spike status flipped from "blocked — pending classification" to "classified —
  pending upstream filing". Prior-art web search the same day found no public report of
  `@devcontainers/cli` + `podman --runtime krun` working end-to-end; six sibling upstream issues
  catalogued (see [Prior art](#prior-art--suspected-sibling-upstream-issues)).
