# 00 — Toolchain & layout

The Bash ecosystem choices for a fresh script project: how to lay out files, what strict-mode
preamble every script needs, and where the detailed layout spec lives.

## Script layout

Unlike compiled languages there is no scaffolder like `cargo new`; a Bash project is a directory of
scripts you create by hand. The baseline shape:

- `bin/<name>` — a thin executable shim on `PATH`; sources the library and calls `main "$@"`.
- `lib/` — the real logic, split into sourced files (a loader, core, one function per file).
- `tests/` — `bats` test files.

For a single-file utility the shim _is_ the script. For anything with subcommands or multiple
modules, follow the detailed structure spec:
[`../cli-spec/bash-cli-project-specs.md`](../cli-spec/bash-cli-project-specs.md). Bootstrap owns the
_ordering_ (get a runnable, lintable script first); `cli-spec/` owns the detailed _how_.

## Shebang

Prefer `#!/usr/bin/env bash` over `#!/bin/bash` so the script uses the `bash` on `PATH` (the one the
Nix devShell provides) rather than a system Bash that may be old (e.g. macOS ships 3.2).

## Strict mode

Start every script with the strict-mode preamble so failures surface instead of being silently
swallowed:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

- `-e` — exit on any unhandled non-zero command.
- `-u` — error on unset variables.
- `-o pipefail` — a pipeline fails if any stage fails, not just the last.

Know the caveats (`|| true` to opt out, subshell exit-code propagation) — the detailed treatment is
in [`../cli-spec/bash-cli-project-specs.md`](../cli-spec/bash-cli-project-specs.md).

## ShellCheck-driven structure

Structure the code so ShellCheck can see it: keep sourced files discoverable (add a
`# shellcheck source=lib/core.sh` directive above dynamic `source` lines), and prefer functions over
top-level code so the linter can reason about scope. Treating ShellCheck warnings as errors from the
first commit shapes the layout — this is enforced as a gate in
[01 — Quality gates](01-quality-gates.md).

## Toolchain + Nix

There is no compiler to pin, but the _tools_ still need pinning so local and CI agree. Add `bash`,
`shfmt`, `shellcheck`, and `bats` to the per-project Nix devShell — see
[nix/02-per-project-devshell](../../../tools/nix/02-per-project-devshell.md). This closes the "works
on my machine" gap (Bash version, ShellCheck version) before any code is written.

## Automation

The general dev-env and gate skills (`bootstrap-nix`, `bootstrap-precommit`, `bootstrap-taskrunner`)
lay down the devShell and gate wiring. The steps above are the SoT; see
[general 07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md).
