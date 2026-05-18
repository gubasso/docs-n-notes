# 00 — Directory Tree (Rust)

> Prerequisite: [General principles — Architecture](../../../programming/cli-design/00-architecture.md) for the directory roles, parse-shape vs runtime-shape, and the `AppContext` pattern. This chapter is the Rust implementation.

The canonical layout. Every directory has a single responsibility and an explicit "does NOT belong here" line. If a file violates its directory's rule, move the file or fix the rule via an ADR — never let the rule rot silently.

## Canonical tree

```
crate/
├─ Cargo.toml                  # edition = "2024", single bin
├─ rust-toolchain.toml         # pinned channel (stable by default)
├─ justfile                    # check / lint / test / fmt tasks
├─ deny.toml                   # cargo-deny policy
├─ src/
│  ├─ main.rs                  # ≤120 LOC. parse → init logging → AppContext → dispatch → exit-code map.
│  ├─ lib.rs                   # OPTIONAL. Only when truly reusable. See chapter 01.
│  ├─ cli/                     # clap derive structs ONLY.
│  │  ├─ mod.rs                # root Cli + Commands enum + GlobalArgs
│  │  └─ <subcommand>.rs       # `#[derive(Args)] pub struct <Verb>Args`
│  ├─ commands/                # one handler per subcommand.
│  │  ├─ mod.rs
│  │  └─ <subcommand>.rs       # `pub fn run(ctx: &AppContext, args: <Verb>Args) -> Result<(), AppError>`
│  ├─ domain/                  # pure types + invariants + newtypes.
│  │  └─ <concept>.rs
│  ├─ services/                # OPTIONAL. Add only when orchestration is reused.
│  ├─ adapters/                # I/O at the edges.
│  │  └─ <external_system>.rs
│  ├─ config/                  # figment loader + layered merge.
│  ├─ context.rs               # AppContext struct.
│  ├─ error.rs                 # AppError enum + exit_code().
│  ├─ logging.rs               # tracing-subscriber init helper.
│  ├─ exit.rs                  # OPTIONAL. Move exit-code mapping here if error.rs grows.
│  ├─ ui/                      # human-facing terminal output ONLY.
│  └─ util/                    # truly generic helpers.
├─ tests/
│  ├─ cmd_<name>.rs            # one integration test per subcommand (assert_cmd)
│  ├─ fixtures/
│  ├─ snapshots/
│  └─ support/mod.rs           # shared test helpers
└─ benches/                    # criterion benches; only when needed
```

## Rules per directory

### `src/main.rs`

**Purpose**: the binary entry. Parses args, initializes logging, builds `AppContext`, dispatches to a `commands::*::run`, maps `AppError` to `ExitCode`.

**Does NOT belong here**: business logic, I/O calls, clap derive structs (they live in `cli/`), tokio runtime usage outside the one constructor that goes onto `AppContext`.

**Size budget**: ≤120 LOC. If it grows past that, lift code into `cli/`, `commands/`, or `logging.rs`.

### `src/lib.rs`

**Purpose** (optional): the public crate API when the logic is genuinely reusable by another crate or by integration tests that need internals.

**Does NOT belong here**: a no-op file that just declares private modules. If you're not exporting a real surface, delete `lib.rs` and keep modules `mod` inside `main.rs`.

### `src/cli/`

**Purpose**: clap derive structs only — the parse-shape of every flag, arg, and subcommand. `mod.rs` exposes the root `Cli`, the `Commands` enum, and any shared `GlobalArgs`.

**Does NOT belong here**: business logic, I/O, `tokio::main`, calls to `std::fs` / `reqwest` / `std::process`, error mapping beyond what clap demands.

**Rule**: each subcommand `<name>` has exactly one file `cli/<name>.rs` containing a single `pub struct <Verb>Args` deriving `clap::Args`.

### `src/commands/`

**Purpose**: subcommand handlers. Each `commands/<name>.rs` exposes a free function `pub fn run(ctx: &AppContext, args: <Verb>Args) -> Result<(), AppError>` that projects the CLI args into a service-layer call (or inlines simple orchestration), renders output via `ctx.ui`, and returns a typed error.

**Does NOT belong here**: clap derive structs, direct I/O (delegate to `adapters/`), shared orchestration reused across multiple commands (lift into `services/`).

### `src/domain/`

**Purpose**: pure types and invariants. Newtypes for IDs, paths, names; algebraic types for state machines. Constructors enforce invariants via `TryFrom`. Methods are pure functions of `&self` or `&mut self`.

**Does NOT belong here**: `std::io`, `tokio`, `reqwest`, `serde_*` *file* readers (a `#[derive(Serialize, Deserialize)]` on a domain struct is fine; calling `serde_json::from_reader` is not — that goes to `adapters/`).

### `src/services/` (optional)

**Purpose**: use-case orchestration shared by 2+ commands, or non-trivial pure cores that deserve unit tests in isolation. A service is a free function or a struct with a single public `execute` method; it takes adapter traits as parameters so it can be tested with fakes.

**Does NOT belong here**: anything used by only one command (inline it into `commands/<name>.rs`), direct I/O (call adapters), domain invariants (those live in `domain/`).

**Heuristic**: if you'd duplicate the logic across two `commands/*.rs` files, extract a service. If you wouldn't, don't pre-extract.

### `src/adapters/`

**Purpose**: the only place that talks to the outside world. One file per external system: `fs.rs`, `git.rs`, `http.rs`, `process.rs`, `clock.rs`, etc. Each defines a trait (`GitBackend`, `Clock`) and a default implementation. Services depend on the trait, not the impl.

**Does NOT belong here**: domain logic, command orchestration, terminal output (use `ui/`).

### `src/config/`

**Purpose**: layered config loading. Defines the `Config` struct and the figment chain that merges defaults → user file → project file → env → CLI.

**Does NOT belong here**: global mutable state, business defaults that belong in `domain/` (config holds *user-facing knobs*, not invariants).

### `src/context.rs`

**Purpose**: the `AppContext` struct, built once in `main` and passed by `&AppContext` everywhere. Holds resolved `Config`, computed paths, the shared `tokio::Runtime` handle, the `Ui` instance, and the tracing root span.

**Does NOT belong here**: methods that do real work — `AppContext` is a value object, not a god-class. Behavior goes to `commands/`, `services/`, or adapters.

### `src/error.rs`

**Purpose**: the crate-level `AppError` enum (thiserror) plus `impl AppError { pub fn exit_code(&self) -> u8 }` mapped to BSD sysexits. Aggregates errors via `#[from]` from each layer.

**Does NOT belong here**: `anyhow::Result` type aliases for downstream layers (let them import `anyhow` directly when they need it).

### `src/logging.rs`

**Purpose**: the `pub fn init(verbosity: u8) -> anyhow::Result<()>` helper that installs `tracing-subscriber` with `EnvFilter`.

**Does NOT belong here**: emission. Only the install.

### `src/ui/`

**Purpose**: every byte of human-facing output. Renderers, progress bars, color, prompts. A single `Ui` struct exposes methods like `render_widget`, `confirm`, `progress`.

**Does NOT belong here**: structured diagnostics (those go through `tracing`). No `println!` allowed anywhere else in the crate.

### `src/util/`

**Purpose**: truly generic helpers (≤ 200 LOC per file). Things that could live in any project: `os_str` conversion shims, formatting utilities, etc.

**Does NOT belong here**: anything that mentions a domain noun. If it does, it belongs in `domain/` or `services/`.

### `tests/`

**Purpose**: process-level integration tests. One `tests/cmd_<name>.rs` per subcommand using `assert_cmd::Command::cargo_bin("<bin>")`. Shared helpers under `tests/support/`. Snapshots under `tests/snapshots/`.

**Does NOT belong here**: pure unit tests (those go inline under `#[cfg(test)] mod tests` in their owning module).

### `benches/`

**Purpose**: criterion benchmarks. Only add files you'll actually maintain.

**Does NOT belong here**: throwaway timing scripts (use `examples/` if you need them).

## Optional extras

Add when you actually need them — not preemptively:

- `examples/` — small runnable examples that double as docs.
- `xtask/` — workspace-internal CLI for build tasks (release prep, docs gen). Only at workspace scale.
- `docs/adr/` — Architecture Decision Records for spec deviations.

## Reading order for new contributors

1. `Cargo.toml` — see the dependency footprint.
2. `src/main.rs` — see the dispatch surface.
3. `src/cli/mod.rs` — see the user-facing command set.
4. Pick one `commands/<name>.rs` — trace it down through `services/` → `adapters/`.
5. `src/error.rs` — understand the failure model.
