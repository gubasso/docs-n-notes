# Bash CLI project — implementation-kind additions

What a **CLI** project adds on top of the general recipe and the Bash binding: argument parsing with
`getopts`, subcommands, a usage/help surface, and configuration. This file owns only the
**bootstrap-time ordering**; the detailed _how_ is owned by [`../cli-spec/`](../cli-spec/README.md)
and is not restated here.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the Bash
  [binding runbook](runbook.md) are done — a runnable, strict-mode, gated script exists.

## Add these, in this order

When scaffolding a CLI, layer these on the runnable shim in order — each links to the spec that
details it:

1. **Directory & module layout for a CLI.** Establish the `bin/<name>` shim → `lib/loader.sh` →
   `lib/core.sh` → `main "$@"` split, one function per file. →
   [`../cli-spec/bash-cli-project-specs.md`](../cli-spec/bash-cli-project-specs.md).
2. **Argument parsing.** Parse global flags with the `getopts` builtin (portable, no dependency);
   reserve long options for a hand-rolled `case` loop if needed. →
   [`../cli-spec/bash-cli-project-specs.md`](../cli-spec/bash-cli-project-specs.md).
3. **Subcommands.** Dispatch the first non-flag argument to a per-command function/file (a `case`
   over the verb), each with its own `getopts` pass. →
   [`../cli-spec/bash-cli-project-specs.md`](../cli-spec/bash-cli-project-specs.md).
4. **Usage / help.** A `usage()` function printed on `-h`, on no args, and on parse errors (to
   stderr, exit non-zero for errors). →
   [general — Error Messages](../../../programming/cli-design/02-error-messages.md).
5. **Configuration.** Config file + env + flag precedence, using XDG paths
   (`${XDG_CONFIG_HOME:-$HOME/.config}/<app>`). →
   [general — Config Precedence](../../../programming/cli-design/03-config-precedence.md),
   [`../cli-spec/bash-cli-project-specs.md`](../cli-spec/bash-cli-project-specs.md).

For error handling, signals/tempfiles, testing, install, and distribution, continue through the rest
of [`../cli-spec/`](../cli-spec/README.md).

## Distribution (later phase)

Shipping the CLI (an `install.sh`, XDG install paths, AUR/OBS packages) is release-phase work — see
[`../release-workflow-spec/`](../release-workflow-spec/README.md). Bootstrap stops at a working,
gated CLI script.
