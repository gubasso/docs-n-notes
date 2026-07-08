# branch-protection

Templates and a one-shot setup script per platform for the `develop` → tag → CI → `master` workflow.
Run once per new project.

- [workflow](workflow.md) — strategy, prerequisites, caveats, verification checklist.
- [first-run-enablement](first-run-enablement.md) — turning Actions/CI on and to write, after the
  first push.
- [github-web-ui](github-web-ui.md) / [gitlab-web-ui](gitlab-web-ui.md) — point-and-click
  alternatives to the setup scripts.

## Usage

```bash
# GitHub — apply master/develop/tag rulesets, set develop as default, verify.
OWNER_REPO=owner/repo REQUIRED_CHECKS="ci/build,ci/test" github/setup.sh

# GitLab — protect branches/tags, set develop as default, verify.
PROJECT=group/project TIER=free gitlab/setup.sh          # or TIER=premium BOT_USER_ID=<id>
```

`REQUIRED_CHECKS` is a comma-separated list of CI status-check contexts to require on `master` and
`develop`. It **must match the job names your CI actually emits** — see your language's
`release-workflow-spec`. If unset, no status-check rule is added (nothing to block PRs on). GitLab
gates on the pipeline itself (`only_allow_merge_if_pipeline_succeeds`), so it needs no check names.

Each script then prints the manual host steps it cannot do via the API (copy the release-promote CI
template into the repo; enable Actions/CI write — see `first-run-enablement.md`).

## Layout

- `github/setup.sh` — entry point; reads `OWNER_REPO`.
  - `rulesets/` — the master/develop/tag ruleset payloads it applies.
  - `workflows/release-promote.yml` — copied into the target repo's `.github/workflows/`.
- `gitlab/setup.sh` — entry point; reads `PROJECT` (`group/project`) and `TIER`.
  - `ci/release-promote.gitlab-ci.yml` — copied into the target project's `.gitlab-ci.yml`.
