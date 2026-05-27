---
digest-of: tech/languages/rust
last-synced: 2026-05-27
source-files:
  - code-review-guide.md
  - rust.md
  - patterns.md
  - axum.md
  - datetime-serde-sqlx-chrono.md
  - publish-crates-io.md
  - sqlx.md
token-estimate: 500
---

# AGENTS

## Scope

Rust language notes at the top level (outside `cli-spec/`). Includes the code-review guide, general
Rust notes, patterns, and framework-specific references (Axum, SQLx, chrono).

## Key Points

- **Code review guide**: Rust-specific review heuristics for the `review-code-deep` skill. Covers
  ownership, lifetimes, unsafe, error handling, concurrency, and Rust-specific anti-patterns.
- **General notes** (`rust.md`): Libraries roster (thiserror, anyhow, miette, tracing), cargo tools
  (watch, test, release), git2 crate, module/file structure, arrays/vectors, iterators.
- **Patterns** (`patterns.md`): Typestate pattern reference (Cliffle blog).
- **Axum**: Web framework notes.
- **DateTime handling**: serde + SQLx + chrono integration patterns.
- **SQLx**: Database query patterns.
- **Publishing**: crates.io publishing workflow.

## Source Map

| Topic                                               | File                             |
| --------------------------------------------------- | -------------------------------- |
| Rust review heuristics (loaded by review-code-deep) | `code-review-guide.md`           |
| Libraries, cargo tools, general Rust notes          | `rust.md`                        |
| Typestate pattern                                   | `patterns.md`                    |
| Axum web framework                                  | `axum.md`                        |
| DateTime + serde + SQLx + chrono                    | `datetime-serde-sqlx-chrono.md`  |
| crates.io publishing                                | `publish-crates-io.md`           |
| SQLx patterns                                       | `sqlx.md`                        |
| CLI project spec (full spec)                        | `cli-spec/` (separate AGENTS.md) |

## Maintenance Notes

- CLI-spec has its own detailed AGENTS.md; this digest covers only the top-level Rust files.
- Several files are reference-link collections rather than detailed guides; load directly when the
  specific topic arises.
