# 01 — Trusted Publishing (crates.io)

General counterpart:
[Trusted Publishing / OIDC](../../../programming/release-workflow/02-trusted-publishing-oidc.md).
Deep reference:
[`crates-io-publishing/04-trusted-publishing-oidc.md`](../crates-io-publishing/04-trusted-publishing-oidc.md).

This chapter is the workflow-level summary; the linked `crates-io-publishing/` chapter carries the
token-scope and first-publish detail.

## The auth model

release-plz mints and exchanges the crates.io OIDC token **itself** when the job has
`permissions: id-token: write`. That means:

- **No `CARGO_REGISTRY_TOKEN`** secret and **no** `rust-lang/crates-io-auth-action` step (that step
  is only for plain `cargo publish` workflows that are not release-plz).
- The token is short-lived (minted per job) and scoped — nothing long-lived lives in CI.

The trusted publisher is matched on **owner + repo + workflow filename (+ optional environment)** —
it is **branch-agnostic**, so switching the trigger from `main` to `develop` needs **no**
reconfiguration on crates.io as long as the workflow _file_ stays `release.yml` and the owner/repo
are unchanged.

## First publish is manual

Trusted Publishing attaches to an already-existing crate, so the very first version is published by
hand with a scoped, short-lived `publish-new` token, after which you configure the trusted publisher
and let CI own every release. Full runbook:
[`crates-io-publishing/03-first-publish-manual.md`](../crates-io-publishing/03-first-publish-manual.md).

## Configuring the trusted publisher

On the crate settings page (`https://crates.io/crates/<crate>/settings`, "Trusted Publishing"), add
a GitHub Actions publisher matching the workflow:

- **Repository owner / name:** `<owner>` / `<crate-repo>`.
- **Workflow filename:** `release.yml` — the file name, **not** the workflow's `name:` field.
- **Environment:** blank unless the job declares one.

## Require trusted publishing (enforcement)

The crate settings page has a **"Require trusted publishing for all new versions"** checkbox
(shipped in the crates.io January 2026 update). When enabled, crates.io **rejects every API-token
publish** — only the OIDC trusted publisher can push new versions.

- **Enable it** once OIDC is working: it removes the long-lived-token attack surface entirely.
- **Tradeoff:** it disables the local token escape hatch, so an emergency hand-publish requires
  temporarily unchecking it first. It only affects _new_ versions.

See
[`crates-io-publishing/04-trusted-publishing-oidc.md`](../crates-io-publishing/04-trusted-publishing-oidc.md)
for the citations (RFC 3691, the crates.io enforcement announcement).

## Reference

- [crates.io — Trusted Publishing](https://crates.io/docs/trusted-publishing)
- [RFC 3691 — Trusted Publishing](https://rust-lang.github.io/rfcs/3691-trusted-publishing-cratesio.html)
- [crates.io development update, Jan 2026](https://blog.rust-lang.org/2026/01/21/crates-io-development-update/)
