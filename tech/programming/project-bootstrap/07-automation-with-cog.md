# 07 — Automation with cog

Most of the bootstrap runbook can be automated with [cog](https://github.com/gubasso/cog) and its
`bootstrap-*` skills — one skill per domain. This chapter defines how automation relates to this
repository as the source of truth.

## The contract

This repo is the **SoT** for _what_ must happen; `cog bootstrap-*` skills automate _how_.

> If cog and the runbook disagree, fix the runbook first, then cog.

The manual runbook is authoritative. cog is a _how_ accelerator, never the source of truth: it
detects project state and applies templates that satisfy the steps documented here. If a skill's
behavior diverges from the documented step, the documented step wins and the skill is corrected to
match.

## Domain → helper map

Each bootstrap domain maps to exactly one cog skill. This is a routing table, **not** a restatement
of the steps — the steps live in the runbook and chapters.

| Bootstrap domain            | Runbook step | cog skill                 |
| --------------------------- | ------------ | ------------------------- |
| Repository foundation       | 2            | `bootstrap-repo`          |
| Governance & docs           | 3            | `bootstrap-governance`    |
| Local dev environment (Nix) | 4            | `bootstrap-nix`           |
| Editorconfig                | 4            | `bootstrap-editorconfig`  |
| Pre-commit hooks            | 5            | `bootstrap-precommit`     |
| Task runner                 | 5            | `bootstrap-taskrunner`    |
| CI workflow                 | 6            | `bootstrap-ci`            |
| Rust crate skeleton         | language     | `bootstrap-rust`          |
| Cargo publishing            | release      | `bootstrap-cargo-publish` |

Language- and release-specific skills (`bootstrap-rust`, `bootstrap-cargo-publish`) belong to the
language binding and the release phase respectively, not to the general spine.

## Using the annotations

Each manual step in the [runbook](./runbook.md) may carry an inline `Automate:` annotation naming
the cog skill for that domain. Read the annotation as "this step _can_ be automated by that skill";
the manual command stays primary so the recipe is followable with or without cog. Run the skills in
runbook order, verifying each step's outcome before the next.
