# Runbook — set up releases for a new Rust crate

The ordered, **once-per-project** manual steps to take a crate from an empty repo to CI-automated
releases over Trusted Publishing, with optional prebuilt-binary distribution. Each step links to the
chapter that explains the _why_; this page is only the _what_ and _in what order_.

Everyday releases after setup are not here — those are just "merge the release PR"
([00](00-branch-model-and-release-plz.md)).

## Prerequisites

- The crate is scaffolded (`Cargo.toml` + `src/`) and pushed to a GitHub or GitLab repo.
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/) — release-plz reads
  them.

## Steps

1. **Metadata gate** (no auth needed). Ensure `Cargo.toml` has at least `description` and a
   `license`; add `repository`, `keywords`, `categories`, and an `exclude` denylist. Validate:

   ```bash
   cargo publish --dry-run
   cargo package --list
   ```

   → [01 — Crate metadata](01-crate-metadata.md).

2. **Create the repo and set the default branch to `develop`.** release-plz auto-detects it. →
   [first-run enablement](../../../tools/git/branch-protection/first-run-enablement.md).

3. **Enable Actions + workflow permissions.**
   - GitHub: Settings → Actions → General → allow Actions; **Workflow permissions → Read and
     write**; tick **Allow GitHub Actions to create and approve pull requests** (release-plz opens
     the release PR).
   - GitLab: enable CI/CD; allow the pipeline to run; configure the OIDC `id_token`.

   → [first-run enablement](../../../tools/git/branch-protection/first-run-enablement.md).

4. **Apply branch protection** for `develop`, `master`, and tags — `master` written only by CI (keep
   the CI bypass actor in place _before_ you protect it), linear history, tag protection. →
   [branch-protection/](../../../tools/git/branch-protection/) (`github-cli.md` / `gitlab-cli.md`).

5. **First manual publish** — see the section below.

6. **Configure the trusted publisher** on `https://crates.io/crates/<crate>/settings` → Trusted
   Publishing: owner/repo + **workflow filename `release-plz.yml`** (not `release.yml`), environment
   blank. → [03 — Trusted Publishing / OIDC](03-trusted-publishing-oidc.md).

7. **Revoke the bootstrap token** at <https://crates.io/settings/tokens>. CI mints short-lived OIDC
   tokens from now on. → [02 — API tokens and scopes](02-api-tokens-and-scopes.md).

8. **Add release-plz.** Commit `release-plz.toml` and `.github/workflows/release-plz.yml` (the
   release-plz job with `id-token: write` and no `CARGO_REGISTRY_TOKEN`, plus the `master` `promote`
   job). → [04 — release-plz config](04-release-plz-config.md),
   [00 — Branch model](00-branch-model-and-release-plz.md).

9. **(Optional) Binary distribution.** If the crate ships prebuilt binaries:

   ```bash
   cargo install cargo-dist
   dist init          # writes dist-workspace.toml + .github/workflows/release.yml
   ```

   Choose shell / PowerShell / Homebrew-tap installers; commit `dist-workspace.toml` and the
   generated `release.yml` (a **separate** file from `release-plz.yml`). `cargo-binstall` then works
   from the first cargo-dist Release. →
   [05 — Binary distribution](05-binary-distribution-cargo-dist.md).

10. **(Optional) Enable "require trusted publishing"** on the crate once an OIDC release has
    succeeded, to reject all token publishes. →
    [03 — Trusted Publishing / OIDC](03-trusted-publishing-oidc.md).

11. **Verify end-to-end.** Merge a `feat:` to `develop` → merge the release PR release-plz opens →
    confirm: tag `vX.Y.Z` created, crates.io has the version, `master` fast-forwarded to the tag,
    and (if enabled) cargo-dist attached binaries to the GitHub Release. →
    [branch-protection/workflow.md](../../../tools/git/branch-protection/workflow.md).

## First manual publish

Trusted Publishing attaches to a crate that **already exists**
([03](03-trusted-publishing-oidc.md)), so the very first version is published by hand, once:

1. **Validate** (no token): `cargo publish --dry-run` and `cargo package --list`.
2. **Create a scoped token** at <https://crates.io/settings/tokens>
   ([02](02-api-tokens-and-scopes.md)):
   - Name: disposable, e.g. `<crate>-bootstrap-first-publish`.
   - Endpoint scope: **`publish-new` only** (the first upload creates the crate).
   - Crate scope: the exact crate name. Expiration: the shortest offered.
3. **Log in** and paste the token: `cargo login` (stored in `$CARGO_HOME/credentials.toml`).
4. **Validate again** — the exact build the publish will run: `cargo publish --dry-run`.
5. **Publish**: `cargo publish`.

Then return to step 6 above (configure the trusted publisher) and step 7 (revoke this token).

## Reference

- [00 — Branch model & release-plz](00-branch-model-and-release-plz.md) ·
  [03 — Trusted Publishing / OIDC](03-trusted-publishing-oidc.md) ·
  [first-run enablement](../../../tools/git/branch-protection/first-run-enablement.md)
