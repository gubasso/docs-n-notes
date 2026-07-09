# Bash — bootstrap a new project (spec/binding)

The Bash binding of
[`tech/programming/project-bootstrap/`](../../../programming/project-bootstrap/README.md). It
applies the general once-per-project recipe with concrete Bash tooling — script layout, strict-mode
conventions, and the shfmt/shellcheck/bats quality gates — and links to Bash implementation-kinds.

This binding **overlays** the general spine; it does not restate it. Read the general recipe first,
then the Bash specifics here.

## How to use this binding

1. Read the general [hub](../../../programming/project-bootstrap/README.md) and
   [general runbook](../../../programming/project-bootstrap/runbook.md) — the cross-language _what_.
2. Follow this [`runbook.md`](./runbook.md) for the Bash-specific overlay steps.
3. Jump to your implementation-kind file (e.g. [`cli-project.md`](./cli-project.md)).
4. When ready to publish, hand off to
   [`../release-workflow-spec/`](../release-workflow-spec/README.md) — the later Bash release phase.

## Index

| # | Chapter                                            | One-line hook                                                           |
| - | -------------------------------------------------- | ----------------------------------------------------------------------- |
| 0 | [Toolchain & layout](./00-toolchain-and-layout.md) | `bin/`+`lib/` layout, shebang, `set -euo pipefail`, Nix-hosted tooling. |
| 1 | [Quality gates](./01-quality-gates.md)             | `shfmt` (format), `shellcheck -S style` (lint), `bats-core` (test).     |

## Implementation kinds

- [`cli-project.md`](./cli-project.md) — Bash CLI: the bootstrap-time ordering for `getopts`
  arg-parsing, subcommands, usage/help, and config, delegating detail to
  [`../cli-spec/`](../cli-spec/README.md).

`library-project.md` (a sourced function library) is a followup; add it when you bootstrap that
kind.

## Related

- [General project-bootstrap](../../../programming/project-bootstrap/README.md) — the cross-language
  recipe this binding overlays.
- [`../release-workflow-spec/`](../release-workflow-spec/README.md) — the later Bash release &
  distribution phase (tag, git-cliff changelog, Makefile, `install.sh`, AUR, OBS).
- [`../cli-spec/`](../cli-spec/README.md) — the detailed Bash CLI structure spec.
