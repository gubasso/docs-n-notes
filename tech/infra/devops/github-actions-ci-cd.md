# GitHub Actions CI/CD

This page has been retired. Its former contents described a hand-rolled Rust release using a
long-lived `CARGO_REGISTRY_TOKEN`, a local `cargo release` bump, and a merge-back-to-`develop` step
— all superseded by the automated release-PR + Trusted Publishing (OIDC) model.

For the current guidance see:

- [General release workflow principles](../../programming/release-workflow/README.md) — branch
  model, release-PR invariant, keyless OIDC publishing, and the version
  [source-of-truth decision](../../programming/design-decisions/version-source-of-truth.md).
- [Rust release & publishing](../../languages/rust/release-workflow-spec/README.md) — release-plz on
  the `develop`/`master` model, crates.io Trusted Publishing, metadata, tokens, SemVer/yank, and
  cargo-dist binary distribution.
