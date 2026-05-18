# 02 — Subcommand Pattern (Rust)

> Prerequisite: [General principles — Architecture](../../../programming/cli-design/00-architecture.md) (the four-edit rule, parse-shape vs runtime-shape, when to extract a service). This chapter is the Rust implementation using `clap`.

## The four files (Rust + clap)

For the four-edit rule's rationale and anti-patterns, see the general chapter. In Rust with `clap`, the four files are:

1. **`src/cli/widget.rs`** — parse-shape (clap struct).
2. **`src/cli/mod.rs`** — register the variant in the `Commands` enum.
3. **`src/commands/widget.rs`** — handler (free `run` function).
4. **`src/main.rs`** — dispatch arm.

Real-world reminder of what this prevents: a 1500-line `cli.rs` (`riptask/src/cli.rs:1-1558`).

## File-by-file skeleton

### 1. `src/cli/widget.rs` (parse-shape)

```rust
//! `widget` subcommand: parse-shape.
//!
//! Holds clap derive struct only. No I/O, no business logic.

#[derive(Debug, clap::Args)]
pub struct WidgetArgs {
    /// Optional widget ID to operate on. If omitted, operates on all widgets.
    pub id: Option<String>,

    /// Print what would happen without modifying anything.
    #[arg(short = 'n', long)]
    pub dry_run: bool,

    /// Limit to widgets matching this glob pattern.
    #[arg(long, value_name = "PATTERN")]
    pub filter: Option<String>,
}
```

Rules:

- One file per subcommand.
- One `pub struct <Verb>Args` deriving `clap::Args`.
- All arg-level docs go on fields as `///` comments — clap renders them in `--help`.
- No `impl` blocks beyond what clap demands. The args-to-domain projection lives in `commands/widget.rs`.

### 2. `src/cli/mod.rs` (register the variant)

```rust
//! Root CLI parser.

pub mod widget;
// ... other subcommand modules

#[derive(Debug, clap::Parser)]
#[command(name = "app", version, about, long_about = None)]
pub struct Cli {
    #[command(flatten)]
    pub global: GlobalArgs,

    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Debug, clap::Args)]
pub struct GlobalArgs {
    /// Increase log verbosity (-v info, -vv debug, -vvv trace). Overridden by RUST_LOG.
    #[arg(short, long, action = clap::ArgAction::Count, global = true)]
    pub verbose: u8,

    /// Path to an alternate config file.
    #[arg(long, value_name = "PATH", global = true)]
    pub config: Option<std::path::PathBuf>,
}

#[derive(Debug, clap::Subcommand)]
pub enum Commands {
    /// Operate on widgets.
    Widget(widget::WidgetArgs),
    // ... other variants
}
```

### 3. `src/commands/widget.rs` (handler)

```rust
//! `widget` subcommand: runtime-shape.
//!
//! Projects CLI args into the service-layer call, renders output via `ctx.ui`,
//! returns a typed error.

use crate::cli::widget::WidgetArgs;
use crate::context::AppContext;
use crate::error::AppError;

pub fn run(ctx: &AppContext, args: WidgetArgs) -> Result<(), AppError> {
    let request = Request::from_cli(args)?;
    let report = execute(ctx, request)?;
    ctx.ui.render_widget(&report);
    Ok(())
}

struct Request {
    id: Option<crate::domain::widget::WidgetId>,
    dry_run: bool,
    filter: Option<glob::Pattern>,
}

impl Request {
    fn from_cli(args: WidgetArgs) -> Result<Self, AppError> {
        let id = args.id.map(|s| s.parse()).transpose()?;
        let filter = args.filter.map(|p| glob::Pattern::new(&p)).transpose()?;
        Ok(Self { id, dry_run: args.dry_run, filter })
    }
}

struct Report { /* ... */ }

fn execute(ctx: &AppContext, req: Request) -> Result<Report, AppError> {
    // delegate to services / adapters
    todo!()
}

#[cfg(test)]
mod tests {
    use super::*;
    // unit tests for the CLI-args → Request projection live here.
}
```

Rules:

- Handler is a **free function** named `run`, not a method.
- Signature: `pub fn run(ctx: &AppContext, args: <Verb>Args) -> Result<(), AppError>`.
- The first thing `run` does is project `args` into a domain `Request` — this is where "parse, don't validate" applies. After projection, downstream code never sees raw strings from clap.
- `run` is sync. If it needs async, use `ctx.runtime.block_on(async { … })`. **Do not** build a new tokio runtime per command.
- Direct I/O is forbidden. Call into `services::*` or `adapters::*`.
- Tests for the projection live inline in `mod tests`.

### 4. `src/main.rs` (dispatch arm)

```rust
match cli.command {
    Commands::Widget(args) => commands::widget::run(&ctx, args),
    // ... other arms
}
```

Explicit `match`, one arm per subcommand. No macros. The `match` is exhaustive — clippy will yell if you forget an arm.

## Parse-shape → runtime-shape, in Rust

See [General — parse-shape vs runtime-shape](../../../programming/cli-design/00-architecture.md#parse-shape-vs-runtime-shape). The Rust-specific mapping:

- `WidgetArgs` is constrained by clap derive limitations (`String`, `Option<String>`, `bool`).
- `Request` is constrained by the domain (newtypes, compiled `glob::Pattern`, validated enums).
- The projection lives in `Request::from_cli` and calls things like `WidgetId::from_str` and `glob::Pattern::new`.

## When to extract a service

See [General — When to extract a service](../../../programming/cli-design/00-architecture.md#when-to-extract-a-service). The triggers are language-agnostic; no Rust-specific overrides.

## Rust-specific anti-patterns

Add these to the general anti-patterns:

- **Runtime per command** — every `run` builds its own tokio runtime. See `riptask/src/main.rs:95-159`. Build one runtime in `main`, share via `AppContext`.
- **`Box<dyn Command>` registry** — feels clever, loses exhaustive-match safety on `Commands`, breaks clap-derived help. Use the plain enum.

## Variant: async handlers

If most commands are async, the cleanest pattern is to keep `run` sync but have it block on an async body:

```rust
pub fn run(ctx: &AppContext, args: WidgetArgs) -> Result<(), AppError> {
    ctx.runtime.block_on(async {
        let request = Request::from_cli(args)?;
        let report = execute(ctx, request).await?;
        ctx.ui.render_widget(&report);
        Ok(())
    })
}
```

The shared runtime on `AppContext` is built once with `tokio::runtime::Builder::new_current_thread().enable_all().build()`. Multi-thread runtime is only justified if the workload genuinely benefits — for most CLIs, current-thread is faster (no work-stealing overhead, smaller binary).
