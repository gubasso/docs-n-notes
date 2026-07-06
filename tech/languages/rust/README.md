# Rust

Rust notes and workflow references.

- [axum](axum.md)
- [code-review-guide](code-review-guide.md)
- [crates-io-publishing](crates-io-publishing/README.md) — publishing to crates.io (release-plz +
  Trusted Publishing/OIDC, token scopes, helper scripts)
- [release-workflow-spec](release-workflow-spec/README.md) — the `develop`/`master` release workflow
  with release-plz + `master` promotion (rust binding of
  [general release-workflow](../../programming/release-workflow/README.md))
- [datetime-serde-sqlx-chrono](datetime-serde-sqlx-chrono.md)
- [patterns](patterns.md)
- [rust](rust.md)
- [sqlx](sqlx.md)

Toolchain: the canonical per-project setup is a Nix devShell reading `rust-toolchain.toml` — see
[nix/03-rust-toolchain](../../tools/nix/03-rust-toolchain.md).
