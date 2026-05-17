# 04 — Logging, Config, Testing

Three independent concerns, one chapter because they all share the same shape: the binary owns initialization; libraries are the consumers.

---

## Logging

### Rules

- Libraries depend on `tracing` only. They emit events; they never install a subscriber.
- The binary depends on `tracing-subscriber` and installs exactly one subscriber in `main`.
- Honor `RUST_LOG`. Do not invent app-specific env vars like `APP_LOG` — users have muscle memory for `RUST_LOG`.
- The CLI exposes `-v` / `-vv` / `-vvv` for `info` / `debug` / `trace`. `RUST_LOG` overrides if set.

### `src/logging.rs`

```rust
//! tracing-subscriber installation. Called once from `main`.

use tracing_subscriber::{EnvFilter, fmt, layer::SubscriberExt, util::SubscriberInitExt};

pub fn init(verbosity: u8) -> anyhow::Result<()> {
    let default_directive = match verbosity {
        0 => "warn",
        1 => "info",
        2 => "debug",
        _ => "trace",
    };
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new(default_directive));

    tracing_subscriber::registry()
        .with(filter)
        .with(fmt::layer().with_writer(std::io::stderr).with_target(false))
        .try_init()
        .map_err(|e| anyhow::anyhow!("install tracing subscriber: {e}"))?;
    Ok(())
}
```

Output goes to stderr so it doesn't pollute stdout, which is reserved for the command's actual output.

### When to add a file sink

Add a non-blocking file sink (via `tracing-appender`) when:

- The CLI runs unattended (cron, CI) and someone needs forensic logs after the fact.
- The CLI orchestrates long-running subprocesses whose output should be persisted.

For a typical interactive CLI, stderr is enough.

### JSON formatting

Use `fmt::layer().json()` when logs feed a structured pipeline (Loki, ELK). For human-facing terminal output, the default pretty formatter is right.

### What to log at each level

- `error!` — the operation failed in a way the user needs to know about. Always paired with a returned `Err`.
- `warn!` — recoverable problem; we proceeded but the user might care.
- `info!` — high-level progress (e.g. "synced 12 widgets in 1.2s"). One per top-level operation.
- `debug!` — call boundaries with arg summaries. Read by developers, not users.
- `trace!` — deep internals, hot loops. Off by default even at `-vvv`.

### Spans

Open a span per top-level operation and per adapter call:

```rust
let _span = tracing::info_span!("widget.sync", id = %id).entered();
```

`AppContext` carries the root span; `commands/*` open child spans named `<command>.<phase>`.

---

## Config

### Rules

- One `Config` struct represents the resolved, merged config. It is immutable after construction.
- Construction merges five sources in precedence order (low → high): defaults → user file → project file → env → CLI.
- Use `figment` for the merge. It tracks source provenance, so errors say *which file* set the bad value.
- Use the `directories` crate to resolve XDG paths. Do not hand-roll `$XDG_CONFIG_HOME` logic.
- Config holds user-facing knobs only. Domain invariants live in `domain/`.

### `src/config/mod.rs`

```rust
//! Config loading. Figment merges defaults < user < project < env < CLI.

use figment::{Figment, providers::{Env, Format, Serialized, Toml}};
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct Config {
    pub log_format: LogFormat,
    pub editor: String,
    pub timeout_secs: u64,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            log_format: LogFormat::Text,
            editor: std::env::var("EDITOR").unwrap_or_else(|_| "vi".into()),
            timeout_secs: 30,
        }
    }
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum LogFormat { Text, Json }

#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("config error: {0}")]
    Figment(#[from] figment::Error),
}

pub fn load(cli_overrides: &impl Serialize, project_config: Option<&Path>) -> Result<Config, ConfigError> {
    let user_path = user_config_path();
    let project_path = project_config.map(PathBuf::from);

    let mut fig = Figment::new()
        .merge(Serialized::defaults(Config::default()));

    if let Some(p) = user_path.as_ref() {
        fig = fig.merge(Toml::file(p));
    }
    if let Some(p) = project_path.as_ref() {
        fig = fig.merge(Toml::file(p));
    }

    fig.merge(Env::prefixed("APP_").split("__"))
        .merge(Serialized::defaults(cli_overrides))
        .extract::<Config>()
        .map_err(Into::into)
}

fn user_config_path() -> Option<PathBuf> {
    directories::ProjectDirs::from("com", "you", "app")
        .map(|d| d.config_dir().join("config.toml"))
}
```

### Layering precedence (low → high)

| Source | Path | Example |
|--------|------|---------|
| Defaults | `Config::default()` | hard-coded fallbacks |
| User file | `$XDG_CONFIG_HOME/app/config.toml` | personal preferences |
| Project file | `./.app/config.toml` | per-repo overrides |
| Env vars | `APP_*` (double-underscore = nested) | `APP_TIMEOUT_SECS=60`, `APP_LOG__FORMAT=json` |
| CLI flags | `clap` parsed values | `--timeout-secs 60` |

CLI always wins. Env wins over files. Project wins over user. Defaults lose to everything.

### Why figment over `config-rs` or `confy`

- `figment` tracks per-key source provenance — errors say *"`timeout_secs` from `./app.toml` was negative"*, not just *"invalid value"*.
- `config-rs` works but its error messages are vaguer.
- `confy` can't layer multiple files; it's fine for tiny CLIs and nothing else.

---

## Testing

The testing pyramid for a CLI:

```
                /\
               /  \      compile-fail / typestate (trybuild)         — only when typestate exists
              /----\
             /      \    integration (assert_cmd + insta + tempfile) — one per subcommand
            /--------\
           /          \  unit (#[cfg(test)] mod tests)                — every module with logic
          /____________\
```

### Unit tests

Colocated at the bottom of each module:

```rust
// src/commands/widget.rs

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn from_cli_parses_glob() {
        let args = WidgetArgs { id: None, dry_run: false, filter: Some("*.txt".into()) };
        let req = Request::from_cli(args).unwrap();
        assert!(req.filter.is_some());
    }
}
```

Target: every CLI-args → domain-Request projection, every newtype constructor, every state-machine transition.

### Integration tests

One file per subcommand under `tests/`:

```rust
// tests/cmd_widget.rs

use assert_cmd::Command;
use predicates::prelude::*;
use tempfile::tempdir;

#[test]
fn widget_dry_run_prints_plan_without_changing_state() {
    let tmp = tempdir().unwrap();
    Command::cargo_bin("app").unwrap()
        .arg("widget").arg("--dry-run")
        .current_dir(&tmp)
        .assert()
        .success()
        .stdout(predicate::str::contains("would create"));
    assert!(tmp.path().read_dir().unwrap().next().is_none(), "dry-run should not write files");
}
```

Rules:

- One file per subcommand. Test names describe behavior, not implementation.
- Every test gets its own `tempdir`. Never share state.
- Use `predicates::str::contains` for stdout matching; reserve exact-equality for tiny stable strings.

### Snapshot tests

Use `insta` for any structured output (JSON, YAML, rendered tables, long error messages):

```rust
#[test]
fn widget_list_renders_table() {
    let report = make_test_report();
    insta::assert_yaml_snapshot!(report);
}
```

For stdout snapshots from integration tests, use `insta::assert_snapshot!` with the captured stdout. Snapshots live in `tests/snapshots/`. Review snapshot diffs as carefully as code diffs — they're behavior.

### Compile-fail / typestate (optional)

Use `trybuild` only when you have a typestate API (e.g. a builder where the type changes per `.with_x()` call) and want to lock down the invalid call sequences. Skip otherwise.

```rust
// tests/trybuild.rs
#[test]
fn ui() {
    let t = trybuild::TestCases::new();
    t.compile_fail("tests/trybuild/*.rs");
}
```

### Test runner

Use `cargo nextest` via `just test`. It parallelizes correctly, fails fast, and produces a flat summary. `cargo test` is fine but slower and noisier.

### `tests/support/mod.rs`

Shared helpers — tempdir setup, fixture loaders, env scrubbers:

```rust
//! Shared test helpers.

use std::path::PathBuf;
use tempfile::TempDir;

pub struct Fixture {
    pub tmp: TempDir,
    pub home: PathBuf,
}

impl Fixture {
    pub fn new() -> Self {
        let tmp = tempfile::tempdir().unwrap();
        let home = tmp.path().join("home");
        std::fs::create_dir_all(&home).unwrap();
        Self { tmp, home }
    }

    pub fn cmd(&self) -> assert_cmd::Command {
        let mut c = assert_cmd::Command::cargo_bin("app").unwrap();
        c.env_clear()
            .env("HOME", &self.home)
            .env("PATH", std::env::var_os("PATH").unwrap());
        c
    }
}
```

`env_clear` plus a curated env is the defense against test pollution. Without it, your local `RUST_LOG=trace` will break CI snapshots.
