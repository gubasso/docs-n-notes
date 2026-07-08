# branch-protection

Templates and helper scripts for the `develop` → tag → CI → `master` workflow.

- [workflow](workflow.md)
- [first-run-enablement](first-run-enablement.md) — turning Actions/CI on and to write, after the
  first push
- [github-cli](github-cli.md)
- [github-web-ui](github-web-ui.md)
- [gitlab-cli](gitlab-cli.md)
- [gitlab-web-ui](gitlab-web-ui.md)

## Layout

- `github/` - GitHub rulesets, workflow templates, and helper scripts.
- `gitlab/` - GitLab CI templates and helper scripts.

All scripts read `OWNER_REPO` (GitHub) or `PROJECT` (GitLab, `group/project`) from the environment.
