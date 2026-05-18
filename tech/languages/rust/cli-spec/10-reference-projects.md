# 10 — Reference Projects (Rust)

> Prerequisite: [General principles — Reference Projects](../../../programming/cli-design/09-reference-projects.md) for the language-agnostic organizational patterns these projects exemplify. This chapter zooms in on the Rust specifics.

Real-world Rust CLIs worth studying. For each: shape, what they do well, what to copy.

## Single-crate CLIs

### [`sharkdp/fd`](https://github.com/sharkdp/fd) — file finder

Single crate, ~10k LOC. Layout:

```
src/
├─ main.rs
├─ cli.rs               # clap derive
├─ config.rs
├─ walk.rs              # core traversal
├─ output.rs
├─ error.rs
├─ exit_codes.rs        # explicit exit-code mapping
├─ exec/                # --exec implementation
├─ filter/              # type/extension/size filters
└─ fmt/                 # formatting
```

Copy: the dedicated `exit_codes.rs`, the per-feature subdirectories (`exec/`, `filter/`, `fmt/`).

### [`sharkdp/bat`](https://github.com/sharkdp/bat) — pretty `cat`

**The canonical lib+bin pattern.** `src/lib.rs` exposes the rendering engine; `src/bin/bat/` is the thin CLI on top:

```
src/
├─ lib.rs               # public API
├─ assets.rs
├─ printer.rs
├─ ...
└─ bin/
   └─ bat/
      ├─ main.rs
      ├─ app.rs         # clap
      └─ ...
```

Copy: the `src/lib.rs` + `src/bin/<name>/` split when your logic is reusable.

### [`extrawurst/gitui`](https://github.com/extrawurst/gitui) — git TUI

Single crate, TUI-centric:

```
src/
├─ main.rs
├─ app.rs               # top-level state machine
├─ args.rs              # clap
├─ components/          # one file per TUI component
├─ tabs/
├─ popups/
└─ keys/
```

Copy: the `components/` + `tabs/` + `popups/` split for TUI projects. Less relevant for pure CLIs but instructive.

### [`ouch-org/ouch`](https://github.com/ouch-org/ouch) — universal compressor

```
src/
├─ main.rs
├─ cli/
├─ commands/
├─ utils/
├─ archive/             # topical: archive formats
└─ non_archive/         # topical: single-file compressors
```

Copy: the `cli/` + `commands/` split this spec recommends. Topical dirs (`archive/`, `non_archive/`) for plugin-like features.

## Workspace CLIs

### [`BurntSushi/ripgrep`](https://github.com/BurntSushi/ripgrep) — fast grep

Workspace with reusable library crates:

```
crates/
├─ core/                # bin + flags + glue
├─ matcher/             # grep-matcher: matcher trait
├─ regex/               # grep-regex: regex matcher impl
├─ searcher/            # grep-searcher: search runner
├─ printer/             # grep-printer: output formats
├─ pcre2/
├─ globset/             # globbing
├─ ignore/              # gitignore traversal
└─ ...
```

Copy: extracting reusable subsystems into library crates when they have value independent of the binary. The `globset` and `ignore` crates are used by dozens of other projects.

### [`rust-lang/cargo`](https://github.com/rust-lang/cargo) — Rust's package manager

```
src/
├─ cargo/               # the library
└─ bin/
   └─ cargo/
      ├─ main.rs
      └─ commands/      # one file per subcommand, uniform `exec()` signature
```

Each `commands/<name>.rs` exposes:

```rust
pub fn cli() -> clap::Command { ... }
pub fn exec(gctx: &GlobalContext, args: &ArgMatches) -> CliResult { ... }
```

Copy: the uniform `exec()` signature across subcommands. Cargo uses imperative clap (not derive) but the discipline is the same.

### [`jj-vcs/jj`](https://github.com/jj-vcs/jj) — Jujutsu VCS

```
cli/src/
├─ main.rs
├─ cli_util.rs
├─ command_error.rs
├─ commands/            # one file per subcommand
└─ ui.rs                # bounded UI module
```

Copy: `command_error.rs` as a focused error module; `ui.rs` as the single rendering surface.

### [`eza-community/eza`](https://github.com/eza-community/eza) — modern `ls`

```
src/
├─ main.rs
├─ options/             # clap + arg parsing
├─ output/              # rendering
├─ fs/                  # filesystem abstractions
└─ theme/
```

Copy: the `options/` (parsing) + `output/` (rendering) split if your CLI has substantial formatting logic.

### [`starship/starship`](https://github.com/starship/starship) — shell prompt

```
src/
├─ main.rs
├─ context.rs           # one big AppContext-like struct
├─ module.rs            # trait for modules
├─ modules/             # one file per prompt module
├─ configs/
├─ formatter/
└─ utils/
```

Copy: the `context.rs` + plugin-like `modules/` pattern when you have user-extensible features.

### [`helix-editor/helix`](https://github.com/helix-editor/helix) — modal editor

Aggressive workspace split:

```
helix-core/             # pure types: rope, position, syntax
helix-view/             # view layer
helix-term/             # the binary
helix-tui/              # TUI primitives
helix-lsp/              # LSP client
helix-loader/           # config + assets
helix-event/            # event bus
xtask/                  # build automation
```

Copy: workspace boundaries that align with **dependency direction** — `helix-core` depends on nothing app-specific, `helix-term` depends on everything. Lower-level crates do not depend on higher-level ones.

### [`atuinsh/atuin`](https://github.com/atuinsh/atuin) — shell history

```
crates/
├─ atuin/               # CLI binary
├─ atuin-client/        # client-side logic
├─ atuin-server/        # server-side logic
└─ atuin-common/        # shared types
```

Copy: the four-crate split (`bin` + `client` + `server` + `common`) when you ship both client and server.

### [`zellij-org/zellij`](https://github.com/zellij-org/zellij) — terminal multiplexer

```
zellij-server/
zellij-client/
zellij-utils/
zellij-tile/            # plugin API
default-plugins/
```

Copy: a separate `<app>-tile` (or `<app>-plugin-api`) crate when you support plugins — keeps the plugin ABI small and stable.

## Quick comparison

| Project | LOC | Shape | Key takeaway |
|---------|-----|-------|--------------|
| fd | ~10k | single crate | Per-feature subdirs. |
| bat | ~15k | single crate, `src/lib.rs` + `src/bin/<name>/` | Reusable lib + thin bin. |
| gitui | ~30k | single crate | TUI component layout. |
| ouch | ~10k | single crate | `cli/` + `commands/` matches this spec. |
| jj | ~80k | workspace, `cli/` subcrate | `command_error.rs`, focused `ui.rs`. |
| eza | ~30k | single crate | `options/` + `output/` split. |
| starship | ~40k | single crate | `context.rs` + `modules/`. |
| cargo | ~200k | workspace, `bin/cargo/commands/` | Uniform `exec()` per subcommand. |
| ripgrep | ~50k | workspace | Subsystems as published libs. |
| helix | ~120k | workspace, ~8 crates | Dependency-direction boundaries. |
| atuin | ~40k | workspace, 4 crates | Bin + client + server + common. |
| zellij | ~80k | workspace | Plugin ABI crate. |

## What to copy from your own repos

From `riptask`:

- The exit-code matrix in `src/error.rs:52-118` — one variant per code, unit-tested.
- The `domain/` + `adapters/` + `services/` vocabulary.
- The `[[bin]]` rename trick in `Cargo.toml` (crate `riptask`, binary `tsk`).
- The help-group manifest with a drift test (`src/cli.rs:9-31`, `src/cli.rs:903-937`).

**Don't copy** from riptask:

- The monolithic `src/cli.rs:1-1558`. Split into `cli/mod.rs` + per-subcommand files.
- Per-command tokio runtime construction (`src/main.rs:95-159`). Build one runtime in `main`.
- Custom env var `RIPTASK_LOG`. Use `RUST_LOG`.
- The ambiguous `models/` vs `domain/` split. Pick `domain/` only.

From `ripwork`:

- The parse-shape / runtime-shape split: `cli/<name>.rs` + `workflows/<name>.rs` (this spec calls it `commands/<name>.rs`).
- `pub(crate)` everywhere (`src/runtime/mod.rs:1-7`).
- The `ui/` module as the only place that prints (`CLAUDE.md:46-52`).
- Figment-based config (`src/config.rs:1-13`).
- Per-file `//!` headers stating purpose and non-purpose (`src/main.rs:1-10`).
- ADR references in `Cargo.toml` comments (`Cargo.toml:19-20`).
- `trybuild` for typestate invariants (`tests/trybuild.rs`).

**Don't copy** from ripwork:

- Dead `src/lib.rs:1-13` that exports nothing. Delete it or make it real.
- Recursive `#[from]` chains in `src/error.rs:144-188`. Lift shared infra instead.
- Mixing workflow-args and `common.rs`/`preflight.rs` in one directory. Keep `cli/` strictly clap-derive.
