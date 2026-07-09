---
digest-of: tech/languages/rust/cookbook
last-synced: 2026-07-09
source-files:
  - README.md
token-estimate: 800
---

# AGENTS

## Scope

A single-file, TLDR "ship a Rust project" cookbook: the ordered, copy-paste path from a crate with a
git remote to a published, branch-protected, CI-gated crate. It **intentionally inlines** snippets
that live canonically in the Rust `project-bootstrap-spec/`, `release-workflow-spec/`, `cli-spec/`
shelves and in `tools/git/branch-protection/` + `tools/nix/`, footnoting each to its owner. This
duplication is the sanctioned cookbook exception to the repo's SoT/DRY rule (repo `CLAUDE.md`;
ADR-0002).

## Key Points

- **Not a source of truth.** Every snippet footnotes the spec that owns it; on any disagreement the
  footnoted spec wins. Do not treat the cookbook as canonical, and do not de-duplicate it against
  the specs — the exception is deliberate.
- **Section order:** 0 prerequisites → 1 scaffold with `rust-toolchain.toml` → 2 crate metadata
  (publish gate) → 3 quality gates (`[lints]`, `deny.toml`, pre-commit, justfile) → 4 Nix devShell →
  5 first CI (`ci.yml`; job name is the required status check) → 6 branch security
  (`github/setup.sh` rulesets, Actions read/write) → 7 release/publish (dry-run, first manual
  publish, register trusted publisher `release-plz.yml`, revoke token, commit
  `release-plz.toml`/`.yml`) → 8 cargo-dist binaries → 9 semver/yank/rollback → GitLab notes.
- **GitHub-primary**, GitLab covered as a short closing section.
- Regeneration of the cookbook is human-authored (it is prose the maintainer owns), but this
  `AGENTS.md` digest is the LLM-generated artifact for the directory.

## Source Map

| Topic                                    | File        |
| ---------------------------------------- | ----------- |
| The full ordered ship-it runbook + notes | `README.md` |

## Maintenance Notes

- The cookbook mirrors, in order, the canonical specs it footnotes. When those specs change
  materially (crate-metadata fields, release-plz workflow, branch-protection ruleset intent, nix
  toolchain flake), re-check the corresponding cookbook section so the inlined snippet stays
  faithful — the cookbook is allowed to duplicate, not to drift.
- Regenerate this digest when `README.md` changes.
