# Branch Protection & CI-Driven Release — Workflow

Specification for protecting `master`/`main`, restricting development to `develop`, and promoting to
`main` **only** via CI on a semver tag.

Step-by-step runbooks (pick one per platform):

- [github-web-ui](github-web-ui.md) — GitHub, point-and-click.
- [github-cli](github-cli.md) — GitHub, `gh` + JSON payloads.
- [gitlab-web-ui](gitlab-web-ui.md) — GitLab, point-and-click.
- [gitlab-cli](gitlab-cli.md) — GitLab, `glab` + scripts.

Related:

- [feature-lifecycle](../feature-lifecycle.md)
- [rebase-workflow](../rebase-workflow.md)
- [github-actions-ci-cd](../../../infra/devops/github-actions-ci-cd.md)

---

## Strategy

- `main` — release branch. **No human writes.** Only the CI service actor pushes, triggered by a
  semver tag on `develop`.
- `develop` — integration branch. Feature branches merge here via PR/MR with review + green CI.
- Feature branches — short-lived, merged into `develop`.
- Release — maintainer tags `vX.Y.Z` on `develop` → CI verifies ancestry → fast-forwards `main` to
  the tag → publishes the release.

## Core concepts

### Bypass actor / allowed pusher

The only identity that may write to `main`. Use a GitHub App, `github-actions[bot]`, or a GitLab
Project Access Token. **Never a human user.**

- GitHub: `github-actions[bot]` is the default (app id **15368**).
- GitHub, for CI-on-`main`-after-promotion: use a GitHub App token — pushes via `GITHUB_TOKEN` do
  **not** retrigger workflows.
- GitLab Premium/Ultimate: allow-list the bot user of a Project Access Token.
- GitLab Free: relies on the CI job-token push toggle (17.2+) or a Deploy Token — it cannot restrict
  push to a specific user.

### Tag protection

If anyone can push a `v*` tag, anyone can trigger a release. Protect tags too — restrict
create/delete/update to maintainers (or CI).

### Linear history

Required on `main` so CI can only fast-forward. Matches the "promote to the tag" model: no merge
commits, no rewrites.

## Prerequisites

- Repo admin / Maintainer access.
- CI has run at least once so required status-check names exist.
- Bypass actor / service identity exists **before** you turn protection on — otherwise `main`
  becomes unreleasable.
- For CLI runbooks: `gh` / `glab` authenticated, `jq` installed.

## Local guardrail (optional)

Add `master` / `main` to the `no-commit-to-branch` hook in `.pre-commit-config.yaml` so accidental
local commits fail before they reach the remote:

```yaml
- repo: https://github.com/pre-commit/pre-commit-hooks
  hooks:
    - id: no-commit-to-branch
      args: [--branch, main, --branch, master]
```

## Platform notes (2026)

### GitHub

- **Repository Rulesets** (GA) is the recommended path, replacing the legacy branch-protection API.
- `gh` CLI is read-only for rulesets (`gh ruleset {list,view,check}`); create/update goes through
  `gh api`.
- Pushes using the default `GITHUB_TOKEN` do **not** trigger further workflow runs. If `main` needs
  CI on promotion, mint a GitHub App token via `actions/create-github-app-token@v1` and put that App
  in the ruleset's bypass list.

### GitLab

- `glab` has no `protected-branches` subcommand. All protection config goes through `glab api`.
- Per-user `allowed_to_push` / `allowed_to_merge` require **Premium/Ultimate**. Free tier uses
  coarse access-level enums and must rely on the CI job-token push toggle (17.2+) or a Deploy Token.
- Access-level integers: `0`=No one, `30`=Developer, `40`=Maintainer, `60`=Admin.
- **Branch rules** (Settings → Repository → Branch rules) is the new unified UI superseding
  **Protected branches**. Both paths still work in 18.x; this set of runbooks uses Protected
  branches because its form is fully stable.

## Caveats

- A release tag pushed on a commit that is not an ancestor of `develop` must be rejected by the
  promotion job — never skip the ancestry check.
- `GITHUB_TOKEN` cannot trigger downstream workflows. If `main` has its own CI that must run on
  promotion, use a GitHub App token instead.
- GitLab Free cannot restrict push to a specific user. The only "only CI can push" path there is the
  17.2+ job-token toggle.

## Verification checklist

Run after applying protection on either platform:

1. As a regular user, `git push origin main` — must be rejected.
2. Open a PR/MR from a feature branch directly to `main` — blocked.
3. Open a PR/MR to `develop` without required approvals — merge disabled.
4. Tag `v0.0.1-test` on `develop` — release job runs, `main` advances to the tag, release is
   published.
5. Tag `v0.0.2-test` on a commit **not** on `develop` — ancestry check fails, `main` stays put.
6. Delete the test tags and reset `main` on a scratch repo before trusting the flow in production.

## Sources

- [GitHub: About rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [GitHub: Available rules for rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets)
- [GitHub: REST API endpoints for rules](https://docs.github.com/en/rest/repos/rules)
- [GitHub CLI: gh ruleset](https://cli.github.com/manual/gh_ruleset)
- [GitHub Actions: Events that trigger workflows](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows)
- [GitLab: Protected branches](https://docs.gitlab.com/user/project/repository/branches/protected/)
- [GitLab: Branch rules](https://docs.gitlab.com/user/project/repository/branches/branch_rules/)
- [GitLab: Protected branches API](https://docs.gitlab.com/api/protected_branches/)
- [GitLab: Protected tags](https://docs.gitlab.com/user/project/protected_tags/)
- [GitLab: Push rules](https://docs.gitlab.com/user/project/repository/push_rules/)
- [GitLab: CI/CD job token](https://docs.gitlab.com/ci/jobs/ci_job_token/)
- [GitLab: Project access tokens](https://docs.gitlab.com/user/project/settings/project_access_tokens/)
- [GitLab: CI/CD variables](https://docs.gitlab.com/ci/variables/)
- [GitLab issue #494324 — CI_JOB_TOKEN allow-list](https://gitlab.com/gitlab-org/gitlab/-/issues/494324)
