# 03 — First manual publish

The first version of a crate must be published by hand. This chapter is the one-time bootstrap
runbook; every release after it is automated ([05 — release-plz](05-release-plz-automation.md)).

## Why the first publish can't be automated

[Trusted Publishing](04-trusted-publishing-oidc.md) is configured **against a crate that already
exists** on crates.io — you tell the crate's settings page which repository and workflow are allowed
to mint OIDC tokens for it. Before the first upload the crate does not exist, so there is nothing to
attach that trust to. Hence the first publish uses a manual, scoped token; only afterward can you
turn on OIDC and let CI take over.

## Runbook

1. **Metadata prerequisite.** Ensure `Cargo.toml` has at least `description` and a license (see
   [01 — Crate metadata](01-crate-metadata.md)). Validate — no token needed:

   ```bash
   cargo publish --dry-run
   cargo package --list
   ```

1. **Create a scoped token** at <https://crates.io/settings/tokens> (see
   [02 — API tokens and scopes](02-api-tokens-and-scopes.md)):
   - **Name:** something disposable, e.g. `<crate>-bootstrap-first-publish`.
   - **Endpoint scope:** `publish-new` **only** (the first upload creates the crate;
     `publish-update` does not apply yet).
   - **Crate scope:** the exact crate name.
   - **Expiration:** the shortest offered.

1. **Log in** and paste the token (stored in `$CARGO_HOME/credentials.toml`):

   ```bash
   cargo login
   ```

1. **Validate again** — this is the exact build the real publish will run:

   ```bash
   cargo publish --dry-run
   ```

1. **Publish** the first version:

   ```bash
   cargo publish
   ```

1. **Configure Trusted Publishing** on the now-existing crate's crates.io settings page: add the
   GitHub repository and the release workflow that will publish from now on (see
   [04 — Trusted Publishing / OIDC](04-trusted-publishing-oidc.md)).

1. **Revoke the bootstrap token** at <https://crates.io/settings/tokens>. CI mints short-lived OIDC
   tokens from here on, so the manual token is no longer needed. Keep a long-lived token only if you
   deliberately want a local escape hatch.

## After the bootstrap

- Ongoing releases flow through [release-plz](05-release-plz-automation.md): merge the release PR,
  CI tags and publishes over OIDC.
- If you ever need to publish locally again (CI down), `cargo login` with a fresh
  `publish-update`-scoped token, then use the [helper scripts](06-helper-scripts.md).

## Reference

- [The Cargo Book — Publishing a new crate](https://doc.rust-lang.org/cargo/reference/publishing.html)
