# Go CLI project — implementation-kind additions

What a **CLI** project adds on top of the general recipe and the Go binding: the command surface,
flag/subcommand parsing, error/exit-code handling, and configuration. This file owns only the
**bootstrap-time ordering**.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the Go
  [binding runbook](./runbook.md) are done — a buildable, gated module exists.

## Add these, in this order

When scaffolding a CLI, layer these on the buildable module in order:

1. **Command layout.** Put the entrypoint under `cmd/<name>/main.go` and keep `main` thin; push
   logic into `internal/`. → [00 — Toolchain & layout](./00-toolchain-and-layout.md).
2. **Argument parsing & subcommands.** For a single command with a few flags, the stdlib `flag`
   package is enough; for a subcommand tree with help/completion, use `cobra`. Pick one and define
   the command surface.
3. **Error handling & exit codes.** Return errors up to `main` and map them to process exit codes in
   one place, rather than calling `os.Exit` from deep in the tree.
4. **Configuration.** Establish flag → env → config-file precedence (e.g. `cobra` + `viper`, or a
   small hand-rolled loader). Keep defaults explicit.

## Binary distribution (later phase)

Shipping prebuilt CLI binaries (release archives, `go install`, GoReleaser) is release-phase work,
not bootstrap. Bootstrap stops at a working, gated CLI module. The Go
[`release-workflow-spec/`](../release-workflow-spec/README.md) is intentionally deferred until a
real Go release need arises.
