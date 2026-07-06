---
digest-of: tech/languages/rust/release-workflow-spec
last-synced: 2026-07-06
source-files:
  - README.md
  - 00-release-plz-and-branch-model.md
  - 01-trusted-publishing.md
token-estimate: 1500
---

# AGENTS

## Scope

Rust binding of the general release-workflow shelf (`tech/programming/release-workflow/`): the
`develop`/`master` branch model applied with release-plz over crates.io Trusted Publishing (OIDC).
The _workflow_ view; the sibling `crates-io-publishing/` shelf is the deeper crates.io _publishing_
reference (tokens, metadata, helper scripts, SemVer/yank) and is cross-linked, not duplicated.

## Key Points

- **release-plz runs on `develop`** (auto-detected default branch; no branch key in
  `release-plz.toml`). It opens the release PR and, on merge, tags + `cargo publish` over OIDC.
- **`master` promotion (official pattern):** run a `promote` job with `needs: release-plz` in the
  same run (a `GITHUB_TOKEN` tag push does not retrigger a standalone workflow). Read the tag from
  the action's `releases` output (`jq -r '.[0].tag'`), resolve `refs/tags/<tag>^{commit}`,
  ancestry-check it against `origin/develop`, then `git merge --ff-only` `master` onto the tag
  (create `master` at the tag on first release). Gate on `releases_created == 'true'`.
- **Auth:** `permissions: id-token: write` + release-plz's own OIDC exchange — **no
  `CARGO_REGISTRY_TOKEN`**, no `crates-io-auth-action`. Trusted publisher matches on owner + repo +
  workflow filename (`release.yml`) + optional environment — **branch-agnostic** (main→develop needs
  no crates.io change).
- **First publish is manual** (TP attaches to an existing crate). **Enable "require trusted
  publishing"** enforcement once OIDC works (rejects token publishes; disables the local escape
  hatch until toggled off).
- **Local alt:** cargo-release (imperative, no bot).

## Source Map

| Topic                                             | File                                 |
| ------------------------------------------------- | ------------------------------------ |
| Index, binding header, TL;DR                      | `README.md`                          |
| release-plz on develop + tag-based master promote | `00-release-plz-and-branch-model.md` |
| crates.io Trusted Publishing + require-TP box     | `01-trusted-publishing.md`           |

## Maintenance Notes

- Deep crates.io detail lives in `../crates-io-publishing/` — keep this shelf the workflow summary
  and link there rather than duplicating token/metadata content.
- Verify the `release-plz/action` output names (`releases_created`, `releases`) and the tag-name
  template against upstream when bumping the action version.
- General principles: `../../../programming/release-workflow/`. Platform ruleset setup:
  `../../../tools/git/branch-protection/`.
