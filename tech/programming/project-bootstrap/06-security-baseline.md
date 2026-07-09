# 06 — Security baseline

The minimum security posture a new project should have from day one. Keep it language-agnostic here;
the language binding adds ecosystem tools (e.g. `cargo-deny` / `cargo-audit` for Rust).

## Secrets hygiene

Never commit secrets. Enforce it on three fronts:

- **Ignore** — `.env` and credential files are in `.gitignore` (chapter
  [01](./01-repository-foundation.md)) so they cannot be staged by accident.
- **Scan** — enable secret scanning / push protection on the forge to block a secret that slips
  through.
- **Rotate** — if a secret is ever committed, rotate it; scrubbing history is not enough.

Prefer keyless auth (OIDC / Trusted Publishing) wherever the release phase supports it, so there is
no long-lived registry secret to leak.

## Dependency review & audit

Track and vet dependencies:

- Enable automated dependency-update PRs so you learn about advisories promptly.
- Run a vulnerability audit in CI that fails on known-vulnerable dependencies.
- Review new dependencies before adding them — every dependency is attack surface.

## OpenSSF Scorecard

[OpenSSF Scorecard](https://github.com/ossf/scorecard) is a measurable baseline: it scores a repo on
branch protection, pinned dependencies, token permissions, CI-test presence, and more. Use its
checks as the target checklist for the security posture — most map directly to steps already in this
runbook (branch protection in chapter [05](./05-ci-and-release-readiness.md), least-privilege CI
tokens, etc.).

## Automation

Secrets hygiene and dependency auditing are partly wired by the CI and repo-foundation skills; the
security requirements above are the SoT. See
[07 — Automation with cog](./07-automation-with-cog.md).
