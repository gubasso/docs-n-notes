# Runbook — set up releases for a new Bash CLI

The ordered, **once-per-project** manual steps to take a pure-Bash CLI from an empty repo to
tag-triggered releases with end-user distribution channels. Each step links to the chapter that
explains the _why_; this page is only the _what_ and _in what order_. The recurring release ritual
(every version after setup) is [06 — Release ritual](./06-release-ritual-and-alternatives.md).

Bash has no registry — **tagging is publishing** ([README](./README.md)); there is no token or
trusted-publisher step.

## Steps

1. **Scaffold the release plumbing.** Add a root `VERSION` file (one line, SemVer)
   ([00](./00-versioning-and-source-of-truth.md)); a GNU-conventions `Makefile` with
   `PREFIX`/`DESTDIR` and a reproducible `dist` target ([02](./02-makefile-gnu-standards.md)); a
   `cliff.toml` + `commitlint` hook for Conventional Commits + changelog
   ([01](./01-conventional-commits-and-changelog.md)).

2. **Create the repo and set the default branch to `develop`.** →
   [first-run enablement](../../../tools/git/branch-protection/first-run-enablement.md).

3. **Enable Actions + workflow permissions** (read/write; provenance needs `id-token: write` and
   `attestations: write` at the job level). →
   [first-run enablement](../../../tools/git/branch-protection/first-run-enablement.md).

4. **Apply branch protection** for `develop`, `master`, and tags. →
   [branch-protection/](../../../tools/git/branch-protection/).

5. **Add the release workflow** `.github/workflows/release.yml` (trigger `on: push: tags: ['v*']`:
   test → `make dist` → git-cliff notes → build-provenance → `gh release create` → OBS trigger). →
   [03 — CI release workflow](./03-ci-release-workflow.md).

6. **Cut the first release** with the tag ritual (`git-cliff --bump` → write `VERSION` → commit →
   signed `git tag -s` → `git push --follow-tags`); CI does the rest. →
   [06 — Release ritual](./06-release-ritual-and-alternatives.md).

7. **Set up distribution channels** (once): `install.sh` (checksum-verified `curl | bash`), AUR
   (`<tool>` + `<tool>-git`), and the one-time OBS sub-project + `_service` + scoped `runservice`
   token. → [04 — install.sh & AUR](./04-install-sh-and-aur.md),
   [05 — OBS multi-distro](./05-obs-multi-distro.md).

8. **Verify** the tag produced a GitHub Release with the tarball + `SHA256SUMS` + provenance, and
   that `install.sh` fetches and installs it.

## Reference

- [06 — Release ritual & alternatives](./06-release-ritual-and-alternatives.md) ·
  [first-run enablement](../../../tools/git/branch-protection/first-run-enablement.md)
