# 01 — Release automation

Every modern ecosystem has converged on the same release shape: a bot turns accumulated change
intent into a **release PR**, and merging that PR is the release. The tool differs per language (see
[03 — Tooling by ecosystem](./03-tooling-by-ecosystem.md)); the invariant does not.

## The release-PR invariant

1. **Capture change intent.** Either **Conventional Commits** (release-plz, release-please,
   python-semantic-release) or explicit **changeset files** authored per PR (Changesets).
2. **The bot opens/maintains a release PR.** It bumps the version and rewrites the changelog from
   the accumulated intent, and keeps that PR up to date as more work lands on `develop`.
3. **Merging the release PR is the human gate.** Nothing is published until a maintainer merges it —
   this removes the manual bump + changelog toil without letting automation publish behind your
   back.
4. **On merge: tag + changelog + registry publish.** The tool tags the release, finalizes the
   changelog, and publishes to the package registry (see
   [02 — Trusted Publishing / OIDC](./02-trusted-publishing-oidc.md) for auth).
5. **Promote `master`.** CI fast-forwards the release branch onto the new tag
   ([00 — Branch model](./00-branch-model.md)).

```text
commits / changesets on develop
        │
        ▼
  bot opens "release PR"  ◀── stays current as more work lands
   (version bump + changelog)
        │  maintainer merges  ← the release gate
        ▼
  tag vX.Y.Z + registry publish (OIDC)
        │
        ▼
  CI promotes master to the tag
```

## Source of truth

The version has two roles, kept distinct. The **authoring source of truth** is the committed version
in the repo — `Cargo.toml`, `package.json`, `pyproject.toml`, or a `VERSION` file — bumped in place
by the release tool. The **published record** is the annotated `vX.Y.Z` tag, cut to match it. The
committed version leads; the tag mirrors it. Pick a tool that can bump _that_ committed file (a tool
whose updater cannot is the wrong tool). See
[Version source of truth](../design-decisions/version-source-of-truth.md).

## SemVer

Versions follow [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`. Conventional-commit
types map to bumps — `fix:` → patch, `feat:` → minor, `feat!:` / `BREAKING CHANGE:` → major. Tools
that understand a public API (e.g. `cargo-semver-checks` for Rust libraries) can gate the bump
against the actual API delta; binaries have no public API to check but still version semantically.

A published version is **immutable** — you cannot overwrite or delete it, only mark it withdrawn
(yank / deprecate). Recover from a bad release by **fixing forward** with a new patch, never by
re-publishing a version.

## Changelog

Keep a machine-generated `CHANGELOG.md` in [Keep a Changelog](https://keepachangelog.com/) form,
derived from Conventional Commits or changeset files. The release PR is where the changelog is
reviewed before it becomes public — treat it as part of the release, not an afterthought.

## Conventional Commits

[Conventional Commits](https://www.conventionalcommits.org/) is the substrate most of these tools
read: `type(scope): summary`, with `!` or a `BREAKING CHANGE:` footer for majors. Enforce it with a
commit-lint hook (commitizen, commitlint) so the automated bump + changelog are trustworthy.
Changesets is the exception — it captures intent in per-PR changeset files instead, trading commit
discipline for an explicit, reviewable statement of "what changes and by how much".

## The first release is manual

Trusted Publishing attaches to an **already-existing** package, so it cannot mint the token for the
very first upload. Do the first publish by hand with a scoped, short-lived token, configure Trusted
Publishing against the now-existing package, then let CI own every subsequent release. See
[02 — Trusted Publishing / OIDC](./02-trusted-publishing-oidc.md).

## Reference

- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
