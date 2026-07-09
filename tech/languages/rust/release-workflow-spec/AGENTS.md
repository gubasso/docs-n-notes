---
digest-of: tech/languages/rust/release-workflow-spec
last-synced: 2026-07-09
source-files:
  - README.md
  - 00-branch-model-and-release-plz.md
  - 01-crate-metadata.md
  - 02-api-tokens-and-scopes.md
  - 03-trusted-publishing-oidc.md
  - 04-release-plz-config.md
  - 05-binary-distribution-cargo-dist.md
  - 06-helper-scripts.md
  - 07-semver-yank-rollback.md
  - runbook.md
token-estimate: 2600
---

# AGENTS

## Scope

Rust binding of the general release-workflow shelf (`tech/programming/release-workflow/`): the
`develop`/`master` branch model applied with release-plz over crates.io Trusted Publishing (OIDC),
plus crate metadata, token hygiene, helper scripts, SemVer/yank, and cargo-dist binary distribution.
One unified shelf (workflow + publishing); the per-new-project manual steps are in `runbook.md`.
Supersedes the former split between `release-workflow-spec/` and `crates-io-publishing/` (now
merged).

## Key Points

- **release-plz runs on `develop`** (auto-detected default branch; no branch key in
  `release-plz.toml`). It opens the release PR and, on merge, tags + `cargo publish` over OIDC.
- **`master` promotion (official pattern):** run a `promote` job with `needs: release-plz` in the
  same run (a `GITHUB_TOKEN` tag push does not retrigger a standalone workflow). Read the tag from
  the action's `releases` output (`jq -r '.[0].tag'`), ancestry-check against `origin/develop`, then
  `git merge --ff-only` `master` onto the tag. Gate on `releases_created == 'true'`.
- **Auth:** `permissions: id-token: write` + release-plz's own OIDC exchange — **no
  `CARGO_REGISTRY_TOKEN`**, no `crates-io-auth-action`. crates.io TP covers GitHub Actions and
  **GitLab.com** (self-hosted not yet).
- **Workflow filenames (critical):** the publish workflow is **`release-plz.yml`** and _that_ is the
  filename registered with the crates.io trusted publisher — branch-agnostic. cargo-dist's generated
  binary-build workflow is **`release.yml`**, a different file that does **not** publish to
  crates.io and must **not** be registered. Keep the two files distinct.
- **First publish is manual** (TP attaches to an existing crate); use a scoped `publish-new` token,
  revoked once OIDC is live. **Enable "require trusted publishing"** once OIDC works.
- **Metadata:** `description` + a license are required (publish rejected without them); keep the
  `.crate` lean with an `exclude` denylist (README/LICENSE are not auto-included under an SPDX
  license). **Tokens:** one narrow, per-crate token, shortest expiry. **Helper scripts:** the auth
  check lives only in the project `publish` script (configuration check, never validates/echoes a
  token). **Immutability:** versions can only be yanked; fix forward. `cargo-semver-checks` applies
  to libraries only. **cargo-dist:** `cargo install cargo-dist`; `dist init`/`dist generate`;
  shell + PowerShell + Homebrew-tap installers; cargo-binstall works for free; AUR/OBS are
  downstream/manual.
- **Local alt:** cargo-release (imperative, no bot; dry-run by default).

## Source Map

| Topic                                                      | File                                   |
| ---------------------------------------------------------- | -------------------------------------- |
| Index, TL;DR, setup pointer                                | `README.md`                            |
| Branch model + tag-based `master` promote (flow + example) | `00-branch-model-and-release-plz.md`   |
| Cargo.toml required/recommended fields, lean tarball       | `01-crate-metadata.md`                 |
| Token endpoint + crate scopes, hygiene                     | `02-api-tokens-and-scopes.md`          |
| Trusted Publishing / OIDC, filenames, enforcement, GitLab  | `03-trusted-publishing-oidc.md`        |
| release-plz.toml + `release-plz.yml` CI + SemVer gate      | `04-release-plz-config.md`             |
| cargo-dist binaries in `release.yml`, downstream channels  | `05-binary-distribution-cargo-dist.md` |
| Portable publish/dry-run/release scripts                   | `06-helper-scripts.md`                 |
| SemVer policy, yank, fix-forward                           | `07-semver-yank-rollback.md`           |
| Per-new-project ordered manual steps                       | `runbook.md`                           |

## Maintenance Notes

- General principles: `../../../programming/release-workflow/` (incl.
  `04-workflow-file-conventions.md` for the `release-plz.yml` vs `release.yml` split). Platform
  ruleset + first-run enablement: `../../../tools/git/branch-protection/`.
- External auth model is perishable: re-verify the release-plz OIDC flow, `crates-io-auth-action`
  version, cargo-dist CLI/filenames, and Trusted Publishing status (incl. GitLab) against upstream
  on a cadence (RFC 3691, release-plz docs, cargo-dist book, crates.io blog).
- Standardize on `develop`/`master`; flag any reintroduced `main`.
