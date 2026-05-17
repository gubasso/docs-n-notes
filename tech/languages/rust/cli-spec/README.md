# Rust CLI Architecture Spec

Canonical reference for every Rust CLI project. The source of truth for directory layout, module boundaries, error handling, logging, config, testing, dependencies, and coding style.

Use it as a template at project bootstrap and as a tie-breaker during code review.

## How to use

1. Start a new CLI from `templates/` (copy the files, rename the crate, prune unused modules).
2. When a design question comes up, search the chapter that owns it.
3. When the spec itself needs to change, add an ADR under `adr/` and edit the chapter.

## Index

| # | Chapter | One-line hook |
|---|---------|---------------|
| 0 | [Directory tree](00-directory-tree.md) | Canonical `src/` layout, with "what does NOT go here" per directory. |
| 1 | [Crate layout](01-crate-layout.md) | Single-crate vs workspace; when to add `lib.rs`. |
| 2 | [Subcommand pattern](02-subcommand-pattern.md) | The four-edit rule — one file per subcommand on both sides. |
| 3 | [Error handling](03-error-handling.md) | `thiserror` inside, `anyhow` only at the edge; BSD sysexits. |
| 4 | [Logging, config, testing](04-logging-config-testing.md) | `tracing` + figment + `assert_cmd`/`insta`. |
| 5 | [Dependencies](05-dependencies.md) | Curated default crate list with justification. |
| 6 | [Naming and visibility](06-naming-and-visibility.md) | `pub(crate)` by default; `foo.rs + foo/` over `mod.rs`. |
| 7 | [Coding style](07-coding-style.md) | Rust/Zig-flavored: explicit errors, newtypes, parse-don't-validate. |
| 8 | [Reference projects](08-reference-projects.md) | Layouts to study (ripgrep, fd, bat, jj, cargo, helix). |

## Templates

`templates/` holds the bootstrap skeleton:

```
templates/
├─ Cargo.toml.template
└─ src/
   ├─ main.rs.template
   ├─ cli/mod.rs.template
   ├─ commands/mod.rs.template
   ├─ error.rs.template
   └─ logging.rs.template
```

Copy the tree, drop the `.template` suffixes, rename `app_template` → your crate name.

## TL;DR

- Single crate by default; workspace only at ~8k LOC or when a real second consumer appears.
- `cli/` holds clap parsers (parse-shape). `commands/` holds handlers (runtime-shape). One file per subcommand on **both** sides.
- `domain/` is pure (no I/O, no async). `adapters/` is the only place that touches the outside world. `services/` is optional — add it only when orchestration is reused.
- Error stack: `thiserror` per-layer typed enums → top-level `AppError` → `exit_code()` mapped to BSD sysexits.
- `tracing` + `tracing-subscriber` with `RUST_LOG`. Don't invent app-specific log env vars.
- `figment` for layered config: defaults → user file → project file → env → CLI.
- Tests: `assert_cmd` + `predicates` + `insta` + `tempfile`. Run with `cargo nextest`.
- One `AppContext` built once in `main`, passed by `&AppContext`. Single shared tokio runtime.
- No `println!` outside `ui/`. No `panic!` outside `main`.

## Sources

External references the spec relies on:

- [Rust CLI Book](https://rust-cli.github.io/book/)
- [clap derive tutorial](https://docs.rs/clap/latest/clap/_derive/_tutorial/)
- [BurntSushi: Error handling in Rust](https://burntsushi.net/rust-error-handling/)
- [anyhow](https://docs.rs/anyhow/) · [thiserror](https://docs.rs/thiserror/)
- [tracing](https://docs.rs/tracing/) · [tracing-subscriber](https://docs.rs/tracing-subscriber/)
- [figment](https://docs.rs/figment/) · [directories](https://docs.rs/directories/)
- [Alexis King: Parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/)
- [Rust newtype pattern](https://rust-unofficial.github.io/patterns/patterns/behavioural/newtype.html)
- [assert_cmd](https://docs.rs/assert_cmd/) · [insta](https://insta.rs/docs/)
- [BSD sysexits(3)](https://man.freebsd.org/cgi/man.cgi?query=sysexits&sektion=3)
- [Rust API Guidelines: Naming](https://rust-lang.github.io/api-guidelines/naming.html)
- [Visibility & privacy](https://doc.rust-lang.org/reference/visibility-and-privacy.html)
- [Killercup: Elegant APIs in Rust](https://deterministic.space/elegant-apis-in-rust.html)
