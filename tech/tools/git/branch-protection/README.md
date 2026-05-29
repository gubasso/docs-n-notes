# branch-protection

Templates and helper scripts for the `develop` → tag → CI → `main` workflow.

Strategy and rationale live in [workflow](workflow.md). Step-by-step CLI runbooks:
[github-cli](github-cli.md) and [gitlab-cli](gitlab-cli.md).

## Layout

```text
github/
  rulesets/      JSON payloads for `gh api /repos/:o/:r/rulesets`
  workflows/     GitHub Actions workflow templates
  scripts/       thin wrappers around `gh` / `gh api`
gitlab/
  scripts/       thin wrappers around `glab api`
  ci/            GitLab CI job templates
```

All scripts read `OWNER_REPO` (GitHub) or `PROJECT` (GitLab, `group/project`) from the environment
and can be run unmodified against any repo.
