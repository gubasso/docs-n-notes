# Rust CLI project — implementation-kind additions

What a **CLI** project adds on top of the general recipe and the Rust binding: argument parsing,
logging, configuration, and a subcommand shape. This file owns only the **bootstrap-time ordering**;
the detailed _how_ is owned by [`../cli-spec/`](../cli-spec/README.md) and is not restated here.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the Rust
  [binding runbook](runbook.md) are done — a buildable, gated crate exists.

## Add these, in this order

When scaffolding a CLI, layer these on the buildable crate in order — each links to the spec chapter
that details it:

1. **Directory & crate layout for a CLI.** Establish the binary/library split and module tree. →
   [`../cli-spec/00-directory-tree.md`](../cli-spec/00-directory-tree.md),
   [`../cli-spec/01-crate-layout.md`](../cli-spec/01-crate-layout.md).
2. **Argument parsing & subcommands.** Define the command surface (e.g. with `clap`). →
   [`../cli-spec/02-subcommand-pattern.md`](../cli-spec/02-subcommand-pattern.md).
3. **Error handling.** A consistent error type and exit-code strategy. →
   [`../cli-spec/03-error-handling.md`](../cli-spec/03-error-handling.md).
4. **Logging.** Structured, level-controlled output. →
   [`../cli-spec/04-logging.md`](../cli-spec/04-logging.md).
5. **Configuration.** Config file + env + flag precedence. →
   [`../cli-spec/05-config.md`](../cli-spec/05-config.md).

For testing, dependencies, naming, and style, continue through the rest of
[`../cli-spec/`](../cli-spec/README.md).

## Binary distribution (later phase)

Shipping prebuilt CLI binaries (installers, `cargo-binstall`) is release-phase work via cargo-dist —
see [`../release-workflow-spec/`](../release-workflow-spec/README.md). Bootstrap stops at a working,
gated CLI crate.
