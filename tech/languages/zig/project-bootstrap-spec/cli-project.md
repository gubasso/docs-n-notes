# Zig CLI project — implementation-kind additions

What a **CLI executable** adds on top of the general recipe and the Zig binding: an executable build
step, argument handling, and a small command surface. This file owns only the **bootstrap-time
ordering**; the buildable, gated project comes from the [binding runbook](./runbook.md) first.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the Zig
  [binding runbook](./runbook.md) are done — a project that `zig build` succeeds on exists.

## Add these, in this order

1. **Keep the executable build step.** In `build.zig`, keep the `addExecutable` step (and its
   install/run steps) so `zig build run` works; drop the library `root.zig` module if the project is
   a pure CLI. → [00 — Toolchain & layout](./00-toolchain-and-layout.md).

2. **Argument parsing.** Zig's standard library has no `clap`-style parser; read `std.process.args`
   (or `argsAlloc`) directly, or add a community arg-parser as a `build.zig.zon` dependency with
   `zig fetch --save`. Keep the parser choice explicit and minimal at bootstrap.

3. **Exit codes & errors.** Decide how errors map to process exit status early — return an error
   union from `main` (Zig maps it to a non-zero exit) or call `std.process.exit(code)` explicitly.

4. **Wire run and test steps.** Confirm `zig build run` launches the CLI and `zig build test` runs
   the `test { ... }` blocks. → [01 — Quality gates](./01-quality-gates.md).

## Later phases

Shipping prebuilt CLI binaries (cross-compiled release artifacts, installers) is release-phase work,
not bootstrap. Zig's built-in cross-compilation makes this straightforward later; bootstrap stops at
a working, gated CLI executable.
