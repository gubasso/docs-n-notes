---
digest-of: tech/languages/rust/crates-io-publishing
last-synced: 2026-07-06
source-files:
  - README.md
  - 01-crate-metadata.md
  - 02-api-tokens-and-scopes.md
  - 03-first-publish-manual.md
  - 04-trusted-publishing-oidc.md
  - 05-release-plz-automation.md
  - 06-helper-scripts.md
  - 07-semver-yank-rollback.md
  - 08-binary-distribution-cargo-dist.md
token-estimate: 1300
---

# AGENTS

## Scope

General-purpose guide for publishing any Rust crate to crates.io using the modern, low-secret setup:
CI-first releases with release-plz over Trusted Publishing (OIDC), with auth-gated helper scripts as
the local escape hatch. Language- and project-neutral; uses `my-crate` / `<owner>/<repo>`
placeholders.

## Key Points

- **Publishing model:** CI-first (release-plz + OIDC, no stored secret) is the default; local helper
  scripts are the escape hatch. The **first publish is always manual** — Trusted Publishing can only
  be attached to an already-existing crate.
- **Metadata:** `description` and a license are **required** (publish rejected without them);
  `repository` warns; `categories` must match canonical slugs or the publish fails. Validate with
  `cargo publish --dry-run` (no token needed).
- **Package contents:** Cargo ships the whole working tree by default; keep the `.crate` lean —
  `src/` + `Cargo.toml`/`Cargo.lock` + `README`/`LICENSE` only. Project docs belong in the repo /
  docs.rs, not the tarball. Prefer `exclude` (denylist) over `include`, because `README`/`LICENSE`
  are not auto-included when `license` is an SPDX expression. Hard limit is 10 MB; for a binary
  crate no consumer reads the tarball at all.
- **Tokens:** endpoint scopes are `publish-new`, `publish-update`, `yank`, `change-owners`, `legacy`
  (avoid `legacy`); plus optional crate scopes. Best practice = one narrow, per-crate token,
  `publish-new` for the first upload, shortest expiry, revoked once OIDC is live.
- **OIDC:** release-plz mints the short-lived token itself with `permissions: id-token: write` and
  **no** `CARGO_REGISTRY_TOKEN`; plain `cargo publish` workflows use
  `rust-lang/crates-io-auth-action` instead.
- **release-plz:** opens a review-gated release PR (bump + changelog); merge publishes.
  `semver_check = true` gates public-API compatibility for libraries. `cargo-release`
  (`cargo release <level> --execute`, dry-run by default, no review PR) is the operator-driven
  **local alternative** for maintainers who want an explicit local release command; release-plz is
  the CI-first default.
- **Helper scripts:** the auth check lives in the project's own `publish` script, checks that auth
  is _configured_ (never that a token is valid), and never echoes a token value. `publish-dry` needs
  no auth.
- **Immutability:** published versions can only be **yanked**, never deleted or overwritten; recover
  by fixing forward with a new patch. `cargo-semver-checks` applies to library crates only (binaries
  have no public API).
- **Binary distribution:** `dist` (cargo-dist) ships prebuilt binaries to GitHub Releases — separate
  from crates.io source publishing; its workflow is generated, regenerate with `dist generate`.

## Source Map

| Topic                                    | File                                   |
| ---------------------------------------- | -------------------------------------- |
| Index + publishing model + defaults      | `README.md`                            |
| Cargo.toml required/recommended fields   | `01-crate-metadata.md`                 |
| Token endpoint + crate scopes, hygiene   | `02-api-tokens-and-scopes.md`          |
| One-time manual first-publish runbook    | `03-first-publish-manual.md`           |
| Trusted Publishing / OIDC in CI          | `04-trusted-publishing-oidc.md`        |
| release-plz release-PR workflow + config | `05-release-plz-automation.md`         |
| Portable publish/dry-run/release scripts | `06-helper-scripts.md`                 |
| SemVer policy, yank, fix-forward         | `07-semver-yank-rollback.md`           |
| cargo-dist binary distribution           | `08-binary-distribution-cargo-dist.md` |

## Maintenance Notes

- Regenerate when any chapter changes or a new one is added.
- External auth model is perishable: re-verify the release-plz OIDC flow, the
  `crates-io-auth-action` version, and Trusted Publishing setup against upstream docs on a cadence
  (RFC 3691, release-plz docs, crates.io blog).
- Supersedes the former single-file `publish-crates-io.md` and `cargo-release-setup.md`. The old
  `cargo-release-setup.md` defaulted to `cargo-release` with a wrong `publish-update` first-publish
  scope and a long-lived token instead of OIDC; here release-plz + OIDC is the default and
  `cargo-release` is documented only as the operator-driven local alternative (see chapter 05).
