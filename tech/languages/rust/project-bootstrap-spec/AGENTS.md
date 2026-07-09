---
digest-of: tech/languages/rust/project-bootstrap-spec
last-synced: 2026-07-09
source-files:
  - README.md
  - runbook.md
  - 00-toolchain-and-layout.md
  - 01-quality-gates.md
  - cli-project.md
token-estimate: 780
---

# AGENTS

## Scope

Rust binding of the general `tech/programming/project-bootstrap/` shelf: the once-per-project Rust
setup that takes an empty repo to a scaffolded, gated, buildable crate ready for feature work. It
**overlays** the general spine (repo, license, governance, dev env, CI, security) and never restates
it; it owns only the Rust ecosystem choices and the CLI implementation-kind ordering. Publishing is
out of scope — it hands off to `../release-workflow-spec/`.

## Key Points

- **Scaffold:** `cargo new <name>` for a binary (`Cargo.toml` + `src/main.rs`),
  `cargo new --lib
  <name>` for a library (`src/lib.rs`); `cargo init` (or `cargo init --lib`) in
  an existing dir. `bootstrap-rust` automates the scaffold, and only scaffolds when the project is
  not already a crate.
- **`Cargo.toml` baseline:** set the minimum now — `name`, `version`, `edition`, short `description`
  — enough to build and test. Publish-grade metadata (`license`, `repository`, `keywords`,
  `categories`, `exclude`) is deferred to the release phase, owned by
  `../release-workflow-spec/01-crate-metadata.md`; do not duplicate that gate here.
- **Toolchain pin + Nix:** a `rust-toolchain.toml` pins the channel/version and required components
  (e.g. `clippy`, `rustfmt`); a Nix devShell reads that file so local and CI share one toolchain
  (`nix/03-rust-toolchain`), closing the "works on my machine" gap before any code is written.
- **Layout:** default `cargo new` layout is enough for a single crate; anything with subcommands,
  multiple modules, or a workspace follows the detailed structure spec in `../cli-spec/` (bootstrap
  owns the _ordering_ — buildable crate first — `cli-spec/` owns the detailed _how_).
- **Quality gates:** `rustfmt` (non-negotiable formatter, `cargo fmt --check`, `rustfmt.toml` only
  to deviate from defaults); `clippy` with warnings denied
  (`cargo clippy --all-targets
  --all-features -- -D warnings`, plus crate-level `#![deny(...)]` or
  a `[lints]` table); `cargo
  audit` (fails on RUSTSEC advisories) and `cargo deny check`
  (advisories + license + source-ban policy) as the security baseline, both run in CI. Wire
  `cargo fmt --check` and `cargo clippy` into pre-commit so failures surface locally in seconds.
- **CLI kind:** on the buildable, gated crate, layer in order — (1) directory & crate layout
  (binary/library split, module tree), (2) argument parsing & subcommands (e.g. `clap`), (3) error
  handling (consistent error type + exit-code strategy), (4) logging (structured, level-controlled),
  (5) configuration (file + env + flag precedence). This file owns only the bootstrap-time
  _ordering_ and delegates every detail to `../cli-spec/`.
- **Release handoff:** publish-readiness (`cargo publish --dry-run`, metadata completeness) and
  binary distribution (installers, `cargo-binstall`, cargo-dist) are release-phase work — hand off
  to `../release-workflow-spec/` (release-plz, Trusted Publishing, cargo-dist). Bootstrap stops at a
  crate that builds, formats, lints, and audits clean.

## Source Map

| Topic                                                           | File                         |
| --------------------------------------------------------------- | ---------------------------- |
| Binding index, how-to-use, implementation-kinds list, related   | `README.md`                  |
| Ordered Rust overlay steps (the _what_/_in what order_)         | `runbook.md`                 |
| `cargo new`, `Cargo.toml` baseline, `rust-toolchain.toml` + Nix | `00-toolchain-and-layout.md` |
| `rustfmt` / `clippy -D warnings` / `cargo-deny`·`cargo-audit`   | `01-quality-gates.md`        |
| CLI bootstrap-time ordering (args, errors, logging, config)     | `cli-project.md`             |

## Maintenance Notes

- General spine: `../../../programming/project-bootstrap/`. Release handoff (release-plz, Trusted
  Publishing, cargo-dist): `../release-workflow-spec/`. Detailed CLI structure: `../cli-spec/`.
- `library-project.md` and `web-service.md` are declared followup kinds; add them (and refresh
  `source-files`) when those kinds are bootstrapped.
- Automation contract lives in general `07-automation-with-cog.md` — the runbook owns the _what_,
  `bootstrap-rust` (cog) the _how_.
- No conflicts among the current source files.
