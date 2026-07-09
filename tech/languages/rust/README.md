# Rust

Rust guidance: general language notes and idioms, the axum web framework, and database integration
(SQLx, chrono/serde datetimes) live as topic files here — the [`AGENTS.md`](./AGENTS.md) Source Map
indexes them file by file. The once-per-project specs and the ship-it cookbook are the landmarks:

**Start here to ship a project:** [cookbook](cookbook/README.md) — a one-file TLDR runbook that
takes a crate from repo + remote to published, branch-protected, and CI-gated (scaffold → gates →
branch security → CI → release/publish), footnoted to the deep-dive specs.

- [`project-bootstrap-spec/`](project-bootstrap-spec/README.md) — bootstrap a new Rust project:
  toolchain/layout and the rustfmt/clippy/deny quality gates (Rust binding of
  [general project-bootstrap](../../programming/project-bootstrap/README.md)).
- [`release-workflow-spec/`](release-workflow-spec/README.md) — the unified Rust release &
  publishing shelf: `develop`/`master` with release-plz + `master` promotion, crates.io Trusted
  Publishing, crate metadata, and cargo-dist (Rust binding of
  [general release-workflow](../../programming/release-workflow/README.md)).

Toolchain: the canonical per-project setup is a Nix devShell reading `rust-toolchain.toml` — see
[nix/03-rust-toolchain](../../tools/nix/03-rust-toolchain.md).
