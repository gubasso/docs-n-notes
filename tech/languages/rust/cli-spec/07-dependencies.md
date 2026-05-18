# 07 — Dependencies (Rust)

> Prerequisite: the cli-design chapters reference the crates listed here. See [`tech/programming/cli-design/`](../../../programming/cli-design/) for the language-agnostic principles. This chapter is the curated crate list for Rust CLIs.

Opinionated default dependency list. Each entry has a one-line justification and a "skip if" condition. Pick deliberately; resist the urge to add "useful-looking" crates without a concrete need.

## Runtime defaults

| Crate | Features | Why | Skip if |
|-------|----------|-----|---------|
| `clap` | `derive`, `env`, `wrap_help` | Standard parser; `env` lets flags fall back to env vars; `wrap_help` makes `--help` readable. | Never. |
| `clap_complete` | — | Generates shell completions via a subcommand. | The CLI is dev-internal and shell completions aren't needed. |
| `anyhow` | — | Ad-hoc context-rich errors at the binary edge. | You're writing a pure library (use only `thiserror`). |
| `thiserror` | — | Typed error enums in `domain/`, `adapters/`, `services/`, `error.rs`. | Never. |
| `tracing` | — | Structured logging primitive. Emitted everywhere. | Never. |
| `tracing-subscriber` | `env-filter`, `fmt` | Installs the subscriber in `main`. | Never (in a binary). |
| `tracing-appender` | — | Non-blocking file sink. | The CLI only ever runs interactively and stderr is enough. |
| `serde` | `derive` | Universal serialization. | Never. |
| `serde_json` | — | JSON I/O. | No JSON I/O anywhere. |
| `toml` | — | Config file parsing (via figment). | No config files. |
| `figment` | `env`, `toml` | Layered config with source provenance. | Trivial single-file config (use `toml` + `serde` directly). |
| `directories` | — | XDG/Windows/macOS config-path resolution. | No cross-platform config paths needed. |
| `camino` | `serde1` | UTF-8-only paths; kills `Path::to_string_lossy()` boilerplate. | The CLI only operates on user-supplied paths it never round-trips through strings. |
| `tokio` | `rt`, `macros` | Single current-thread runtime for async. | Fully sync CLI. |

## Dev-dependencies

| Crate | Features | Why | Skip if |
|-------|----------|-----|---------|
| `assert_cmd` | — | Process-level CLI tests. | No integration tests (you should have them). |
| `predicates` | — | Assertion helpers for `assert_cmd`. | Same. |
| `insta` | `yaml` | Snapshot tests for structured output. | No structured output to snapshot. |
| `tempfile` | — | Isolated temp dirs per test. | Same. |
| `trybuild` | — | Compile-fail tests for typestate APIs. | No typestate. |

## Conditional adds

Add only when a specific concrete need arises.

| Crate | When |
|-------|------|
| `color-eyre` | Pretty `anyhow`-style error chains in dev builds. Gate behind a `dev` feature; skip in release for binary size. |
| `chrono` or `time` | Real date/time handling. Prefer `time` (smaller, no globally-mutable timezone state). Use `chrono` only if dep tree already pulls it. |
| `glob` | Glob pattern matching (e.g. `*.txt`). |
| `regex` | Regular expressions. Heavyweight; consider whether `str::contains` suffices first. |
| `reqwest` | HTTP client. Use `rustls` backend, not `native-tls`, to keep static builds working. |
| `rusqlite` or `sqlx` | SQL persistence. Pick `sqlx` only if you need async or compile-time query checking. |
| `crossterm` | TUI input handling. Reach for it only if you need raw mode. |
| `indicatif` | Progress bars. |
| `dialoguer` | Interactive prompts. |
| `dirs` | Old XDG helper. **Don't use**; `directories` supersedes it. |
| `walkdir` | Filesystem traversal with depth/symlink controls. |
| `ignore` | `.gitignore`-aware traversal. Bigger than `walkdir`; use only if you actually need gitignore semantics. |
| `which` | Locate executables on PATH. |
| `tempfile` (runtime, not dev) | If your CLI creates real tempfiles (not just tests). |
| `parking_lot` | Faster mutex/rwlock than std. Only if profiling shows lock contention. |
| `rayon` | Data parallelism. Use only when the workload is genuinely parallelizable and the CLI isn't I/O-bound. |
| `once_cell` / `std::sync::LazyLock` | Prefer std `LazyLock` (1.80+) over `once_cell::sync::Lazy` for new code. |

## Avoid by default

Deprecated, dead, or superseded:

| Crate | Why avoid | Use instead |
|-------|-----------|-------------|
| `env_logger` | Old; doesn't integrate with spans. | `tracing-subscriber`. |
| `log` (directly) | Lacks structured fields and spans. | `tracing`. |
| `structopt` | Merged into clap; deprecated. | `clap` derive. |
| `failure` | Unmaintained. | `thiserror` + `anyhow`. |
| `error-chain` | Unmaintained. | Same. |
| `confy` | Can't layer multiple files. | `figment`. |
| `dirs` | Maintenance moved to `directories`. | `directories`. |
| `chrono` (if you have a choice) | Global timezone state, larger surface. | `time`. |
| `lazy_static` | Older, macro-based. | `std::sync::LazyLock`. |
| `rustc-serialize` | Pre-`serde`. | `serde`. |
| `serde_yaml` | Unmaintained. | `serde_yaml_ng` or skip YAML. |

## Cargo.toml skeleton

```toml
[package]
name        = "app-template"
version     = "0.1.0"
edition     = "2024"
rust-version = "1.85"
license     = "MIT OR Apache-2.0"
description = "One-line description."
repository  = "https://github.com/you/app-template"

[[bin]]
name = "app"
path = "src/main.rs"

[dependencies]
clap                = { version = "4", features = ["derive", "env", "wrap_help"] }
clap_complete       = "4"
anyhow              = "1"
thiserror           = "1"
tracing             = "0.1"
tracing-subscriber  = { version = "0.3", features = ["env-filter", "fmt"] }
serde               = { version = "1", features = ["derive"] }
serde_json          = "1"
toml                = "0.8"
figment             = { version = "0.10", features = ["env", "toml"] }
directories         = "5"
camino              = { version = "1", features = ["serde1"] }
tokio               = { version = "1", features = ["rt", "macros"] }

[dev-dependencies]
assert_cmd  = "2"
predicates  = "3"
insta       = { version = "1", features = ["yaml"] }
tempfile    = "3"

[profile.release]
lto           = "thin"
codegen-units = 1
strip         = "symbols"
```

Trim aggressively for very small CLIs (drop `tokio`, `figment`, `directories` if you don't need them). Add to taste from the conditional list above.

## Pinning policy

- Pin to **major versions** in `Cargo.toml` (`"4"`, `"0.3"`). Let `Cargo.lock` pin exact versions.
- Commit `Cargo.lock` for binaries. Don't for libraries.
- Run `cargo update` deliberately, not as a default `just` task. Read the changelog.
- Use `cargo deny` (configured in `deny.toml`) to enforce a license allowlist and ban yanked or vulnerable versions.

## Justification: figment over config-rs

Both work. Pick figment because:

- It tracks per-key source provenance. Errors say *"`timeout` in `./app.toml` (line 12) was negative"* instead of *"invalid config"*.
- Its provider model maps cleanly onto our layered precedence (defaults → user → project → env → CLI).
- `config-rs` requires more glue for the same outcome and has noisier errors.

If you're committed to `serde_path_to_error` and don't need source tracking, `config-rs` is fine.
