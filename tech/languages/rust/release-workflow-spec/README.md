# Rust release & publishing

The **Rust binding** of the
[general development & release principles](../../../programming/release-workflow/README.md): the
`develop`/`master` branch model and the release-PR invariant, applied with **release-plz** over
**crates.io Trusted Publishing (OIDC)**, plus crate metadata, token hygiene, helper scripts, SemVer,
and **cargo-dist** binary distribution. One unified shelf — workflow _and_ publishing reference —
with a per-new-project [runbook](runbook.md) on top.

It is deliberately not "just run `cargo publish`". That command is one step near the end; the
durable value is in the branch discipline, the review-gated release PR, the auth model, the
metadata, and the promotion mechanics around it.

## Set up a new crate

Follow the [**runbook**](runbook.md) — the ordered, per-project manual steps (repo settings,
enabling Actions, branch protection, the one-time first publish, configuring the trusted publisher,
optional cargo-dist). The numbered chapters below are the reference each step links to.

## Index

| # | Chapter                                                                  | One-line hook                                                                         |
| - | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| 0 | [Branch model & release-plz](00-branch-model-and-release-plz.md)         | `develop` integrates, `master` mirrors releases; release PR → tag → promote `master`. |
| 1 | [Crate metadata](01-crate-metadata.md)                                   | Required/recommended `Cargo.toml` fields; keeping the tarball lean.                   |
| 2 | [API tokens and scopes](02-api-tokens-and-scopes.md)                     | Endpoint + crate scopes; one narrow, per-crate token.                                 |
| 3 | [Trusted Publishing / OIDC](03-trusted-publishing-oidc.md)               | Keyless CI auth; register `release-plz.yml` (not `release.yml`); enforcement.         |
| 4 | [release-plz config & CI](04-release-plz-config.md)                      | `release-plz.toml`, the `release-plz.yml` workflow, SemVer gating.                    |
| 5 | [Binary distribution (cargo-dist)](05-binary-distribution-cargo-dist.md) | Prebuilt binaries/installers in `release.yml`, separate from the registry.            |
| 6 | [Helper scripts](06-helper-scripts.md)                                   | Portable `publish-dry` / `publish` / `release` scripts.                               |
| 7 | [SemVer, yank, rollback](07-semver-yank-rollback.md)                     | Compatibility policy; versions are immutable — fix forward.                           |

LLM agents should load [AGENTS.md](AGENTS.md) first for the digest, then the chapter that owns the
current change.

## TL;DR (the irreducible defaults)

- **release-plz runs on `develop`** (its auto-detected default branch), opens the release PR, and on
  merge tags + publishes to crates.io over OIDC.
- **Promote `master` onto the release tag** in a `needs:` job in the same run — resolve the tag from
  release-plz's `releases` output, ancestry-check against `develop`, fast-forward.
- **No `CARGO_REGISTRY_TOKEN`.** `permissions: id-token: write` + release-plz's own OIDC exchange.
- **Two workflow files, kept distinct:** `release-plz.yml` publishes source (register _this_ with
  the trusted publisher); cargo-dist's `release.yml` builds binaries.
- **The first publish is manual** — a scoped `publish-new` token, revoked once OIDC is live
  ([runbook](runbook.md#first-manual-publish)).
- **Enable "require trusted publishing"** on the crate once OIDC works.
- Keep the `.crate` lean (`exclude` denylist); published versions are immutable (yank + fix
  forward).

## Reference

- [The Cargo Book — Publishing on crates.io](https://doc.rust-lang.org/cargo/reference/publishing.html)
- [release-plz — docs](https://release-plz.dev/) ·
  [config reference](https://release-plz.dev/docs/config)
