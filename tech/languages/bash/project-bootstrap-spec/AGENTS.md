---
digest-of: tech/languages/bash/project-bootstrap-spec
last-synced: 2026-07-09
source-files:
  - README.md
  - runbook.md
  - 00-toolchain-and-layout.md
  - 01-quality-gates.md
  - cli-project.md
token-estimate: 780
---

# AGENTS

## Scope

Bash binding of the general `tech/programming/project-bootstrap/` shelf: the once-per-project Bash
setup that takes an empty repo to a scaffolded, strict-mode, gated script project ready for feature
work. It **overlays** the general spine (repo, license, governance, dev env, CI, security) and never
restates it; it owns only the Bash ecosystem choices (script layout, strict mode, the
shfmt/shellcheck/bats gates) and the CLI implementation-kind ordering. Distribution is out of scope
— it hands off to `../release-workflow-spec/`.

## Key Points

- **No scaffolder:** unlike compiled languages there is no `cargo new`; a Bash project is a
  directory of scripts created by hand. Bootstrap owns the _ordering_ (get a runnable, lintable
  script first); `../cli-spec/` owns the detailed _how_.
- **Layout:** `bin/<name>` is a thin executable shim on `PATH` that sources the library and calls
  `main "$@"`; `lib/` holds the real logic split into sourced files (loader, core, one function per
  file); `tests/` holds `bats` files. A single-file utility can be just the shim.
- **Shebang:** prefer `#!/usr/bin/env bash` over `#!/bin/bash` so the script uses the `bash` on
  `PATH` (the Nix devShell's), not a stale system Bash (macOS ships 3.2).
- **Strict mode:** every script starts with `set -euo pipefail` + `IFS=$'\n\t'` — `-e` exit on
  unhandled non-zero, `-u` error on unset vars, `-o pipefail` fail if any pipeline stage fails.
- **ShellCheck-driven structure:** keep sourced files discoverable
  (`# shellcheck source=lib/core.sh` above dynamic `source` lines), prefer functions over top-level
  code; treating warnings as errors from the first commit shapes the layout.
- **Toolchain via Nix:** no compiler to pin, but pin the _tools_ — add `bash`, `shfmt`,
  `shellcheck`, `bats` to the per-project Nix devShell so local and CI share versions
  (`nix/02-per-project-devshell`).
- **Quality gates:** `shfmt` formats (`shfmt -d -i 2 -ci -sr .`, `-d` diffs and exits non-zero);
  `shellcheck` lints, non-negotiable (`shellcheck -S style ...`), warnings as errors, silence only
  with inline `# shellcheck disable=SCxxxx` plus a why-comment. ShellCheck is _also_ the security
  gate (flags injection-prone patterns: unquoted expansion, `eval` on input, word-splitting).
  `bats-core` tests, one `.bats` per subcommand/unit, hermetic (no network, `mktemp` temp dirs).
- **Gate wiring:** wire `shfmt -d`, `shellcheck`, `bats` into pre-commit and expose the same three
  as task-runner recipes (`fmt`, `lint`, `test`) so CI and local run one command each.
- **CLI kind (bootstrap-time ordering):** layout (`bin/<name>` shim → `lib/loader.sh` →
  `lib/core.sh` → `main "$@"`, one function per file) → arg parsing via the `getopts` builtin
  (portable, no dependency; long options via a hand-rolled `case` loop) → subcommands (dispatch
  first non-flag arg via `case`, each with its own `getopts`) → `usage()` on
  `-h`/no-args/parse-errors (to stderr, non-zero) → config precedence (file + env + flag) using XDG
  paths.
- **Automation:** `bootstrap-nix` provisions the devShell; `bootstrap-precommit` and
  `bootstrap-taskrunner` wire the gates; `bootstrap-ci` covers CI. The runbook steps are the SoT;
  see general `07-automation-with-cog.md`.

## Source Map

| Topic                                                         | File                         |
| ------------------------------------------------------------- | ---------------------------- |
| Binding index, how-to-use, implementation-kinds list, related | `README.md`                  |
| Ordered Bash overlay steps (the _what_/_in what order_)       | `runbook.md`                 |
| Layout, shebang, strict mode, ShellCheck structure, Nix pin   | `00-toolchain-and-layout.md` |
| `shfmt` / `shellcheck` (also security) / `bats` + pre-commit  | `01-quality-gates.md`        |
| CLI bootstrap ordering (layout, `getopts`, subcommands, help) | `cli-project.md`             |

## Maintenance Notes

- General spine: `../../../programming/project-bootstrap/`. Release/distribution handoff (tag,
  git-cliff changelog, Makefile, `install.sh`, AUR, OBS): `../release-workflow-spec/`. Detailed Bash
  CLI structure: `../cli-spec/`.
- `library-project.md` (a sourced function library) is a declared followup kind; add it (and refresh
  `source-files`) when it lands.
- Re-verify the default-tool flags (`shfmt`, `shellcheck -S style`, `bats-core`) against upstream on
  a cadence when regenerating.
- No conflicts among the current source files.
  </content>
  </invoke>
