# First-run enablement — turning CI on after the first push

Once a new repo is pushed, the workflows won't do anything useful until the host is configured to
**allow Actions/CI to run and to write**. This is the "where do I switch the actions on" step that
sits between pushing the repo and the release automation working. Do it once per new project, then
apply the ruleset in [workflow.md](./workflow.md).

## GitHub

Settings → **Actions** → **General**:

1. **Actions permissions.** New personal repos have Actions on by default; forks and org-governed
   repos may not. Set **Allow all actions and reusable workflows** (or the org-approved subset).
2. **Workflow permissions** → **Read and write permissions.** release-plz commits the version bump
   and the `master` `promote` job pushes — both need write. The restricted (read-only) default makes
   release-plz fail.
3. Tick **Allow GitHub Actions to create and approve pull requests.** release-plz opens the release
   PR; without this it cannot.

**OIDC / Trusted Publishing** needs no repo-level switch — `permissions: id-token: write` at the job
level is what mints the OIDC token, and crates.io authorizes it via the trusted publisher you
register (workflow filename `release-plz.yml`; see
[Trusted Publishing](../../../languages/rust/release-workflow-spec/03-trusted-publishing-oidc.md)).

**Default branch.** Settings → General → set the default branch to **`develop`** (release-plz
auto-detects it).

**Protected `master`.** When you protect `master` (no human writes, linear history), keep the CI
bypass actor — `github-actions[bot]`, or a GitHub App token when `master` needs its own CI on
promotion, since a `GITHUB_TOKEN` tag push does not retrigger workflows. Apply it with
[`github/setup.sh`](github/setup.sh) or [github-web-ui.md](./github-web-ui.md); see
[workflow.md](./workflow.md).

## GitLab (gitlab.com)

Settings → **CI/CD** (and Settings → General → Visibility):

1. **Enable CI/CD** for the project (project features) and ensure a **runner** is available (shared
   runners on, or a project runner registered).
2. **Let CI write to protected branches.** For the `master` promotion push, add the pipeline
   identity (a project/group access token or the appropriate role) to **Allowed to push and merge**
   on the protected `master`, or drive promotion with a token that can push. Apply it with
   [`gitlab/setup.sh`](gitlab/setup.sh) or [gitlab-web-ui.md](./gitlab-web-ui.md).
3. **Default branch** → `develop`.

**OIDC / Trusted Publishing (crates.io, gitlab.com only).** Declare an `id_tokens` entry in the
publish job with the crates.io audience, exchange it via the crates.io API (the `CRATES_IO_ID_TOKEN`
environment variable), then `cargo publish`. Register the trusted publisher on crates.io for
**GitLab** (project path + CI config filename) rather than GitHub. Self-hosted GitLab is not yet
supported. See
[Trusted Publishing](../../../languages/rust/release-workflow-spec/03-trusted-publishing-oidc.md).

## Reference

- [Managing GitHub Actions settings for a repository](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository)
- [GitLab — Enable/configure CI/CD](https://docs.gitlab.com/ee/ci/enable_or_disable_ci.html) ·
  [GitLab OIDC id_tokens](https://docs.gitlab.com/ee/ci/secrets/id_token_authentication.html)
- [crates.io — Trusted Publishing](https://crates.io/docs/trusted-publishing)
