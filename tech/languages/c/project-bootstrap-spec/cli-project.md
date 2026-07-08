# C CLI project — implementation-kind additions

What a **CLI** project adds on top of the general recipe and the C binding: an entry point, argument
parsing, and a consistent exit-code strategy. This file owns only the **bootstrap-time ordering**.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the C
  [binding runbook](runbook.md) are done — a buildable, gated project exists.

## Add these, in this order

1. **Entry point & build target.** Add `src/main.c` and a build-system executable target (CMake
   `add_executable`, Meson `executable()`). → [00 — Toolchain & layout](00-toolchain-and-layout.md).

2. **Argument parsing.** Define the command surface. Use POSIX `getopt`/`getopt_long` for simple
   tools; reach for `argp` (glibc) or a vendored parser like `argparse` for richer subcommand trees.

3. **Exit codes.** Adopt a consistent convention — `0` success, non-zero per failure class; the
   `sysexits.h` codes (`EX_USAGE`, `EX_DATAERR`, …) are a reasonable baseline.

4. **Diagnostics.** Route human-facing errors to `stderr`, results to `stdout`, and keep a single
   error-reporting helper so messages are uniform.

## Distribution (later phase)

Packaging and installing the built binary (system packages, `make install` prefixes) is
release-phase work, not bootstrap. Bootstrap stops at a working, gated CLI executable.
