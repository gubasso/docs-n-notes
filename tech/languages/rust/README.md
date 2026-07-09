# Rust

Rust notes and workflow references.

- [axum](./axum.md)
- [release-workflow-spec](release-workflow-spec/README.md) — the unified Rust release & publishing
  shelf: `develop`/`master` workflow with release-plz + `master` promotion, crates.io Trusted
  Publishing, crate metadata, token scopes, helper scripts, cargo-dist, and a per-new-project
  runbook (rust binding of [general release-workflow](../../programming/release-workflow/README.md))
- [datetime-serde-sqlx-chrono](./datetime-serde-sqlx-chrono.md)
- [patterns](./patterns.md)
- [project-bootstrap-spec](project-bootstrap-spec/README.md) — bootstrap a new Rust project:
  toolchain/layout, quality gates, and CLI implementation-kind (rust binding of
  [general project-bootstrap](../../programming/project-bootstrap/README.md))
- [rust](./rust.md)
- [sqlx](./sqlx.md)

Toolchain: the canonical per-project setup is a Nix devShell reading `rust-toolchain.toml` — see
[nix/03-rust-toolchain](../../tools/nix/03-rust-toolchain.md).
