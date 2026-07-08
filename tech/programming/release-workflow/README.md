# Development & Release Workflow — General Principles

Language-agnostic principles for how code moves from a feature branch to a published release: the
branch model, the automated release-PR pattern, keyless registry publishing over OIDC, and the
CI-driven promotion that keeps a release branch honest. Use this tree as the source of truth when
setting up releases for any project, and the language-specific `release-workflow-spec/` bindings for
the concrete tool + workflow YAML.

The model here is deliberately **not** "run the publish command by hand". That command is one step
near the very end; the durable value is in the branch discipline, the review-gated release PR, the
auth model, and the promotion mechanics around it.

## How to use this tree

1. Read [00 — Branch model](00-branch-model.md) first — it defines `develop`/`master`, feature
   branches, and how a release is promoted. The other chapters assume this vocabulary.
1. Read [01 — Release automation](01-release-automation.md) for the release-PR invariant that every
   ecosystem's tool implements.
1. Read [02 — Trusted Publishing / OIDC](02-trusted-publishing-oidc.md) for the keyless auth model
   that crates.io, PyPI, and npm now share.
1. Pick your ecosystem's tool from [03 — Tooling by ecosystem](03-tooling-by-ecosystem.md) and jump
   to the matching language binding.
1. If the project also ships prebuilt binaries/installers, read
   [04 — Workflow file conventions](04-workflow-file-conventions.md) before adding a second workflow
   — it keeps the binary-dist workflow from colliding with the publish workflow.

## Index

| # | Chapter                                                      | One-line hook                                                                                               |
| - | ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| 0 | [Branch model](00-branch-model.md)                           | `develop` integrates, `master` mirrors releases; CI promotes on a tag, no human writes.                     |
| 1 | [Release automation](01-release-automation.md)               | The release-PR invariant: change-intent → bot PR → merge = publish; SemVer + changelog.                     |
| 2 | [Trusted Publishing / OIDC](02-trusted-publishing-oidc.md)   | Short-lived keyless registry auth; the cross-ecosystem convergence point.                                   |
| 3 | [Tooling by ecosystem](03-tooling-by-ecosystem.md)           | release-plz / release-please / Changesets / GoReleaser and how each implements the model.                   |
| 4 | [Workflow file conventions](04-workflow-file-conventions.md) | Separate the publish workflow from the binary-dist workflow; register the _publish_ file with the registry. |

## Language-specific implementation

These bindings apply the general principles with a concrete tool and workflow YAML. They assume
you've read the matching general chapter, and each links back to it.

- [`tech/languages/rust/release-workflow-spec/`](../../languages/rust/release-workflow-spec/) —
  **release-plz** on `develop` + `master` promotion, crates.io Trusted Publishing, crate metadata,
  tokens, helper scripts, cargo-dist binary distribution, and the per-new-project runbook — one
  unified shelf.
- [`tech/languages/bash/release-workflow-spec/`](../../languages/bash/release-workflow-spec/) — tag
  → GitHub Release → `install.sh` / AUR / OBS. Bash has no central registry, so tagging _is_
  publishing.
- [`tech/languages/python/release-workflow-spec/`](../../languages/python/release-workflow-spec/) —
  stub: release-please / python-semantic-release + PyPI Trusted Publishing.
- [`tech/languages/javascript/release-workflow-spec/`](../../languages/javascript/release-workflow-spec/)
  — stub: Changesets + npm Trusted Publishing (OIDC).

## Related (git mechanics & platform setup)

- [Branch protection & CI-driven release](../../tools/git/branch-protection/) — the platform
  runbooks and rulesets (GitHub Rulesets / GitLab protected branches) that enforce this model.
- [Rebase workflow](../../tools/git/rebase-workflow.md) — keeping feature branches linear on
  `develop`.
- [Feature lifecycle](../../tools/git/feature-lifecycle.md) — the issue → branch → PR → merge loop
  that feeds `develop`.

## TL;DR (the irreducible defaults)

- **`develop` integrates; `master` mirrors releases.** Feature branches merge to `develop` via
  reviewed PRs with green CI. `master` is fast-forwarded by CI on release — **no human ever writes
  to it**. (`main` is the common alias for `master`.)
- **A bot opens the release PR; merging it is the release.** Change intent is captured as
  Conventional Commits or changeset files; the bot maintains a PR that bumps the version + rewrites
  the changelog; merging it tags + publishes.
- **Publish over OIDC / Trusted Publishing.** Short-lived, keyless tokens minted at job time — no
  long-lived registry secret. Enforce it once it works.
- **The first publish is manual.** Trusted Publishing attaches to an already-existing package, so it
  can't mint the token for the very first upload.
- **Promote to `master` with an ancestry check, fast-forward only.** A tag not reachable from
  `develop` must be rejected.
