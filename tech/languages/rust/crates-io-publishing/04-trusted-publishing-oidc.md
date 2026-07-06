# 04 — Trusted Publishing / OIDC

Trusted Publishing lets a CI workflow publish to crates.io with a **short-lived token minted at job
time from an OIDC identity** — no long-lived `CARGO_REGISTRY_TOKEN` stored as a secret. crates.io
verifies that the request comes from a repository + workflow you explicitly authorized on the
crate's settings page, exchanges the OIDC identity for a temporary token, and that token expires
shortly after the job.

This is the default auth model for automated releases. It removes the biggest standing risk of
registry publishing: a leaked long-lived token.

## One-time setup on crates.io

On the crate's settings page (the crate must already exist — see
[03 — First manual publish](03-first-publish-manual.md)), add a Trusted Publishing config naming:

- the **repository** (`<owner>/<repo>`), and
- the **workflow** file that is allowed to publish (e.g. `release-plz.yml`).

Optionally restrict to a GitHub **environment**. Only jobs from that repo + workflow can then mint a
publishing token.

## In CI — with release-plz (recommended)

release-plz performs the OIDC exchange itself. Grant the job `id-token: write` and **do not** set
`CARGO_REGISTRY_TOKEN`:

```yaml
permissions:
  contents: write
  pull-requests: write
  id-token: write        # lets the job mint the OIDC token

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

release-plz mints and exchanges the OIDC token with crates.io on its own, so there is **no**
`rust-lang/crates-io-auth-action` step and **no** registry token in `env`. See
[05 — release-plz automation](05-release-plz-automation.md) for the rest of the workflow.

## In CI — with a plain `cargo publish` workflow

If you are not using release-plz, mint the short-lived token explicitly with
[`rust-lang/crates-io-auth-action`](https://github.com/rust-lang/crates-io-auth-action), then run
`cargo publish`:

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: actions/checkout@v4
  - uses: rust-lang/crates-io-auth-action@v1
    id: auth
  - run: cargo publish
    env:
      CARGO_REGISTRY_TOKEN: ${{ steps.auth.outputs.token }}
```

The action outputs a temporary token scoped to the authorized crate; it is never stored as a
repository secret.

## When OIDC is not available

For self-hosted mirrors or registries without Trusted Publishing support, fall back to a long-lived
`CARGO_REGISTRY_TOKEN` secret with a `publish-update`-scoped, per-crate token (see
[02 — API tokens and scopes](02-api-tokens-and-scopes.md)). Treat this as the exception, not the
norm.

## Reference

- [RFC 3691 — Trusted Publishing on crates.io](https://rust-lang.github.io/rfcs/3691-trusted-publishing-cratesio.html)
- [crates.io development update (Trusted Publishing GA) — Rust Blog](https://blog.rust-lang.org/2025/07/11/crates-io-development-update-2025-07/)
- [The Cargo Book — Registry authentication](https://doc.rust-lang.org/cargo/reference/registry-authentication.html)
- [`rust-lang/crates-io-auth-action`](https://github.com/rust-lang/crates-io-auth-action)
