# zls Per-Project Setup with anyzig and Neovim (`.nvim.lua`)

This guide documents a practical workflow for using `zls` per Zig project while keeping `anyzig` as
the Zig version manager.

It covers:

- first-time host setup
- first-time project setup
- optional project-level `zls` configuration

## What this solves

There are two separate concerns:

1. Runtime Zig resolution:

- `zls` invokes `zig`
- `zig` resolves through `anyzig`
- `anyzig` reads project `build.zig.zon` and selects the Zig version

1. `zls` compatibility:

- `zls` itself must match the Zig release it was built against
- for multi-version Zig projects, keep one `zls` binary per Zig version

This guide uses a host cache:

- `~/.local/share/zls/<zig-version>/zls`

And project override:

- project root `./.nvim.lua`

## Prerequisites

- `anyzig` is installed and `zig` is available in `PATH`
- Neovim is configured with `opt.exrc = true`
- You use the existing dotfiles LSP config (global `zls` setup already present)

Check quickly:

```bash
command -v zig
zig any version
```

## First-time host setup

### 1) Clone `zls` source once

```bash
git clone https://github.com/zigtools/zls.git ~/.local/src/zls
```

### 2) Build and cache `zls` for a Zig version

Use matching Zig and `zls` tags from official compatibility guidance.

```bash
ZIG_VER="0.13.0"
ZLS_TAG="0.13.0"

cd ~/.local/src/zls
git fetch --tags
git checkout "$ZLS_TAG"
zig "$ZIG_VER" build -Doptimize=ReleaseSafe

install -Dm755 zig-out/bin/zls "$HOME/.local/share/zls/$ZIG_VER/zls"
```

#### Alternative: download signed release

Use pre-built binaries from [zigtools/zls releases](https://github.com/zigtools/zls/releases).

```bash
ZIG_VER="0.15.0"
ZLS_TAG="$ZIG_VER" # zls tags usually match zig release versions
ASSET="zls-x86_64-linux.tar.xz"

cd "$(mktemp -d)"
curl -fsSLO "https://github.com/zigtools/zls/releases/download/$ZLS_TAG/$ASSET"
curl -fsSLO "https://github.com/zigtools/zls/releases/download/$ZLS_TAG/$ASSET.minisig"

minisign -Vm "$ASSET" -P 'RWR+9B91GBZ0zOjh6Lr17+zKf5BoSuFvrx2xSeDE57uIYvnKBGmMjOex'

mkdir -p extract
tar -xJ -C extract -f "$ASSET"
install -Dm755 extract/zls "$HOME/.local/share/zls/$ZIG_VER/zls"
```

Some older tags (for example `0.13.0`) do not provide `.minisig` assets. Prefer signed releases.

Repeat this step for each Zig version you actively use.

### 3) Verify cached binary

```bash
~/.local/share/zls/0.13.0/zls --version
```

## First-time project setup

### 1) Pin project Zig version

For new projects, bootstrap with an explicit version:

```bash
zig <zig-version> init
```

Verify project pin:

```bash
rg -n "minimum_zig_version|mach_zig_version" build.zig.zon
```

### 2) Add project `.nvim.lua`

Create this file in the project root:

```lua
local zig_version = "0.13.0" -- must match build.zig.zon
local zls_path = vim.fn.expand("~/.local/share/zls/" .. zig_version .. "/zls")

if vim.fn.executable(zls_path) == 1 then
  vim.lsp.config("zls", {
    cmd = { zls_path },
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
  })
  vim.lsp.enable("zls")
else
  vim.notify("Missing zls for Zig " .. zig_version .. ": " .. zls_path, vim.log.levels.ERROR)
end
```

### Automated setup

From project root (requires `build.zig.zon`):

```bash
zig-zls-init
```

This downloads, verifies, and caches the matching `zls` binary, then scaffolds `.nvim.lua`.

### 3) Open project and trust local config

```bash
cd /path/to/project
nvim .
```

If prompted, allow loading local `.nvim.lua`.

### 4) Verify inside Neovim

Run:

- `:LspInfo`

Confirm:

- `zls` is attached
- command path points to `~/.local/share/zls/<zig-version>/zls`

## Ongoing workflow

When project Zig version changes:

1. update `build.zig.zon`
2. build/cache matching `zls`
3. update `.nvim.lua` `zig_version`
4. reopen Neovim and verify with `:LspInfo`

Or automate steps 2–3 from the project root:

```bash
zig-zls-init --force
```

## Optional project files

### `zls.json`

Use for `zls` behavior toggles (example: build-on-save).

```json
{
  "enable_build_on_save": true
}
```

### `zls.build.json`

Use for complex build options so diagnostics match project build mode.

```json
{
  "build_options": [
    { "name": "enable-tracy", "value": "true" }
  ]
}
```

## Troubleshooting

### `zls` not attached

- check `.nvim.lua` path and `zig_version`
- confirm binary exists and is executable:
  - `test -x ~/.local/share/zls/<zig-version>/zls && echo ok`
- run `:LspInfo`

### Wrong `zls` version behavior

- rebuild `zls` with matching Zig version/tag
- confirm `.nvim.lua` points to the intended cache path

### Local config not applied

- confirm `opt.exrc = true` in Neovim config
- open Neovim from project root
- accept local config prompt for `.nvim.lua`

## Official references

- [zls install](https://zigtools.org/zls/install/)
- [zls configure](https://zigtools.org/zls/configure/)
- [zls per-build config](https://zigtools.org/zls/configure/per-build/)
- [zls Neovim integration](https://zigtools.org/zls/editors/neovim/)
- [anyzig repository](https://github.com/marler8997/anyzig)
- [Zig documentation](https://ziglang.org/documentation/)
