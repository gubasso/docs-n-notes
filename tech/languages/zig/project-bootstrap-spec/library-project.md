# Zig library project — implementation-kind additions

What a **library/module** adds on top of the general recipe and the Zig binding: an exported module,
the `build.zig` wiring that makes it consumable, and the `build.zig.zon` surface downstream projects
depend on. This file owns only the **bootstrap-time ordering**; the buildable, gated project comes
from the [binding runbook](./runbook.md) first.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the Zig
  [binding runbook](./runbook.md) are done — a project that `zig build` succeeds on exists.

## Add these, in this order

1. **Keep the module entry point.** Keep `src/root.zig` as the library's public entry and drop the
   `main.zig` executable step if the project is a pure library. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md).

2. **Export the module in `build.zig`.** Use `b.addModule("<name>", ...)` so consumers can pull the
   module by name. This is what makes the library importable — a library is defined by the exported
   module, not by a build flag.

3. **Set the consumable manifest surface.** In `build.zig.zon`, set `.name`, `.version`, and
   `.paths` so the package is fetchable and complete when consumed via `zig fetch --save`. This is
   the contract downstream projects depend on. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md).

4. **Tests as the public contract.** Put `test { ... }` blocks against the exported API and run them
   with `zig build test`; they document and gate the surface consumers rely on. →
   [01 — Quality gates](./01-quality-gates.md).

## How consumers depend on it

A downstream project adds this library to its own `build.zig.zon` with
`zig fetch --save <url-or-path>` (which records a content hash), then imports the exported module in
its `build.zig` via `dependency(...).module("<name>")`. Bootstrap's job is to make that surface
exist and stay green; publishing/tagging is later release-phase work.
