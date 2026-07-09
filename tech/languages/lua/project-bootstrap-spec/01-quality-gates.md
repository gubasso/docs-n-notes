# 01 — Quality gates

The Lua concretion of the general
[quality gates](../../../programming/project-bootstrap/04-quality-gates.md) chapter.

## Formatter — `stylua`

[`stylua`](https://github.com/JohnnyMorganz/StyLua) is the de-facto Lua formatter. Add a
`.stylua.toml` only if you deviate from defaults; enforce in CI with:

```bash
stylua --check .
```

## Linter — `luacheck`

[`luacheck`](https://github.com/lunarmodules/luacheck) is the static linter. Configure it with a
`.luacheckrc` that declares the runtime `std` (e.g. `std = "lua54"`, `"luajit"`, or `"min"`) and any
allowed globals, then fail the build on findings:

```bash
luacheck .
```

Matching `std` to the runtime chosen in [00 — Toolchain & layout](./00-toolchain-and-layout.md) is
what makes global/undefined-variable warnings accurate.

## Tests — `busted`

[`busted`](https://lunarmodules.github.io/busted/) is the standard test runner; place specs under
`spec/` and run:

```bash
busted
```

`busted` and `luacheck` are themselves rocks — declare them under a rockspec `test_dependencies` /
`build_dependencies` block or install them into the devShell.

## Pre-commit wiring

Wire `stylua --check`, `luacheck`, and `busted` into the pre-commit hooks from the general
[04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md) so failures surface
locally in seconds.

## Publish-readiness (later phase)

Publish-grade checks (`luarocks upload`, rockspec metadata completeness) belong to a later release
phase, not bootstrap. Bootstrap only guarantees the project formats, lints, and tests clean.
