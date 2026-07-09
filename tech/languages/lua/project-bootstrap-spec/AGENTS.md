---
digest-of: tech/languages/lua/project-bootstrap-spec
last-synced: 2026-07-09
source-files:
  - README.md
  - runbook.md
  - 00-toolchain-and-layout.md
  - 01-quality-gates.md
  - rock-library.md
token-estimate: 780
---

# AGENTS

## Scope

Lua binding of the general `tech/programming/project-bootstrap/` shelf: the once-per-project Lua
setup that takes an empty repo to a scaffolded, gated, `require`-able project ready for feature
work. It **overlays** the general spine (repo, license, governance, dev env, CI, security) and never
restates it; it owns only the Lua ecosystem choices (runtime, LuaRocks/rockspec, quality gates) and
one implementation-kind ordering (rock library). Publishing (`luarocks upload`, publish-grade
rockspec metadata) is a later release phase, out of scope here.

## Key Points

- **Runtime (decide first, then pin):** Lua has no single canonical version. Lua 5.4/5.3 is the
  reference PUC-Rio interpreter and the default for standalone tools/libraries; Lua 5.1 when the
  consumer is LuaJIT-bound (Neovim, OpenResty); LuaJIT for performance-critical/embedded
  (Neovim/nginx) targets. The choice drives rockspec `lua` dependency, luacheck `std`, and the CI
  matrix — decide before scaffolding.
- **Package manager:** LuaRocks is the de-facto manager. The manifest is a **rockspec**
  (`<name>-<version>.rockspec`) declaring `package`, `version`, `source`, `dependencies`, and a
  `build` section mapping module names to files. Keep the bootstrap rockspec minimal (`dev-1`);
  publish-grade metadata (license, tagged `source`, labels) is release-phase. `luarocks make` /
  `luarocks build` installs locally into the project tree.
- **Layout:** module tree addressed by `require` via `package.path` — `foo.bar` maps to
  `foo/bar.lua` (or `foo/bar/init.lua`). Line up the rockspec `modules` map with `require` strings,
  e.g. `src/<name>/init.lua` (`require("<name>")`), `src/<name>/util.lua`, `spec/` for busted tests.
- **Version pin + Nix:** pin the interpreter and tooling (`luarocks`, `stylua`, `luacheck`,
  `busted`) in the Nix devShell so local and CI share one runtime; the devShell hosts the chosen
  `lua`/`luajit` and puts LuaRocks on `PATH` (`nix/02-per-project-devshell`).
- **Quality gates:** `stylua` (formatter; `.stylua.toml` only to deviate from defaults; enforce
  `stylua --check .`), `luacheck` (linter; `.luacheckrc` declaring `std` matched to the chosen
  runtime, e.g. `lua54`/`luajit`/`min`, plus allowed globals; `luacheck .`), `busted` (test runner;
  specs under `spec/`). `busted` and `luacheck` are themselves rocks — declare under rockspec
  `test_dependencies`/`build_dependencies` or install into the devShell. Wire all three into
  pre-commit so failures surface locally.
- **Rock-library kind (bootstrap-time ordering):** write the initial `<name>-dev-1.rockspec` → lay
  out `src/<name>/init.lua` + submodules matching the `modules` map → verify the build locally with
  `luarocks make`/`luarocks build` and confirm the module is `require`-able from the devShell → add
  `busted` specs under `spec/` covering the public API. Stops at a locally-buildable, gated,
  `require`-able rock; tagging a real rockspec and `luarocks upload` is release-phase.
- **Automation:** `bootstrap-nix` provisions the devShell hosting runtime + tooling;
  `bootstrap-precommit` and `bootstrap-taskrunner` wire the gates; `bootstrap-ci` continues the
  general spine. The notes are the SoT; see general `07-automation-with-cog.md`.

## Source Map

| Topic                                                           | File                         |
| --------------------------------------------------------------- | ---------------------------- |
| Binding index, how-to-use, implementation-kinds list, related   | `README.md`                  |
| Ordered Lua overlay steps (the _what_/_in what order_)          | `runbook.md`                 |
| Runtime (5.x vs LuaJIT), LuaRocks/rockspec, `require` tree, Nix | `00-toolchain-and-layout.md` |
| `stylua` / `luacheck` / `busted` + pre-commit wiring            | `01-quality-gates.md`        |
| Rock-library bootstrap ordering (rockspec, module tree, build)  | `rock-library.md`            |

## Maintenance Notes

- General spine: `../../../programming/project-bootstrap/`. Runtime/devShell host:
  `../../../tools/nix/02-per-project-devshell.md`. Lua reference notes: `../README.md`.
- `cli-project.md` (standalone Lua tool) and `neovim-plugin.md` (Neovim runtime plugin) are declared
  followup kinds; add them (and refresh `source-files`) when they land.
- Re-verify the default-tool choices (`stylua`, `luacheck`, `busted`, LuaRocks) and runtime guidance
  against upstream when regenerating.
- No conflicts among the current source files.
