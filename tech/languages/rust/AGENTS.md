---
digest-of: tech/languages/rust
last-synced: 2026-05-28
source-files:
  - README.md
  - axum.md
  - cargo-release-setup.md
  - code-review-guide.md
  - datetime-serde-sqlx-chrono.md
  - patterns.md
  - publish-crates-io.md
  - rust.md
  - sqlx.md
token-estimate: 7100
---

# AGENTS

## Scope

Rust language notes at the top level, including general Rust guidance, framework notes, database
integration patterns, review heuristics, and publishing workflow references.

## Key Points

- **General notes** (`rust.md`): libraries, cargo tools, git2, module layout, arrays/vectors, and
  iterator patterns.
- **Code review guide**: Rust-specific review heuristics for ownership, lifetimes, unsafe, and
  concurrency.
- **Axum**: Web framework reference notes.
- **DateTime handling**: serde + SQLx + chrono integration patterns.
- **SQLx**: Database query patterns and migrations-related notes.
- **Publishing**: crates.io release workflow.

## Source Map

| Topic                            | File                            |
| -------------------------------- | ------------------------------- |
| Rust index                       | `README.md`                     |
| Axum web framework               | `axum.md`                       |
| Cargo release setup              | `cargo-release-setup.md`        |
| Rust review heuristics           | `code-review-guide.md`          |
| DateTime + serde + SQLx + chrono | `datetime-serde-sqlx-chrono.md` |
| General Rust patterns            | `patterns.md`                   |
| crates.io publishing             | `publish-crates-io.md`          |
| General Rust notes               | `rust.md`                       |
| SQLx patterns                    | `sqlx.md`                       |

## Maintenance Notes

- `cli-spec/` has its own digest and is not included here.
- Regenerate when any top-level Rust markdown file changes or new ones are added.
