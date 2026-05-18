# 02 — Subcommand Pattern (Rust)

> Prerequisite: [General principles — Architecture](../../../programming/cli-design/00-architecture.md) (the four-edit rule, parse-shape vs runtime-shape, when to extract a service). This chapter is the Rust implementation using `clap`.

The four-edit rule: adding a new subcommand `widget` touches exactly four files. No more, no less. This keeps the surface predictable, makes code review cheap, and prevents the giant-`cli.rs` antipattern (`riptask/src/cli.rs:1-1558`).

## The four files

1. **`src/cli/widget.rs`** — parse-shape (clap struct).
2. **`src/cli/mod.rs`** — register the variant in the `Commands` enum.
3. **`src/commands/widget.rs`** — handler (free `run` function).
4. **`src/main.rs`** — dispatch arm.

That's it. No registry macro, no auto-discovery, no plugin trait. Explicit dispatch over magic.

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

## Why split parse-shape from runtime-shape

The clap struct (`WidgetArgs`) and the domain request (`Request`) **must not be the same type**. They evolve independently:

- `WidgetArgs` is constrained by clap's derive limitations and what's ergonomic on the command line (strings, `Option<String>`, `bool` flags).
- `Request` is constrained by the domain (newtypes, parsed glob patterns, validated enums).

Projecting `WidgetArgs` → `Request` is where you parse strings into newtypes (`WidgetId::from_str`), compile glob patterns, and reject illegal combinations. Once you have a `Request`, downstream code cannot represent an invalid state. This is the "parse, don't validate" principle made concrete.

## When to extract into `services/`

The default is: keep `execute` inside `commands/widget.rs`. Extract a `services::widget` module only when **at least one** of these is true:

1. Another command needs the same orchestration.
2. The pure core of the logic is non-trivial and you want to unit-test it without clap.
3. The handler exceeds ~200 LOC.

Otherwise, inline. Premature service extraction creates trivial passthroughs that obscure the call graph.

## Anti-patterns to avoid

- **Giant single `cli.rs`** holding every clap struct. Makes diffs unreadable, makes `cargo check` slow, makes ownership of a subcommand ambiguous. See `riptask/src/cli.rs:1-1558`.
- **Handler as a method on the args struct** (`impl WidgetArgs { fn run(&self, ctx: &AppContext) }`). Couples parse-shape to runtime, prevents pure projection.
- **Runtime per command** — every `run` builds its own tokio runtime. See `riptask/src/main.rs:95-159`. Build one runtime in `main`, share via `AppContext`.
- **`Cmd`/`run` traits with dynamic dispatch.** A `Box<dyn Command>` registry feels clever but loses the exhaustive-match safety net and adds nothing over a plain enum.

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
