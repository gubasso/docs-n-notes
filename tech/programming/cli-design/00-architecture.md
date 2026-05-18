# 00 — Architecture

The shape every CLI should default to. Define the directory roles, split parse-shape from runtime-shape, build one `AppContext` and pass it by reference, and stay single-crate until you have a concrete reason not to.

## Vocabulary

The other chapters use these terms. Read them here once.

| Term | Meaning |
|------|---------|
| **parse-shape** | The argument struct the CLI parser produces. Strings, `Option<String>`, booleans. Constrained by what's ergonomic on the command line. |
| **runtime-shape** | The domain struct the handler uses after parsing. Newtypes, parsed enums, validated paths. Cannot represent invalid states. |
| **AppContext** | The single value built once in `main` and threaded by reference. Holds resolved config, paths, runtime handle, UI, and the root tracing span. |
| **command** | A subcommand handler — one `run(&AppContext, <Verb>Args) -> Result<(), AppError>` per subcommand. |
| **service** | Use-case orchestration shared by ≥2 commands. Optional. |
| **adapter** | The only place that talks to the outside world. One per external system. |
| **domain** | Pure types + invariants. No I/O. |

## Directory roles

```
src/
├─ main.rs                 entry: parse → init logging → AppContext → dispatch → exit-code
├─ cli/                    parse-shape (CLI parser structs)
│  └─ <subcommand>.rs        one file per subcommand
├─ commands/               runtime-shape handlers
│  └─ <subcommand>.rs        one file per subcommand
├─ domain/                 pure types + invariants (newtypes, state machines)
├─ adapters/               I/O at the edges (one file per external system)
├─ services/               orchestration reused across commands (optional)
├─ config/                 layered config loader
├─ context.rs              AppContext struct
├─ error.rs                top-level error + exit-code mapping
├─ logging.rs              logging-subsystem init helper
├─ ui/                     human-facing output (the only place that writes to stdout)
└─ util/                   truly generic helpers (≤200 LOC per file)

tests/
├─ cmd_<name>.rs           one integration test file per subcommand
├─ fixtures/
├─ snapshots/
└─ support/                shared helpers (env-clear, tempdir setup)
```

Every directory has a **single responsibility** and an explicit **"does NOT belong here"** rule. If a file violates that rule, move the file or fix the rule — don't let it rot. The language-specific specs (`tech/languages/<lang>/cli-spec/00-directory-tree.md`) translate this skeleton to concrete file names and module syntax.

This tree maps onto **clean-architecture / hexagonal** layers — useful when discussing the design with people who think in those terms:

- **Domain** → `domain/`
- **Application** → `commands/` + `services/`
- **Infrastructure** → `adapters/` + `config/` + `context.rs`
- **Presentation** → `cli/` + `ui/`

The directory names stay as above; the layer names are just vocabulary.

### `main`

**Owns**: parse args, init logging, build `AppContext`, dispatch to a command, map errors to exit codes.

**Does NOT own**: business logic, I/O, parser definitions, runtime construction beyond the one instance handed to `AppContext`.

**Size**: keep it ≤ 120 LOC. When it grows, lift code into `cli/`, `commands/`, or `logging.rs`.

### `cli/`

**Owns**: CLI parser definitions — the parse-shape of every flag, arg, and subcommand.

**Does NOT own**: business logic, I/O, error mapping beyond what the parser requires.

**Rule**: one file per subcommand. The root file (mod entry) exposes the top-level parser, the subcommand enum, and any shared global args.

### `commands/`

**Owns**: handlers. Each file exposes a free function `run(&AppContext, <Verb>Args) -> Result<(), AppError>` that projects parse-shape into runtime-shape, calls services / adapters, renders output, and returns a typed error.

**Does NOT own**: parser definitions (those are in `cli/`), direct I/O (delegate to `adapters/`), orchestration shared across commands (lift into `services/`).

### `domain/`

**Owns**: pure types and invariants. Newtypes for IDs, paths, names; algebraic types for state machines. Constructors enforce invariants via `TryFrom` / `from_str`.

**Does NOT own**: any I/O. A `#[derive(Serialize, Deserialize)]` on a domain struct is fine; calling a file/JSON reader is not — that goes to `adapters/`.

### `services/` (optional)

**Owns**: use-case orchestration shared by ≥2 commands, or non-trivial pure cores you want to unit-test in isolation.

**Does NOT own**: anything used by only one command (inline it), direct I/O (call adapters), domain invariants (those live in `domain/`).

**Heuristic**: if you'd duplicate the logic across two `commands/*.rs` files, extract a service. Otherwise, don't pre-extract.

### `adapters/`

**Owns**: every conversation with the outside world. One file per external system (`fs`, `git`, `http`, `process`, `clock`, …). Each defines a trait + a default implementation.

**Does NOT own**: domain logic, command orchestration, terminal output.

**Errors**: each adapter defines its own error type (e.g. `GitError`, `HttpError`). The top-level `AppError` aggregates them at the boundary. Mechanism is language-specific (Rust: `#[from]`; Python: exception hierarchy; Bash: namespaced exit codes) — see [02 — Error Messages](02-error-messages.md).

### `config/`

**Owns**: layered config loading. Defines the resolved `Config` struct and the merge chain. See [03 — Config Precedence](03-config-precedence.md).

**Does NOT own**: global mutable state, business invariants (those live in `domain/`).

### `context.rs`

**Owns**: the `AppContext` struct, built once in `main` and passed by reference everywhere. Holds `Config`, paths, the UI handle, the async-runtime handle (if any), the tracing root span, and an interface to clocks/randomness.

**Does NOT own**: methods that do real work. `AppContext` is a value object, not a god-class. Behavior goes to `commands/`, `services/`, or `adapters/`.

**`Paths`**: resolves the three XDG directories once, kept distinct so the wrong byte never lands in the wrong place:

- `config_home` (`$XDG_CONFIG_HOME`) — user-editable settings, loaded by `config/`.
- `state_home` (`$XDG_STATE_HOME`) — app-written persistent state (logs, sessions, history). Accessed via `adapters/`.
- `cache_home` (`$XDG_CACHE_HOME`) — ephemeral, safe to delete. Accessed via `adapters/`.

Resolve once here, never recompute. Language-specific defaults live in each `cli-spec/`.

### `error.rs`

**Owns**: the top-level `AppError` enum and its `exit_code()` mapping. See [02 — Error Messages](02-error-messages.md).

### `logging.rs`

**Owns**: the install helper for the logging subsystem. See [01 — Logging & Output](01-logging-and-output.md).

**Does NOT own**: log emission. Only the install.

### `ui/`

**Owns**: every byte of human-facing output. Renderers, color, progress bars, prompts.

**Does NOT own**: structured diagnostics — those go through the program-log layer.

**Rule**: no print statement is allowed *anywhere else* in the codebase. Treat it as a CI lint.

### `util/`

**Owns**: truly generic helpers, ≤ 200 LOC per file.

**Does NOT own**: anything that mentions a domain noun. If it does, it belongs in `domain/` or `services/`.

### `tests/`

**Owns**: process-level integration tests. One file per subcommand. Shared helpers under `support/`. Snapshots under `snapshots/`.

**Does NOT own**: pure unit tests — those colocate inside each module.

---

## Parse-shape vs runtime-shape

The argument struct the parser produces (parse-shape) and the request the handler consumes (runtime-shape) are **two different types**.

```
+-------------------+     +-----------------+     +---------------+
|  CLI text input   | --> |   parse-shape   | --> |  runtime-shape|
| (argv, env, file) |     |  (WidgetArgs)   |     |   (Request)   |
+-------------------+     +-----------------+     +---------------+
                              ^                          ^
                              |                          |
                          parser-friendly:           domain-friendly:
                          strings, bools,            newtypes, parsed
                          Option<String>             enums, validated paths
```

The projection from parse-shape → runtime-shape happens once, at the top of each handler. This is where you parse strings into newtypes, compile patterns, validate enums, and reject illegal flag combinations.

After projection, downstream code **cannot represent an invalid state**. This is the "parse, don't validate" principle made concrete (see [04 — Coding Style](04-coding-style-rust-zig.md), rule 2).

---

## The four-edit rule for subcommands

Adding a new subcommand `widget` touches exactly four files:

1. `cli/widget.rs` — parse-shape struct.
2. `cli/<root>` — register the variant in the subcommand enum.
3. `commands/widget.rs` — handler (free `run` function).
4. `main.rs` (or the dispatch arm) — dispatch.

No registry macros, no auto-discovery, no plugin trait. Explicit dispatch over magic. The compiler tells you when you forgot an arm.

**Anti-patterns** this rule prevents:

- Giant single `cli.rs` holding every parser struct. Makes diffs unreadable.
- Handler as a method on the args struct (`impl WidgetArgs { fn run(...) }`). Couples parse-shape to runtime, prevents the pure projection step.
- Per-command async-runtime construction. Build one runtime in `main`, share via `AppContext`.
- `Box<dyn Command>` registry. Loses exhaustive-match safety, adds nothing.

### When to extract a service

The default is: keep the work inline in `commands/widget.rs`. Extract `services/widget` only when **at least one** is true:

1. Another command needs the same orchestration.
2. The pure core is non-trivial and you want to unit-test it without the parser.
3. The handler exceeds ~200 LOC.

Otherwise, inline. Premature service extraction creates passthrough wrappers that obscure the call graph.

---

## Cross-cutting concerns (middleware, telemetry, hooks)

Pre/post-command interception, telemetry wrappers, retry/recovery decorators — these cut across multiple commands. Place them by volume:

- **One or two hooks**: wrap the dispatch arm in `main.rs`. No new directory.
- **A reusable family** (telemetry, audit, rate limiting): define a `Middleware` trait in `adapters/`, with one impl per concern. Compose the chain in `context.rs` or at dispatch.
- **A dedicated `middleware/` directory**: only when the chain exceeds ~300 LOC or three independent concerns. Until then, `adapters/` is the right home — middleware is an infrastructure concern.

Do **not** decorate handlers inside `commands/`. That scatters cross-cutting policy across every subcommand and breaks the four-edit rule.

---

## One `AppContext`, built once

```
main()
  parse_cli() -> Cli
  init_logging(cli.verbosity)
  ctx = AppContext::new(cli.global)   <-- builds once
  dispatch(&ctx, cli.command)         <-- pass by reference
```

The context carries:

- `config: Arc<Config>` — resolved config (see [03](03-config-precedence.md)).
- `paths: Paths` — computed (data dir, state dir, cache dir).
- `ui: Ui` — the only renderer.
- `runtime: Handle` — shared async runtime, if any.
- `clock: Arc<dyn Clock>` — abstracts time for tests.
- (optionally) `tracing_root: tracing::Span`.

**No globals.** No process-wide `static`, no thread-locals, no implicit context. Commands take an explicit `&AppContext`; tests construct one with fakes (`MockClock`, `InMemoryUi`).

---

## Crate organization: single → workspace

Start **single-crate, single-binary**. This is what `fd`, `gitui`, `ouch`, and `starship` do. Faster compiles, zero workspace ceremony, lowest-friction shape for the first months of a project.

Migrate to a workspace only when **one** of these triggers fires (do not migrate proactively):

1. **Second binary sharing ≥30% of code.** A daemon, a helper, a TUI variant. Split into `app-core` (library) + `app-cli` (binary) + new consumer.
2. **A subsystem is publishable on its own.** `ripgrep` extracted `grep-matcher`, `grep-regex`, `grep-searcher`, `grep-printer` because each is reusable. If it has zero app-specific concerns, it earns its own crate.
3. **Compile time exceeds tolerance.** Incremental `check` over ~10 s and the slow code is structurally separable.
4. **Plugins/adapters need independent dep trees.** Helix splits `helix-lsp` so the LSP client's deps don't bloat the core.

**Hard threshold**: at ~8k LOC of application code, take a serious look. Below that, the cost of workspace navigation outweighs the wins.

### Workspace shapes when you do migrate

- **Core lib + thin bin** (the `bat` pattern): `crates/app-core/` (library) + `crates/app-cli/` (the binary, depends on core).
- **Domain crates + glue** (the `ripgrep` pattern): `app-domain/`, `app-adapter-<system>/`, `app-service/`, `app-cli/`. Use when subsystems are publishable.

See [09 — Reference Projects](09-reference-projects.md) for organizational patterns from well-studied codebases.

### Directory rules across a workspace

The single-crate rules above still hold per-crate. Specifically:

- **Four-edit rule** stays scoped to whichever crate owns the binary; you still touch four files, just within that one crate.
- **`domain/` and `adapters/`** extract into `app-core` (or per-subsystem crates). `cli/` and `commands/` stay in the binary crate.
- **No cross-crate `cli/` imports.** Each binary owns its own parse-shape. Crates communicate via runtime-shape request types defined in `domain/`.
- **One `AppContext` per binary.** Don't share the struct across binaries — each may need different fields. If construction logic is shared, factor it as a builder in `app-core`.

---

## When to add a library file (`lib.rs` / `__init__.py` API)

Only when one of these is true:

1. Another consumer (a second crate, a Tauri app, a sibling binary) needs the same logic.
2. Integration tests need access to internals that aren't reachable from a binary-only crate.

A no-op library file that just declares private modules is dead weight. If you don't have a real consumer, **don't** create the public surface — keep modules internal.

---

## See also

- [04 — Coding Style](04-coding-style-rust-zig.md) — explicit errors, parse-don't-validate, composition, no globals.
- [07 — Naming & Documentation](07-naming-and-docs.md) — verb/noun discipline, module headers ("what it is, what it isn't").
- [08 — Testing Strategy](08-testing-strategy.md) — what tests live where in the tree.
- Language-specific spec: [`rust/cli-spec/00-directory-tree.md`](../../languages/rust/cli-spec/00-directory-tree.md).
