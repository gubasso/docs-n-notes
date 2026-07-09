# 04 — release-plz configuration & CI

[release-plz](https://release-plz.dev/) automates the release cycle: it watches the default branch,
opens a **release PR** that bumps versions and updates the changelog, and — on merge — tags the
release and publishes to crates.io. Combined with
[Trusted Publishing](./03-trusted-publishing-oidc.md) it needs no stored registry token.

## The release-PR workflow

1. Merge feature work to the default branch.
2. release-plz opens or updates a **release PR** containing the version bump, changelog entries, and
   updated `Cargo.toml` / `Cargo.lock`.
3. Review the PR like any other change; merge it when ready.
4. On merge, release-plz tags the release and publishes the new version.

The release PR is the human control point — nothing is published until you merge it. This keeps
automation from surprising you while removing the manual bump + changelog toil.

## Configuration — `release-plz.toml`

Conservative defaults for a single crate:

```toml
# See https://release-plz.dev/docs/config for all options.
[workspace]
changelog_update = true   # maintain CHANGELOG.md from conventional commits
release_always   = false  # release only when there is something to release
publish          = true   # publish to crates.io on release-PR merge
semver_check     = true   # gate public-API compatibility (see chapter 07)
```

Per-crate overrides go in a `[[package]]` table — e.g. to opt a workspace member out of publishing:

```toml
[[package]]
name    = "internal-helper"
publish = false
```

## CI workflow

Wire release-plz into GitHub Actions with OIDC auth (no `CARGO_REGISTRY_TOKEN`). Save this as
**`.github/workflows/release-plz.yml`** — that filename is what you register with the crates.io
trusted publisher ([03](./03-trusted-publishing-oidc.md)), and keeping it distinct from cargo-dist's
`release.yml` avoids the collision described in
[workflow file conventions](../../../programming/release-workflow/04-workflow-file-conventions.md):

```yaml
name: release-plz

on:
  push:
    branches: [develop]

permissions:
  contents: write
  pull-requests: write
  id-token: write

jobs:
  release-plz:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: release-plz/action@v0.5
        with:
          command: release-plz
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

See [03 — Trusted Publishing / OIDC](./03-trusted-publishing-oidc.md) for why `id-token: write` and
no registry token are all the auth this needs.

> **Branch model.** release-plz auto-detects the default branch; the example runs on `develop`
> (integration + release trigger). To keep a `master` release branch as a mirror of the latest
> published version, add a `promote` job that fast-forwards `master` onto the release tag. The
> [branch model & `master` promotion](./00-branch-model-and-release-plz.md) shows the full `develop`
> → tag → promote-`master` wiring; the
> [general principles](../../../programming/release-workflow/00-branch-model.md) explain the model.

## Local operator commands

release-plz can also be driven by hand (it does **not** publish from these — it prepares the
release):

```bash
release-plz update       # bump versions + changelog locally
release-plz release-pr   # open/refresh the release PR
```

Publishing still happens on the release-PR merge (CI), or manually via `cargo publish` when CI is
unavailable.

## Local alternative: cargo-release

release-plz is the default; [`cargo-release`](https://github.com/crate-ci/cargo-release) is the
operator-driven local alternative for a maintainer who wants an explicit local release command with
no automation PR. It bumps the version, tags, and publishes in one step, and is **dry-run by
default** — nothing happens without `--execute`:

```bash
cargo release patch            # dry-run: show what a patch release would do
cargo release patch --execute  # bump + tag + publish directly (no review PR)
```

Because it publishes directly rather than through a reviewed release PR, it still needs
[configured auth](./02-api-tokens-and-scopes.md) (a local `cargo login` token, or OIDC in CI).
Choose it over release-plz only when you deliberately want the local, no-bot workflow; for CI-first
releases, prefer release-plz.

## SemVer gating

With `semver_check = true`, release-plz runs [`cargo-semver-checks`](./07-semver-yank-rollback.md)
on library crates and picks a version bump consistent with the public-API delta. Binary-only crates
have no public API to check.

## Reference

- [release-plz — documentation](https://release-plz.dev/)
- [release-plz — configuration reference](https://release-plz.dev/docs/config)
