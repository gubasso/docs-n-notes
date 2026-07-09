# Rust — bootstrap a new project (spec/binding)

The Rust binding of
[`tech/programming/project-bootstrap/`](../../../programming/project-bootstrap/README.md). It
applies the general once-per-project recipe with concrete cargo tooling — crate scaffolding,
toolchain pinning, and the rustfmt/clippy/deny quality gates — and links to Rust
implementation-kinds.

This binding **overlays** the general spine; it does not restate it. Read the general recipe first,
then the Rust specifics here.

For a condensed, copy-paste hands-on path across bootstrap **and** release in one file, see the
[cookbook](../cookbook/README.md) — it inlines and footnotes the chapters here.

## How to use this binding

1. Read the general [hub](../../../programming/project-bootstrap/README.md) and
   [general runbook](../../../programming/project-bootstrap/runbook.md) — the cross-language _what_.
2. Follow this [`runbook.md`](./runbook.md) for the Rust-specific overlay steps.
3. Jump to your implementation-kind file (e.g. [`cli-project.md`](./cli-project.md)).
4. When ready to publish, hand off to
   [`../release-workflow-spec/`](../release-workflow-spec/README.md) — the later Rust release phase.

## Index

| # | Chapter                                            | One-line hook                                                           |
| - | -------------------------------------------------- | ----------------------------------------------------------------------- |
| 0 | [Toolchain & layout](./00-toolchain-and-layout.md) | `cargo new`/`init`, `Cargo.toml` baseline, `rust-toolchain.toml` + Nix. |
| 1 | [Quality gates](./01-quality-gates.md)             | `rustfmt`, `clippy -D warnings`, `cargo-deny` / `cargo-audit`.          |

## Implementation kinds

- [`cli-project.md`](./cli-project.md) — Rust CLI: the bootstrap-time ordering for arg-parsing,
  logging, and config, delegating detail to [`../cli-spec/`](../cli-spec/README.md).

`library-project.md` and `web-service.md` are followups; add them when you bootstrap those kinds.

## Related

- [General project-bootstrap](../../../programming/project-bootstrap/README.md) — the cross-language
  recipe this binding overlays.
- [`../release-workflow-spec/`](../release-workflow-spec/README.md) — the later Rust release &
  publishing phase.
- [`../cli-spec/`](../cli-spec/README.md) — the detailed Rust CLI structure spec.
