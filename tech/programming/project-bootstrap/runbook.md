# Runbook — bootstrap a new project (any language)

The ordered, **once-per-project** manual steps to take a project from an empty repo to a
fully-scaffolded, quality-gated baseline ready for feature work. Each step links to the chapter that
explains the _why_; this page is only the _what_ and _in what order_.

Language- and implementation-kind specifics are **overlays** — after the general steps here, jump to
your [`project-bootstrap-spec/`](../../languages/rust/project-bootstrap-spec/README.md) binding.
Everyday work after setup is not here; this is the one-time scaffold.

## Prerequisites

- A version-controlled host with Git installed.
- An account on the target forge (GitHub / GitLab).
- A decision on **language** and **implementation-kind** — see the
  [three-layer model](README.md#the-three-layer-model).

## Steps

1. **Create the repo and pick the default branch.** Create an empty repo on the forge and clone it;
   set the default branch to `develop` if you follow the develop/master model. →
   [00 — Bootstrap model](00-bootstrap-model.md),
   [branch-protection first-run](../../tools/git/branch-protection/first-run-enablement.md).

2. **Lay the repository foundation:** add `.gitignore`, a `LICENSE` (SPDX identifier), and a
   `README` skeleton at the repo root. → [01 — Repository foundation](01-repository-foundation.md).
   _Automate:_ `bootstrap-repo`.

3. **Seed governance docs:** `CLAUDE.md` (agent instructions), the `AGENTS.md` convention, and an
   ADR scaffold for decisions. → [02 — Governance & docs](02-governance-and-docs.md). _Automate:_
   `bootstrap-governance`.

4. **Set up the local dev environment:** a Nix devShell + `.envrc` (direnv) for a reproducible
   toolchain, and an `.editorconfig` for cross-editor consistency. →
   [03 — Local dev environment](03-local-dev-environment.md). _Automate:_ `bootstrap-nix`,
   `bootstrap-editorconfig`.

5. **Wire the quality gates:** a formatter, a linter, pre-commit hooks, and a task runner (a single
   entry point for common recipes). → [04 — Quality gates](04-quality-gates.md). _Automate:_
   `bootstrap-precommit`, `bootstrap-taskrunner`.

6. **Stand up CI and release-readiness:** a first CI workflow (build + test + gates) and branch
   protection. Release _setup_ itself lives in the later phase. →
   [05 — CI & release-readiness](05-ci-and-release-readiness.md). _Automate:_ `bootstrap-ci`. Links:
   [`../release-workflow/`](../release-workflow/README.md),
   [`../../tools/git/branch-protection/`](../../tools/git/branch-protection/).

7. **Establish the security baseline:** secrets hygiene, dependency review/audit, and the OpenSSF
   Scorecard checklist. → [06 — Security baseline](06-security-baseline.md).

8. **Apply language + implementation-kind overlays.** Jump to your language binding and follow its
   runbook, then its implementation-kind file. →
   [`project-bootstrap-spec/`](../../languages/rust/project-bootstrap-spec/README.md) (Rust
   reference binding).

## Automation

The whole recipe can be driven by `cog bootstrap-*` skills — one skill per domain. The manual steps
above remain **primary and authoritative**: cog automates the _how_, this runbook owns the _what_.
See [07 — Automation with cog](07-automation-with-cog.md) for the domain→helper map and the
reconciliation rule.

## Reference

- [00 — Bootstrap model](00-bootstrap-model.md) ·
  [05 — CI & release-readiness](05-ci-and-release-readiness.md) ·
  [07 — Automation with cog](07-automation-with-cog.md) ·
  [branch-protection first-run](../../tools/git/branch-protection/first-run-enablement.md)
