# 00 — Toolchain & layout

The Lua ecosystem choices for a fresh project: which runtime to target, how to pin it, how the
package manager and rockspec work, and how the module tree is addressed by `require`.

## Runtime — Lua 5.x vs LuaJIT

Lua has no single canonical version; pick deliberately and pin it:

- **Lua 5.4 / 5.3** — the reference PUC-Rio interpreter; default for standalone tools and libraries.
- **Lua 5.1** — target this when your consumer is LuaJIT-bound (Neovim, OpenResty) since LuaJIT
  tracks the 5.1 syntax and standard library.
- **LuaJIT** — the JIT-compiled 5.1-compatible runtime; choose it for performance-critical or
  embedded (Neovim/nginx) targets.

The runtime choice drives everything downstream (rockspec `lua` dependency, luacheck `std`, CI
matrix), so decide before scaffolding.

## Package manager — LuaRocks + rockspec

[LuaRocks](https://luarocks.org/) is the de-facto package manager. A project's manifest is a
**rockspec** (`<name>-<version>.rockspec`) declaring `package`, `version`, `source`, `dependencies`,
and a `build` section mapping module names to files:

```lua
package = "my-rock"
version = "dev-1"
source = { url = "git+https://github.com/user/my-rock.git" }
dependencies = { "lua >= 5.1" }
build = {
  type = "builtin",
  modules = { ["my-rock"] = "src/my-rock/init.lua" },
}
```

Keep the bootstrap rockspec minimal (`dev-1`); publish-grade metadata (license, tagged `source`,
labels) is release-phase work. Use `luarocks make` / `luarocks build` to install locally into the
project tree.

## Module & `require` layout

Lua resolves modules through `package.path`; a module named `foo.bar` maps to `foo/bar.lua` (or
`foo/bar/init.lua`). Establish the tree so the rockspec `modules` map and `require` strings line up:

```text
src/my-rock/init.lua   -- require("my-rock")
src/my-rock/util.lua   -- require("my-rock.util")
spec/                  -- busted tests
```

Bootstrap owns getting a `require`-able tree in place; the detailed layout is small enough to live
here for now.

## Version pinning + Nix

Pin the interpreter and tooling (`luarocks`, `stylua`, `luacheck`, `busted`) in the Nix devShell so
local and CI share one runtime — see
[nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md). The devShell hosts
the chosen `lua`/`luajit` and puts LuaRocks on `PATH`, closing the "works on my machine" gap before
any code is written.

## Automation

`bootstrap-nix` provisions the devShell that hosts the runtime and tooling; the steps above are the
SoT. See
[general 07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md).
