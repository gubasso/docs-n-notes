# 03 — Trusted Publishing / OIDC

General counterpart:
[Trusted Publishing / OIDC](../../../programming/release-workflow/02-trusted-publishing-oidc.md).

Trusted Publishing lets a CI workflow publish to crates.io with a **short-lived token minted at job
time from an OIDC identity** — no long-lived `CARGO_REGISTRY_TOKEN` stored as a secret. crates.io
verifies the request comes from a repository + workflow you explicitly authorized on the crate's
settings page, exchanges the OIDC identity for a temporary token, and that token expires shortly
after the job. This is the default auth model for automated releases; it removes the biggest
standing risk of registry publishing — a leaked long-lived token.

## First publish is manual (and why)

A trusted publisher is configured **against a crate that already exists** on crates.io: you tell the
crate's settings page which repository + workflow may mint tokens for it. Before the first upload
the crate does not exist, so there is nothing to attach that trust to. Hence the very first version
is published by hand with a scoped, short-lived `publish-new` token; only afterward do you configure
the trusted publisher and let CI own every release. The ordered steps live in the
[runbook](runbook.md#first-manual-publish).

## One-time setup on crates.io

Configure this on the **crate settings page** — `https://crates.io/crates/<crate>/settings`, the
**Trusted Publishing** section (crate _owner_ only), after the first manual publish:

1. Open the settings page and find **Trusted Publishing** → **Add**.
2. Fill the GitHub Actions form to match your **publish** workflow:
   - **Repository owner / name** — `<owner>` / `<repo>`.
   - **Workflow filename** — **`release-plz.yml`**. This is the workflow _file_ name, **not** the
     workflow's `name:` field. Our release-plz workflow file is `release-plz.yml`
     ([04](04-release-plz-config.md)); enter exactly that.
   - **Environment** — leave blank unless the job declares a GitHub `environment:`.
3. Save. Only jobs from that repo + workflow (+ environment, if set) can now mint a publishing
   token.

> **Do not register `release.yml`.** cargo-dist's generated binary-distribution workflow is
> `.github/workflows/release.yml` ([05](05-binary-distribution-cargo-dist.md)) — a **different**
> file that builds binaries and does **not** publish to crates.io. Registering it here would point
> the trusted publisher at the wrong workflow and every OIDC publish would be rejected. Register the
> release-plz file (`release-plz.yml`) only. See
> [workflow file conventions](../../../programming/release-workflow/04-workflow-file-conventions.md).

The publisher matches on **owner + repo + workflow filename (+ optional environment)** — it is
**branch-agnostic**. Changing the workflow's trigger branch (e.g. `main` → `develop`) needs **no**
reconfiguration here, as long as the workflow _file_ name and owner/repo stay the same.

## In CI — with release-plz (recommended)

release-plz performs the OIDC exchange itself. Grant the job `id-token: write` and **do not** set
`CARGO_REGISTRY_TOKEN` — there is **no** `rust-lang/crates-io-auth-action` step and no registry
token in `env`. The full workflow (and the `master` promote job) is in
[04](04-release-plz-config.md).

## In CI — with a plain `cargo publish` workflow

If you are not using release-plz, mint the short-lived token explicitly, then run `cargo publish`:

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

The action outputs a temporary token scoped to the authorized crate; it is never stored as a secret.

## GitLab CI/CD

crates.io Trusted Publishing also supports **GitLab.com** (self-hosted GitLab not yet). The job
requests a GitLab OIDC `id_token` (with the crates.io audience) and exchanges it via the crates.io
API using the `CRATES_IO_ID_TOKEN` environment variable, then runs `cargo publish`. The trusted
publisher on crates.io is configured for GitLab instead of GitHub (project path + CI config
filename). Enabling CI/CD and the OIDC token is covered in
[first-run enablement](../../../tools/git/branch-protection/first-run-enablement.md).

## Require trusted publishing (enforcement)

Configuring a trusted publisher **allows** OIDC publishing but does not by itself **disable** token
publishing. The crate settings page has a separate **"Require trusted publishing for all new
versions"** checkbox (crates.io January 2026 update). When enabled, crates.io **rejects every
publish that authenticates with an API token** — both a local `cargo login` token and a
`CARGO_REGISTRY_TOKEN` secret — so only the configured trusted publisher can push new versions.

- **Enable it once OIDC is working.** It eliminates the long-lived-token attack surface entirely.
- **Tradeoff:** it disables the local token escape hatch; an emergency hand-publish requires
  temporarily unchecking the box first. It only affects _new_ versions.

The same January 2026 update also blocks the `pull_request_target` and `workflow_run` triggers from
Trusted Publishing, closing those as bypass vectors.

## When OIDC is not available

For self-hosted mirrors or registries without Trusted Publishing, fall back to a long-lived
`CARGO_REGISTRY_TOKEN` secret with a `publish-update`-scoped, per-crate token
([02](02-api-tokens-and-scopes.md)). Treat this as the exception. (It is incompatible with _require
trusted publishing_ above — enforcement rejects token publishes.)

## Reference

- [crates.io — Trusted Publishing](https://crates.io/docs/trusted-publishing)
- [RFC 3691 — Trusted Publishing on crates.io](https://rust-lang.github.io/rfcs/3691-trusted-publishing-cratesio.html)
- [crates.io development update, Jan 2026 (enforcement + GitLab)](https://blog.rust-lang.org/2026/01/21/crates-io-development-update/)
- [`rust-lang/crates-io-auth-action`](https://github.com/rust-lang/crates-io-auth-action)
- [The Cargo Book — Registry authentication](https://doc.rust-lang.org/cargo/reference/registry-authentication.html)
