# Node CLI project — implementation-kind additions

What a **Node CLI** project adds on top of the general recipe and the JavaScript binding: the
executable entry point, argument parsing, and packaging so the command runs. This file owns only the
**bootstrap-time ordering**; it stops at a working, gated CLI.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the JavaScript
  [binding runbook](./runbook.md) are done — an installable, gated package exists.

## Add these, in this order

Layer these on the initialized package in order:

1. **Executable entry point.** Add a `bin` field to `package.json` mapping the command name to a
   script (e.g. `"bin": { "mytool": "./dist/cli.js" }`), and start that script with a shebang
   (`#!/usr/bin/env node`). → [00 — Toolchain & layout](./00-toolchain-and-layout.md).

2. **Argument parsing & subcommands.** Define the command surface. Node's built-in `util.parseArgs`
   covers simple cases; use [commander](https://github.com/tj/commander.js) or
   [yargs](https://github.com/yargs/yargs) for richer subcommand trees, or
   [oclif](https://oclif.io/) for a full CLI framework.

3. **Error handling & exit codes.** Fail with a non-zero exit code and a readable message; do not
   let unhandled rejections crash silently.

4. **Logging & output.** Separate machine output (stdout) from diagnostics (stderr); add a
   `--verbose`/`--quiet` control.

5. **Configuration.** If needed, resolve config from file + env + flags with a defined precedence.

Keep the build (`tsc` → `dist/`) and the `bin` path in sync so the published command actually runs.

## Binary distribution (later phase)

Publishing the CLI to npm (and any standalone-binary packaging, e.g. via `pkg` or Node SEA) is
release-phase work — see [`../release-workflow-spec/`](../release-workflow-spec/README.md).
Bootstrap stops at a working, gated CLI package that runs locally via `node` or a linked `bin`.
