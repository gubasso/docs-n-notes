# 01 — Quality gates

The Rust concretion of the general
[quality gates](../../../programming/project-bootstrap/04-quality-gates.md) and
[security baseline](../../../programming/project-bootstrap/06-security-baseline.md) chapters.

## Formatter — `rustfmt`

`rustfmt` is the non-negotiable formatter. Add a `rustfmt.toml` only if you deviate from defaults;
enforce in CI with:

```bash
cargo fmt --check
```

## Linter — `clippy`

Run `clippy` with warnings denied so lint failures block the build:

```bash
cargo clippy --all-targets --all-features -- -D warnings
```

Add crate-level `#![deny(...)]` or a `[lints]` table in `Cargo.toml` for the lints you always want
enforced.

## Security — `cargo-deny` / `cargo-audit`

These are the Rust tools behind the general security baseline:

- `cargo audit` — fails on dependencies with known RUSTSEC advisories.
- `cargo deny check` — advisories plus license and source-ban policy.

Run both in CI so a vulnerable or disallowed dependency cannot merge.

## Pre-commit wiring

Wire `cargo fmt --check` and `cargo clippy` into the pre-commit hooks from the general
[04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md) so failures surface
locally in seconds.

## Publish-readiness (later phase)

Publish-grade checks (`cargo publish --dry-run`, metadata completeness) belong to the release phase,
not bootstrap — see [`../release-workflow-spec/`](../release-workflow-spec/README.md). Bootstrap
only guarantees the crate builds, formats, lints, and audits clean.
