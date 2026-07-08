---
digest-of: tech/languages/rust
last-synced: 2026-07-08
source-files:
  - README.md
  - axum.md
  - code-review-guide.md
  - datetime-serde-sqlx-chrono.md
  - patterns.md
  - rust.md
  - sqlx.md
token-estimate: 7000
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
- **Release & publishing**: the `release-workflow-spec/` sub-shelf is the unified rust binding of
  the general `tech/programming/release-workflow/` shelf — release-plz on `develop`, `master`
  promotion onto the release tag, crates.io Trusted Publishing (register `release-plz.yml`, not
  `release.yml`), crate metadata, token scopes, helper scripts, SemVer/yank, cargo-dist binary
  distribution, and a per-new-project runbook. Own nested `AGENTS.md`. (Formerly split into a
  separate `crates-io-publishing/` shelf — now merged.)

## Source Map

| Topic                            | File                            |
| -------------------------------- | ------------------------------- |
| Rust index                       | `README.md`                     |
| Axum web framework               | `axum.md`                       |
| Rust review heuristics           | `code-review-guide.md`          |
| Release & publishing (sub-shelf) | `release-workflow-spec/`        |
| DateTime + serde + SQLx + chrono | `datetime-serde-sqlx-chrono.md` |
| General Rust patterns            | `patterns.md`                   |
| General Rust notes               | `rust.md`                       |
| SQLx patterns                    | `sqlx.md`                       |

## Maintenance Notes

- `cli-spec/` and `release-workflow-spec/` each have their own digest and are not expanded here.
- Regenerate when any top-level Rust markdown file changes or new ones are added.
