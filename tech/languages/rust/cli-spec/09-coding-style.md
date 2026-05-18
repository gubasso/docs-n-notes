# 09 — Coding Style (Rust)

> Prerequisite: [General principles — Coding Style (Rust/Zig Flavor)](../../../programming/cli-design/04-coding-style-rust-zig.md) for the universal rules (parse-don't-validate, newtypes, composition over inheritance, comment why not what). This chapter is the Rust implementation with idiomatic Rust syntax.

Rust/Zig flavor: explicit errors, no hidden control flow, parse don't validate, newtypes everywhere, composition over inheritance, small focused modules. The point of these rules is to make the cost of any line of code visible at the call site.

## 1. Explicit errors

Every fallible operation returns `Result`. No `panic!` outside `main`, tests, build scripts, and `LazyLock` initializers. No `.unwrap()` or `.expect()` outside the same exceptions.

```rust
// no
let widget = registry.get(&id).unwrap();

// yes
let widget = registry.get(&id)
    .ok_or_else(|| AppError::Usage(format!("unknown widget: {id}")))?;
```

The carat: `.expect("invariant: ...")` is acceptable when documenting a true invariant that the type system can't express, but treat each one as a smell to revisit.

## 2. Parse, don't validate

At every boundary (CLI, file, network), parse strings into precise types **once**. After parsing, downstream code can't represent invalid state.

```rust
// at the boundary (cli or adapter)
fn parse_widget_id(raw: &str) -> Result<WidgetId, DomainError> {
    WidgetId::try_from(raw)
}

// downstream — accepts only the parsed type
fn execute(req: Request) -> Result<Report, ServiceError> {
    // req.id is already a WidgetId; no need to revalidate
}
```

This is the antidote to "validation scattered across layers". See [Alexis King's essay](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) for the canonical writeup.

## 3. Newtypes for domain primitives

Wrap every domain-meaningful primitive in a newtype with a private constructor and `TryFrom<&str>` (or `TryFrom<u32>`, etc.) that enforces invariants:

```rust
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct WidgetId(String);

impl WidgetId {
    pub fn as_str(&self) -> &str { &self.0 }
}

impl std::str::FromStr for WidgetId {
    type Err = DomainError;
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        if !(1..=64).contains(&s.len()) {
            return Err(DomainError::IdLength { len: s.len() });
        }
        if let Some(c) = s.chars().find(|c| !c.is_ascii_alphanumeric() && *c != '-') {
            return Err(DomainError::IdInvalidChar(c));
        }
        Ok(Self(s.to_owned()))
    }
}
```

Newtypes are zero-cost at runtime. They cost a few lines of code in exchange for making one whole class of bugs unrepresentable.

Apply to: IDs, names, paths (`AbsoluteUtf8Path` over `PathBuf`), URLs, branch names, project keys, timeouts, byte sizes — anything where the unit or constraint matters.

## 4. Composition over inheritance

There is no inheritance. Use small focused traits and compose them.

```rust
pub trait GitBackend {
    fn rev_parse(&self, refname: &str) -> Result<CommitSha, GitError>;
    fn current_branch(&self) -> Result<BranchName, GitError>;
}

pub struct RealGitBackend { /* ... */ }
impl GitBackend for RealGitBackend { /* ... */ }

#[cfg(test)]
pub struct MockGitBackend { /* ... */ }
#[cfg(test)]
impl GitBackend for MockGitBackend { /* ... */ }
```

Use `dyn Trait` (trait objects) only when **both** are true:

- The trait set is genuinely heterogeneous at runtime.
- The perf cost (virtual call, allocation) is negligible.

CLI command dispatch is the canonical place where `Box<dyn Adapter>` is fine. Tight inner loops are where it isn't.

For most services, prefer generics:

```rust
pub fn sync<G: GitBackend, H: HttpClient>(git: &G, http: &H) -> Result<Report, _> { ... }
```

Monomorphization beats vtable dispatch in hot paths and lets the compiler inline.

## 5. Free functions > methods (when no state is needed)

A method on a struct exists because the struct owns invariants the method preserves. If the function is a pure transform of its arguments, make it a free function in the same module.

```rust
// yes — pure transform, no invariant on Self
pub fn render_report(report: &Report, format: Format) -> String { ... }

// no — Renderer holds nothing; the struct adds noise
impl Renderer {
    pub fn render(&self, report: &Report, format: Format) -> String { ... }
}
```

Method when the receiver carries state (`self.connection.query(...)`). Free function otherwise.

## 6. Borrow > own in arguments

Take the least-owning type that does the job. Return owned types when the caller will keep them.

| Pattern | Take | Return |
|---------|------|--------|
| String input you only read | `&str` | — |
| Path input you only read | `&Path` or `&Utf8Path` | — |
| Slice you only read | `&[T]` | — |
| Optional context | `Option<&T>` | — |
| You'll consume / store the value | `T` (owned) | — |
| Returning a new value | — | `T` (owned) |
| Maybe borrow / maybe own | `Cow<'_, str>` | Only when profiling justifies it. |

Anti-pattern: `fn foo(s: String) -> ...` when you only call `s.as_str()`. Take `&str` and let the caller decide.

## 7. `Result` > `Option` for failures

- `Option<T>` means *absent by design*. "There may or may not be a value, and that's a normal state."
- `Result<T, E>` means *could fail*. "Something tried and didn't succeed; here's why."

```rust
// search that may legitimately miss
fn lookup(name: &str) -> Option<Widget>     { ... }

// open a file
fn read(path: &Path) -> Result<String, std::io::Error> { ... }
```

`Option<Option<T>>` and `Result<Option<T>, E>` are both fine when the semantics distinguish "fallible search that returned no hit" from "fallible search that errored".

## 8. Small focused modules

Hard cap: **~400 LOC per file.** When you cross it, split.

- A 1500-line `cli.rs` (`riptask/src/cli.rs`) is a refactor target, not a steady state.
- One file per subcommand. One file per adapter. One file per domain concept.
- A file that's 30 lines for a single type is fine. Two unrelated types in one file is not.

The cap is a forcing function for module boundaries. Hitting it usually means an extraction is overdue.

## 9. One `AppContext`, built once in `main`

The dispatch surface for every command:

```rust
pub struct AppContext {
    pub config:  Arc<Config>,
    pub paths:   Paths,
    pub ui:      Ui,
    pub runtime: tokio::runtime::Handle,
    pub clock:   Arc<dyn Clock>,
}
```

Built in `main`, passed by `&AppContext`. Commands read what they need from it. No global `static`, no `lazy_static`, no thread-local mutable state.

Why: testability. Commands take an explicit context; tests construct one with fakes (`MockClock`, `InMemoryUi`).

## 10. Trait objects only when justified

Banned: `Box<dyn Error>` as a return type. Use the typed `AppError`.

Acceptable: `Arc<dyn Clock>` on `AppContext` so tests can swap in a `MockClock`. Acceptable: `Box<dyn Iterator<Item = T>>` to erase a complex iterator chain at an API boundary.

Default to generics; reach for `dyn` only when monomorphization explodes binary size or when heterogeneity is genuinely runtime-determined.

## 11. No `#![allow(dead_code)]` at crate root

Scope `allow` attributes to the smallest possible target — the item, not the crate:

```rust
// yes
#[allow(dead_code)]
fn intentionally_unused_during_bootstrap() { ... }

// no — at crate root
#![allow(dead_code)]
```

If a whole module is "WIP, ignore warnings", say so:

```rust
// src/foo/mod.rs
#![allow(dead_code)] // WIP: see ADR-0007
```

…and then remove it before shipping.

## 12. Comment "why", not "what"

The code says what. Comments say why.

```rust
// no
// Increment counter by 1.
counter += 1;

// yes — non-obvious invariant
// Counter resets to 0 on rollover (24h); see ADR-0014.
counter += 1;
```

Link to ADRs, issues, or specs by stable identifier. Don't reference variables by name in comments — renames will rot the comment.

## 13. No `println!` outside `ui/`

All human-facing output goes through `ctx.ui.<method>`. All diagnostic output goes through `tracing::{info, warn, error}!`. A `println!` anywhere else is a bug.

This rule has teeth: it's grep-able. Add it as a CI lint:

```bash
! rg --type rust 'println!|eprintln!' src/ --glob '!src/ui/**' --glob '!src/main.rs'
```

(Allowing `main.rs` to print at most the final error.)

## 14. Prefer iterators and combinators

Loops are fine. But if a sequence of `map` / `filter` / `collect` reads more clearly than a manual loop, prefer it.

```rust
// fine
let names: Vec<_> = widgets.iter()
    .filter(|w| w.is_active())
    .map(|w| w.name().to_owned())
    .collect();
```

Don't force iterators when a `for` loop is clearer. Don't chain ten combinators across ten lines; break the pipeline at a meaningful intermediate value.

## 15. Async only when justified

If the work is CPU-bound or fits in a single thread, stay sync. Async exists for I/O concurrency, not as a default.

For the spec's default `tokio` features (`rt`, `macros`):

- `rt` — current-thread runtime; no work-stealing.
- `macros` — `#[tokio::main]`, `tokio::select!`, etc.

Add `rt-multi-thread` only when measurement justifies it.

## 16. Closures over `Fn` traits at API boundaries

For internal callbacks, take `impl Fn(...)` / `impl FnMut(...)` / `impl FnOnce(...)` — the compiler monomorphizes and inlines. Use `Box<dyn Fn(...)>` only when the closure must be stored heterogeneously.

## 17. Const what can be const

Use `const` for true compile-time constants. Use `static` for shared runtime values. Use `LazyLock` for runtime-initialized constants. In that order of preference.

## 18. Cargo / lints

`Cargo.toml`:

```toml
[lints.rust]
unused_must_use = "deny"
unsafe_code     = "forbid"  # remove "forbid" if you genuinely need unsafe

[lints.clippy]
pedantic     = { level = "warn", priority = -1 }
nursery      = { level = "warn", priority = -1 }
unwrap_used  = "warn"
expect_used  = "warn"
```

Adopt clippy lints aggressively; silence individual lints inline with a justifying comment, not globally.

## 19. Module headers

Every file opens with a `//!` block:

```rust
//! `widget` subcommand: parse-shape.
//!
//! Holds clap derive structs only. No I/O, no business logic.
```

Two sentences: what it is, what it isn't. The "isn't" sentence prevents drift.

## 20. The reading order

When in doubt about whether a change belongs here, ask in this order:

1. **Does this touch the outside world?** → `adapters/`.
2. **Is it pure orchestration shared across commands?** → `services/`.
3. **Does it enforce an invariant on a value?** → `domain/`.
4. **Is it specific to one subcommand?** → `commands/<name>.rs`.
5. **Is it CLI parsing?** → `cli/<name>.rs`.
6. **Is it cross-cutting setup?** → `main.rs`, `context.rs`, `logging.rs`, `config/`.
7. **None of the above?** → likely doesn't belong in the crate yet.
