# Python CLI project — implementation-kind additions

What a **CLI** project adds on top of the general recipe and the Python binding: argument parsing,
logging, configuration, and a subcommand shape. This file owns only the **bootstrap-time ordering**.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the Python
  [binding runbook](runbook.md) are done — an importable, gated project exists.

## Add these, in this order

1. **Console-script entry point.** Declare the CLI under `[project.scripts]` in `pyproject.toml`
   (e.g. `mytool = "mytool.cli:main"`) so `uv run mytool` and the installed package both expose it.
   → [00 — Toolchain & layout](00-toolchain-and-layout.md).

2. **Argument parsing & subcommands.** Define the command surface. Use `argparse` (stdlib, zero
   deps) for a small tool, or `click` / `typer` for richer subcommand trees, help, and completion.
   Pick one and keep it as the single owner.

3. **Error handling.** A consistent error type and exit-code strategy — return non-zero on failure,
   print diagnostics to stderr.

4. **Logging.** Use the stdlib `logging` module with a level controlled by a `--verbose`/`-v` flag
   or an env var; keep human output on stdout and logs on stderr.

5. **Configuration.** Establish config-file + env + flag precedence (flags override env override
   file). Validate config early — e.g. with `pydantic` — and fail fast on bad input.

## Binary distribution (later phase)

Shipping the CLI to users (PyPI, `pipx`/`uv tool install`, or frozen executables via `PyInstaller`)
is release-phase work — see [`../release-workflow-spec/`](../release-workflow-spec/README.md).
Bootstrap stops at a working, gated CLI project.
