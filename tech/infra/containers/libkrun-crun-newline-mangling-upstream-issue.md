# Upstream bug: `podman --runtime krun` mangles `\n` in `sh -c` payload

> Drafted: 2026-05-19. Not yet filed. File against **containers/crun** and/or **containers/libkrun** (mirror to the other once one is open). Minimal repro is in §3 below.
>
> Repro evidence: [SPIKE-DEVCONTAINER-CLI-KRUN.md §6](../../../../devcontainerctl/docs/specs/sandbox-runtime/SPIKE-DEVCONTAINER-CLI-KRUN.md) in the `devcontainerctl` repo.

## Suggested title

`podman --runtime krun: newline in 'sh -c' payload delivered as '\n' + literal 'n' prefix on next line`

## Where to file

Primary: <https://github.com/containers/crun/issues/new> (the `--krun` handler lives here)
Mirror: <https://github.com/containers/libkrun/issues/new> (host→guest argv path runs through libkrun's vsock + init/agent)

Reference once filed:
- containers/libkrun#273 — argument-passing bug (`--` not forwarded correctly) — likely related root cause
- containers/podman#28067 — TUI character handling broken under krun (Enter/newlines not handled correctly) — possibly same root cause
- containers/crun#1098 — `podman exec` into a krun'd container does not enter the VM — different bug, same handler
- containers/libkrun#104 — `podman run` with krun drops env from image config — different bug, same handler

## Body (paste into the issue)

---

### Summary

When running a container with `podman run --runtime krun`, newlines (`\n`) embedded in a multi-line `sh -c` payload are mangled: the newline character is emitted to the guest shell, but the leading character of the next line is then read as if the `n` of the `\n` escape were still pending — so every line after the first is prefixed with a stray `n`.

The bug does not reproduce under the default `crun` runtime with the exact same command. It is reproducible with a two-line `echo` script — no devcontainer tooling, no shim, no `trap`/`exec`/`while` — so the bug is on the krun argv path, not in any specific caller.

### Environment

- Host: Arch Linux, kernel `7.0.7-arch2-1`, rootless
- `podman --version` → `podman version 5.8.2`
- `crun --version` →

  ```
  crun version 1.27.1
  commit: 3ec076b3b6714ec2f1a10533cf18d5605a6de637
  spec: 1.0.0
  +SYSTEMD +SELINUX +APPARMOR +CAP +SECCOMP +EBPF +CRIU +LIBKRUN +YAJL
  ```

- `pacman -Q crun libkrun libkrunfw krun` →

  ```
  crun 1.27.1-1
  libkrun 1.18.0-1
  libkrunfw 5.3.0-1
  krun 1.27.1-1
  ```

- Image: `mcr.microsoft.com/devcontainers/base:debian` (public tag; happy to paste a specific digest if maintainers ask).

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

```
line1
line2
exit=0
```

### Actual

Under `--runtime krun`:

```
line1
/bin/sh: 2: necho: not found
exit=127
```

Under default `crun`:

```
line1
line2
exit=0
```

The second line of the script was delivered as `necho line2` (the leading `e` of `echo` is being read as the second character; the `n` that should have completed the `\n` escape was instead retained as a literal character at the start of line 2).

### Additional repro — multi-line shim

A more realistic payload (the shape `@devcontainers/cli` 0.86.0 uses for its container keep-alive shim) makes the mangling visible across every line:

```bash
podman run --rm --runtime krun --entrypoint /bin/sh \
  mcr.microsoft.com/devcontainers/base:debian \
  -c $'echo Container started\ntrap "exit 0" 15\n\necho after-trap\nexec sleep 2' -
```

Output:

```
Container started
-: 2: ntrap: not found
-: 3: n: not found
-: 4: necho: not found
-: 5: nexec: not found
exit=127
```

Every line after the first is prefixed with `n`:

| Source line                 | Delivered to shell      |
|-----------------------------|-------------------------|
| `echo Container started`    | `echo Container started` (line 1 — clean) |
| `trap "exit 0" 15`          | `ntrap "exit 0" 15`     |
| `` (blank)                  | `n`                     |
| `echo after-trap`           | `necho after-trap`      |
| `exec sleep 2`              | `nexec sleep 2`         |

Under default `crun`, the same payload prints `Container started` then `after-trap` and exits 0 cleanly.

### Hypothesis

Looks like a one-pass `\n` decode somewhere in the host→guest argv path (libkrun vsock + init/agent) that emits the newline character but fails to advance the input cursor past the escape — so the next character is read again. The first line is delivered correctly because no escape precedes it; every subsequent line picks up the stray `n` from the preceding `\n` decode.

### Impact

Any caller that hands `podman --runtime krun` a multi-line `sh -c` payload fails. Notably:

- `@devcontainers/cli up` against `podman --runtime krun` cannot establish a container, because its keep-alive shim is a multi-line script. The CLI surfaces this as `Shell server terminated (code: 1|255, signal: null)` followed by misleading cascades like `unable to find user <name>: no matching entries in passwd file` (because all subsequent in-container probes also fail).
- Likely related: containers/podman#28067 (TUI character handling), containers/libkrun#273 (`--` not forwarded).

### Workaround

Pass commands as separate argv entries (no embedded newlines), or use `podman exec` with a fresh argv vector against an already-running container. The bug only manifests when `\n` is present inside the `-c` payload that crosses the host→guest boundary at container start.

### Notes for the maintainer

- I have not yet built `crun` / `libkrun` from source to bisect. Happy to do so if it would help — please point me at suspected files.
- Original investigation context: tried to use `@devcontainers/cli` as the lifecycle interpreter on top of `podman --runtime krun` for a sandboxed dev-environment tool. Spike write-up with full failure timeline and prior-art survey is available on request.

---

## Notes for me (gu) — do not include in the upstream issue

- Before filing, run the repro one more time on the host and paste real version output into the `Environment` section above (replace the `<!-- paste -->` markers). Stale versions will get the report bounced.
- File against **containers/crun first** — that's where the `--krun` handler dispatches. If maintainers redirect to libkrun, mirror it there with a back-link.
- After filing, update [SPIKE-DEVCONTAINER-CLI-KRUN.md](../../../../devcontainerctl/docs/specs/sandbox-runtime/SPIKE-DEVCONTAINER-CLI-KRUN.md) — change the Status line from "pending upstream filing" to "filed upstream as `<url>`".
- If the maintainer asks for a smaller repro, try a one-character second line: `-c $'a\nb'` — likely produces `a` then `/bin/sh: 2: nb: not found`.
