---
digest-of: tech/languages/rust
last-synced: 2026-07-09
source-files:
  - README.md
  - axum.md
  - datetime-serde-sqlx-chrono.md
  - patterns.md
  - rust.md
  - sqlx.md
token-estimate: 5800
---

# AGENTS

## Scope

Rust language notes at the top level: general Rust guidance, framework notes, database integration
patterns, and pointers to the bootstrap, CLI, and release/publishing sub-shelves (each of which
carries its own nested digest).

## Key Points

- **General notes** (`rust.md`): libraries, cargo tools, git2, module layout, arrays/vectors, and
  iterator patterns.
- **Patterns** (`patterns.md`): general Rust idioms and patterns.
- **Axum**: Web framework reference notes.
- **DateTime handling**: serde + SQLx + chrono integration patterns.
- **SQLx**: Database query patterns and migrations-related notes.
- **Bootstrap**: the `project-bootstrap-spec/` sub-shelf is the rust binding of the general
  `tech/programming/project-bootstrap/` shelf — toolchain/layout, quality gates, and the CLI
  implementation-kind. Own nested `AGENTS.md`.
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
| Bootstrap (sub-shelf)            | `project-bootstrap-spec/`       |
| Release & publishing (sub-shelf) | `release-workflow-spec/`        |
| DateTime + serde + SQLx + chrono | `datetime-serde-sqlx-chrono.md` |
| General Rust patterns            | `patterns.md`                   |
| General Rust notes               | `rust.md`                       |
| SQLx patterns                    | `sqlx.md`                       |

## Maintenance Notes

- `cli-spec/`, `project-bootstrap-spec/`, and `release-workflow-spec/` each have their own digest
  and are not expanded here.
- The former top-level `code-review-guide.md` was migrated out of this repo into the cog skill-refs
  corpus; it is no longer a source file here.
- Regenerate when any top-level Rust markdown file changes or new ones are added.
