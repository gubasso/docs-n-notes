# Lua rock library — implementation-kind additions

What a **LuaRocks module** (rock) adds on top of the general recipe and the Lua binding: a rockspec,
a `require`-addressable module tree, and a local build/install loop. This file owns only the
**bootstrap-time ordering**; runtime and quality-gate detail live in
[00 — Toolchain & layout](./00-toolchain-and-layout.md) and
[01 — Quality gates](./01-quality-gates.md) and are not restated here.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the Lua
  [binding runbook](./runbook.md) are done — a runtime is pinned and gates are wired.

## Add these, in this order

1. **Write the initial rockspec.** Create `<name>-dev-1.rockspec` with `package`, `version`,
   `source`, `dependencies`, and a `build` section. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md).
2. **Lay out the module tree.** Establish `src/<name>/init.lua` and submodules so the rockspec
   `modules` map matches the `require` strings consumers will use. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md).
3. **Verify the build locally.** Run `luarocks make` (or `luarocks build`) against the rockspec and
   confirm the module is `require`-able from the devShell.
4. **Add tests under `spec/`.** Cover the public API with `busted`. →
   [01 — Quality gates](./01-quality-gates.md).

## Publishing (later phase)

Tagging a real `<name>-<version>` rockspec and `luarocks upload` to luarocks.org is release-phase
work, not bootstrap. Bootstrap stops at a locally-buildable, gated, `require`-able rock.
