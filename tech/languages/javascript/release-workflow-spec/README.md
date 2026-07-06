# JavaScript / Node Release Workflow Spec

This is the **JavaScript/Node binding** of the
[general principles](../../../programming/release-workflow/README.md); it is a **stub to be
expanded**.

## Recommended tooling

- **Release-PR tool (idiomatic):** [Changesets](https://github.com/changesets/changesets) +
  [`changesets/action`](https://github.com/changesets/action) — developers add changeset files per
  PR; the action opens/maintains a **"Version Packages"** release PR; on merge it versions +
  publishes. Monorepo-friendly. Note this uses explicit changeset files rather than conventional
  commits (a deliberate divergence).
- **Alternatives:** semantic-release (push model, conventional commits); release-please (release-PR,
  conventional commits).
- **Publish + auth:**
  [npm Trusted Publishing with OIDC](https://github.blog/changelog/2025-07-31-npm-trusted-publishing-with-oidc-is-generally-available/)
  — GA 2025-07-31; no `NPM_TOKEN`; provenance attestations generated automatically; requires npm CLI
  ≥ 11.5.1.

This mirrors the general release-PR + trusted-publishing model. Related note:
[node-npm.md](../node-npm.md) ("Releases" section).

## To expand

- Changesets configuration (`.changeset/config.json`).
- The publish workflow YAML (`changesets/action`).
- OIDC setup for tokenless npm publishing.
- Monorepo release graph (linked vs independent versioning).
