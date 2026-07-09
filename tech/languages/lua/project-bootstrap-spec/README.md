# Lua — bootstrap a new project (spec/binding)

The Lua binding of
[`tech/programming/project-bootstrap/`](../../../programming/project-bootstrap/README.md). It
applies the general once-per-project recipe with concrete Lua tooling — interpreter/runtime choice,
LuaRocks

- rockspec layout, and the stylua/luacheck/busted quality gates — and links to Lua
  implementation-kinds.

This binding **overlays** the general spine; it does not restate it. Read the general recipe first,
then the Lua specifics here.

## How to use this binding

1. Read the general [hub](../../../programming/project-bootstrap/README.md) and
   [general runbook](../../../programming/project-bootstrap/runbook.md) — the cross-language _what_.
2. Follow this [`runbook.md`](./runbook.md) for the Lua-specific overlay steps.
3. Jump to your implementation-kind file (e.g. [`rock-library.md`](./rock-library.md)).

## Index

| # | Chapter                                            | One-line hook                                                                |
| - | -------------------------------------------------- | ---------------------------------------------------------------------------- |
| 0 | [Toolchain & layout](./00-toolchain-and-layout.md) | Lua 5.x vs LuaJIT, LuaRocks + rockspec, `require` module tree, Nix devShell. |
| 1 | [Quality gates](./01-quality-gates.md)             | `stylua`, `luacheck`, `busted`, pre-commit wiring.                           |

## Implementation kinds

- [`rock-library.md`](./rock-library.md) — LuaRocks module: the bootstrap-time ordering for a
  publishable rock (rockspec, module tree, `luarocks make`/`build`).

`cli-project.md` (standalone Lua tool) and `neovim-plugin.md` (Neovim runtime plugin) are followups;
add them when you bootstrap those kinds.

## Related

- [General project-bootstrap](../../../programming/project-bootstrap/README.md) — the cross-language
  recipe this binding overlays.
- [Lua reference notes](../README.md) — syntax, runtime, and ecosystem guidance.
- [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md) — how the devShell
  hosts the Lua runtime and tooling.
