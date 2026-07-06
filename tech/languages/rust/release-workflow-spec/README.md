# Rust Release Workflow Spec

The **Rust binding** of the
[general development & release principles](../../../programming/release-workflow/README.md). It
applies the `develop`/`master` branch model and the release-PR invariant with **release-plz** over
**crates.io Trusted Publishing (OIDC)**. Every chapter links back to its general counterpart.

For the deeper crates.io reference — token scopes, crate metadata, helper scripts, SemVer/yank — see
the sibling [`crates-io-publishing/`](../crates-io-publishing/) shelf. This shelf is the _workflow_
view (branch model + release-plz + `master` promotion); that one is the _publishing_ reference. They
cross-link rather than duplicate.

## Index

| # | Chapter                                                          | General principle                                                                                                                                               |
| - | ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0 | [release-plz & branch model](00-release-plz-and-branch-model.md) | [branch model](../../../programming/release-workflow/00-branch-model.md) + [release automation](../../../programming/release-workflow/01-release-automation.md) |
| 1 | [Trusted Publishing](01-trusted-publishing.md)                   | [Trusted Publishing / OIDC](../../../programming/release-workflow/02-trusted-publishing-oidc.md)                                                                |

## TL;DR

- **release-plz runs on `develop`** (its auto-detected default branch), opens the release PR, and on
  merge tags + publishes to crates.io over OIDC.
- **Promote `master` onto the release tag** in a `needs:` job in the same run (a `GITHUB_TOKEN` tag
  push does not retrigger a standalone workflow) — resolve the tag from release-plz's `releases`
  output, ancestry-check it against `develop`, fast-forward.
- **No `CARGO_REGISTRY_TOKEN`.** `permissions: id-token: write` + release-plz's own OIDC exchange.
- **Enable "require trusted publishing"** on the crate settings once OIDC works.
- **First publish is manual** — see
  [`crates-io-publishing/03-first-publish-manual.md`](../crates-io-publishing/03-first-publish-manual.md).
