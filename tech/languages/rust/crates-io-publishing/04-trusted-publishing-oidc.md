# 04 — Trusted Publishing / OIDC

Trusted Publishing lets a CI workflow publish to crates.io with a **short-lived token minted at job
time from an OIDC identity** — no long-lived `CARGO_REGISTRY_TOKEN` stored as a secret. crates.io
verifies that the request comes from a repository + workflow you explicitly authorized on the
crate's settings page, exchanges the OIDC identity for a temporary token, and that token expires
shortly after the job.

This is the default auth model for automated releases. It removes the biggest standing risk of
registry publishing: a leaked long-lived token.

## One-time setup on crates.io

Configure this on the **crate settings page** — `https://crates.io/crates/<crate>/settings`, the
**Trusted Publishing** section (a crate _owner_ only). The crate must already exist, so do this
after the first manual publish (see [03 — First manual publish](03-first-publish-manual.md)):

1. Open `https://crates.io/crates/<crate>/settings` and find **Trusted Publishing** → **Add**.
2. Fill the GitHub Actions form to match your release workflow:
   - **Repository owner / name** — `<owner>` / `<repo>`.
   - **Workflow filename** — the workflow _file_ name, e.g. `release.yml`. This is the filename,
     **not** the workflow's `name:` field (a common mix-up — if your file is `release.yml` but its
     `name:` is `release-plz`, enter `release.yml`).
   - **Environment** — leave blank unless the job declares a GitHub `environment:`; set it only
     then.
3. Save. Only jobs from that repo + workflow (+ environment, if set) can now mint a publishing
   token.

The publisher matches on **owner + repo + workflow filename (+ optional environment)** — it is
**branch-agnostic**. Changing the workflow's trigger branch (e.g. `main` → `develop`) needs **no**
reconfiguration here, as long as the workflow _file_ name and owner/repo stay the same.

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

## Require trusted publishing (enforcement)

Configuring a trusted publisher **allows** OIDC publishing but does not by itself **disable** token
publishing. The crate settings page has a separate **"Require trusted publishing for all new
versions"** checkbox (shipped in the crates.io January 2026 update). When enabled, crates.io
**rejects every publish that authenticates with an API token** — both a local `cargo login` token
and a `CARGO_REGISTRY_TOKEN` secret — so only the configured trusted publisher can push new
versions.

- **Enable it once OIDC is working.** It eliminates the long-lived-token attack surface entirely:
  even a leaked broad-scope token cannot publish the crate.
- **Tradeoff:** it disables the local token escape hatch. An emergency hand-publish then requires
  temporarily unchecking the box first, then re-checking it. It only affects _new_ versions.

The same January 2026 update also blocks the `pull_request_target` and `workflow_run` triggers from
Trusted Publishing, closing those as bypass vectors.

## When OIDC is not available

For self-hosted mirrors or registries without Trusted Publishing support, fall back to a long-lived
`CARGO_REGISTRY_TOKEN` secret with a `publish-update`-scoped, per-crate token (see
[02 — API tokens and scopes](02-api-tokens-and-scopes.md)). Treat this as the exception, not the
norm. (Note: this fallback is incompatible with _require trusted publishing_ above — enforcement
rejects token publishes.)

## Reference

- [RFC 3691 — Trusted Publishing on crates.io](https://rust-lang.github.io/rfcs/3691-trusted-publishing-cratesio.html)
- [crates.io development update (Trusted Publishing GA) — Rust Blog](https://blog.rust-lang.org/2025/07/11/crates-io-development-update-2025-07/)
- [crates.io development update (require trusted publishing) — Rust Blog, Jan 2026](https://blog.rust-lang.org/2026/01/21/crates-io-development-update/)
- [The Cargo Book — Registry authentication](https://doc.rust-lang.org/cargo/reference/registry-authentication.html)
- [`rust-lang/crates-io-auth-action`](https://github.com/rust-lang/crates-io-auth-action)
