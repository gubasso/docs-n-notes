# 02 — Trusted Publishing / OIDC

The auth convergence point across ecosystems: **Trusted Publishing** replaces long-lived registry
tokens with short-lived, keyless credentials minted at job time from the CI provider's OIDC token.
crates.io, PyPI, and npm all support it, and the shape is the same everywhere.

## How it works

1. The CI job requests an **OIDC identity token** from the platform (GitHub Actions / GitLab CI/CD).
   On GitHub this needs `permissions: id-token: write`.
1. The job presents that token to the registry.
1. The registry checks it against a **trusted publisher** you configured on the package settings —
   matching on repository owner, repository name, workflow filename, and an optional environment.
1. On a match, the registry mints a **short-lived, scoped token** (minutes, not forever) and the
   publish proceeds. Nothing long-lived is ever stored in CI.

The trusted-publisher match is keyed on **repo + workflow file (+ environment)** — it is
**branch-agnostic**. Switching your trigger branch (e.g. `main` → `develop`) does **not** require
reconfiguring the publisher, as long as the workflow _filename_ and owner/repo stay the same.

## Per-registry status

| Registry      | Trusted Publishing                                                                         | Publish mechanism                                                                                                                                                    |
| ------------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **crates.io** | GA 2025 (RFC 3691). GitHub Actions + GitLab.com CI/CD; self-hosted GitLab not yet.         | release-plz mints + exchanges the token itself; plain `cargo publish` uses `rust-lang/crates-io-auth-action` (GitHub) or the `CRATES_IO_ID_TOKEN` exchange (GitLab). |
| **PyPI**      | GA since 2023.                                                                             | `pypa/gh-action-pypi-publish` or `uv publish` (both do the OIDC exchange).                                                                                           |
| **npm**       | GA 2025-07-31. Requires npm CLI ≥ 11.5.1; provenance attestations generated automatically. | `npm publish` with OIDC configured — no `NPM_TOKEN`.                                                                                                                 |

## Enforcement — require trusted publishing

Configuring a trusted publisher **allows** OIDC publishing but does not, by itself, **disable**
token publishing. Registries increasingly offer an enforcement switch that rejects any token-based
publish so only OIDC can push new versions:

- **crates.io** shipped a per-crate _"Require trusted publishing for all new versions"_ setting
  (crate settings page) in the January 2026 update — once enabled, API-token publishes are rejected.

Enable enforcement once OIDC is working: it eliminates the long-lived-token attack surface entirely.
The one tradeoff is that it disables any local token escape hatch — an emergency hand-publish then
requires temporarily turning enforcement off. It only affects _new_ versions.

## Fallback

When OIDC is unavailable (registry or platform doesn't support it, or CI is down), fall back to a
long-lived token: a local `cargo login` / `npm login` / `~/.pypirc`, or a CI secret. Treat this as
the exception, and scope + expire the token tightly.

## Reference

- [crates.io — Trusted Publishing](https://crates.io/docs/trusted-publishing) ·
  [RFC 3691](https://rust-lang.github.io/rfcs/3691-trusted-publishing-cratesio.html) ·
  [crates.io update, Jan 2026 (enforcement)](https://blog.rust-lang.org/2026/01/21/crates-io-development-update/)
- [PyPI — Trusted Publishers](https://docs.pypi.org/trusted-publishers/) ·
  [pypa/gh-action-pypi-publish](https://github.com/pypa/gh-action-pypi-publish)
- [npm Trusted Publishing GA (2025-07-31)](https://github.blog/changelog/2025-07-31-npm-trusted-publishing-with-oidc-is-generally-available/)
