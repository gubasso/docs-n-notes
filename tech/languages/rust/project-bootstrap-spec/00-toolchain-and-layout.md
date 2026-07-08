# 00 — Toolchain & layout

The Rust ecosystem choices for a fresh crate: how to scaffold it, what baseline metadata to set, how
to pin the toolchain, and where the detailed layout spec lives.

## Scaffold the crate

- Binary: `cargo new <name>` (creates `Cargo.toml` + `src/main.rs`).
- Library: `cargo new --lib <name>` (creates `src/lib.rs`).
- In an existing directory: `cargo init` (or `cargo init --lib`).

`bootstrap-rust` automates this scaffold (and only scaffolds when the project is not already a
crate).

## `Cargo.toml` baseline metadata

Set the minimum now: `name`, `version`, `edition`, and a short `description`. Leave publish-grade
metadata (`license`, `repository`, `keywords`, `categories`, `exclude`) to the release phase — it is
owned by
[`../release-workflow-spec/01-crate-metadata.md`](../release-workflow-spec/01-crate-metadata.md), so
do not duplicate that gate here. Bootstrap only needs enough to build and test.

## Toolchain pinning + Nix

Add a `rust-toolchain.toml` pinning the channel/version and required components (e.g. `clippy`,
`rustfmt`). The canonical per-project setup reads that file from a Nix devShell so local and CI
share one toolchain — see [nix/03-rust-toolchain](../../../tools/nix/03-rust-toolchain.md). This
closes the "works on my machine" gap before any code is written.

## Layout

For a single crate, the default `cargo new` layout is enough to start. For anything with
subcommands, multiple modules, or a workspace, follow the detailed structure spec:
[`../cli-spec/00-directory-tree.md`](../cli-spec/00-directory-tree.md) and
[`../cli-spec/01-crate-layout.md`](../cli-spec/01-crate-layout.md). Bootstrap owns the _ordering_
(get a buildable crate first); `cli-spec/` owns the detailed _how_.

## Automation

`bootstrap-rust` lays down the crate skeleton and optional rustfmt/clippy/deny config. The steps
above are the SoT; see
[general 07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md).
