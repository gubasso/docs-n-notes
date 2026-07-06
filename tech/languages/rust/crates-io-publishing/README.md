# Publishing Rust crates on crates.io

A general-purpose runbook for publishing any Rust crate to [crates.io](https://crates.io), built
around the modern, low-secret setup: **CI-first releases with
[release-plz](https://release-plz.dev/) over crates.io
[Trusted Publishing (OIDC)](04-trusted-publishing-oidc.md)**, with a small set of auth-gated
[helper scripts](06-helper-scripts.md) as the local escape hatch.

It is deliberately not "just run `cargo publish`". That command is one step near the end; the
durable value is in the metadata, token hygiene, auth model, and automation around it.

## Publishing model

Two paths, one recommended and one for when CI is unavailable:

- **CI-first (recommended).** release-plz opens a "release PR" that bumps the version and updates
  the changelog + `Cargo.toml` + `Cargo.lock`. Merging that PR tags the release and publishes
  automatically. Auth is a short-lived OIDC token minted at job time — **no long-lived secret**. See
  [05 — release-plz automation](05-release-plz-automation.md) and
  [04 — Trusted Publishing / OIDC](04-trusted-publishing-oidc.md).
- **Local (escape hatch).** Run the [helper scripts](06-helper-scripts.md) by hand with a long-lived
  token from `cargo login`. Used for the mandatory first publish and whenever CI is down.

The **first version is always published manually** — Trusted Publishing can only be configured
against a crate that already exists, so it cannot mint the token for the very first upload. After
that one-time bootstrap, CI owns every release.

## How to use this shelf

1. Fill in [01 — Crate metadata](01-crate-metadata.md) — without `description` + a license,
   crates.io rejects the publish outright.
1. Create a scoped token following [02 — API tokens and scopes](02-api-tokens-and-scopes.md).
1. Run the [03 — First manual publish](03-first-publish-manual.md) runbook once.
1. Wire CI with [04 — Trusted Publishing / OIDC](04-trusted-publishing-oidc.md) and
   [05 — release-plz automation](05-release-plz-automation.md).
1. Optionally add the [06 — Helper scripts](06-helper-scripts.md) for local operators.
1. Learn the [07 — SemVer, yank, and rollback](07-semver-yank-rollback.md) guarantees before you cut
   versions.
1. If you ship prebuilt binaries, see
   [08 — Binary distribution (cargo-dist)](08-binary-distribution-cargo-dist.md).

LLM agents should load [AGENTS.md](AGENTS.md) first for the digest, then read the chapter that owns
the current change.

## Index

| # | Chapter                                                                  | One-line hook                                                            |
| - | ------------------------------------------------------------------------ | ------------------------------------------------------------------------ |
| 1 | [Crate metadata](01-crate-metadata.md)                                   | Required/recommended `Cargo.toml` fields, plus keeping the tarball lean. |
| 2 | [API tokens and scopes](02-api-tokens-and-scopes.md)                     | Endpoint + crate scopes, least privilege, one narrow token per crate.    |
| 3 | [First manual publish](03-first-publish-manual.md)                       | The one-time bootstrap runbook and why it can't be automated.            |
| 4 | [Trusted Publishing / OIDC](04-trusted-publishing-oidc.md)               | Short-lived CI auth with no stored secret.                               |
| 5 | [release-plz automation](05-release-plz-automation.md)                   | Release-PR workflow, config, and SemVer gating.                          |
| 6 | [Helper scripts](06-helper-scripts.md)                                   | Portable `publish-dry` / `publish` / `release` scripts.                  |
| 7 | [SemVer, yank, rollback](07-semver-yank-rollback.md)                     | Compatibility policy and how to recover from a bad release.              |
| 8 | [Binary distribution (cargo-dist)](08-binary-distribution-cargo-dist.md) | Prebuilt binaries/installers, separate from the registry.                |

## Defaults

- Publish over CI + Trusted Publishing; keep long-lived tokens only for the local escape hatch.
- One narrow, per-crate token — `publish-new` for the first upload, revoked once OIDC is live.
- Keep the published `.crate` lean — ship build inputs + `README`/`LICENSE`, exclude docs and dev
  tooling; project docs live in the repo. Prefer `exclude` over `include`.
- Never let an auth check live anywhere but the project's own publish script; it checks that auth is
  _configured_, never that a token is _valid_, and never echoes a token value.
- A published version is immutable — you can only [yank](07-semver-yank-rollback.md), never delete
  or overwrite. Fix forward with a new patch.

## Reference

- [The Cargo Book — Publishing on crates.io](https://doc.rust-lang.org/cargo/reference/publishing.html)
- [The Cargo Book — Registry authentication](https://doc.rust-lang.org/cargo/reference/registry-authentication.html)
