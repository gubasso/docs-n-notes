# Zig — bootstrap a new project (spec/binding)

The Zig binding of
[`tech/programming/project-bootstrap/`](../../../programming/project-bootstrap/README.md). It
applies the general once-per-project recipe with concrete Zig tooling — `zig init`, the `build.zig`
/ `build.zig.zon` pair, version pinning, and the lean built-in quality gates (`zig fmt`,
`zig build test`) — and links to Zig implementation-kinds.

This binding **overlays** the general spine; it does not restate it. Read the general recipe first,
then the Zig specifics here.

## How to use this binding

1. Read the general [hub](../../../programming/project-bootstrap/README.md) and
   [general runbook](../../../programming/project-bootstrap/runbook.md) — the cross-language _what_.
2. Follow this [`runbook.md`](./runbook.md) for the Zig-specific overlay steps.
3. Jump to your implementation-kind file (e.g. [`cli-project.md`](./cli-project.md) or
   [`library-project.md`](./library-project.md)).

## Index

| # | Chapter                                            | One-line hook                                                                |
| - | -------------------------------------------------- | ---------------------------------------------------------------------------- |
| 0 | [Toolchain & layout](./00-toolchain-and-layout.md) | `zig init`, `build.zig` + `build.zig.zon`, `src/` layout, version pin + Nix. |
| 1 | [Quality gates](./01-quality-gates.md)             | `zig fmt`, `zig build test`, compile-time safety, pre-commit wiring.         |

## Implementation kinds

- [`cli-project.md`](./cli-project.md) — Zig CLI executable: the bootstrap-time ordering for
  argument parsing, the run/test steps, and a small command surface.
- [`library-project.md`](./library-project.md) — Zig library/module consumable via `build.zig.zon`:
  the exported module, the `addModule` wiring, and what downstream consumers depend on.

`web-service.md` and other kinds are followups; add them when you bootstrap those shapes.

## Related

- [General project-bootstrap](../../../programming/project-bootstrap/README.md) — the cross-language
  recipe this binding overlays.
- [Zig references hub](../README.md) — anyzig, ZLS, and troubleshooting notes.
- [nix/templates/zig](../../../tools/nix/templates/zig/) — the Nix devShell template that hosts the
  `zig` + `zls` toolchain.
