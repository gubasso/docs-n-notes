---
digest-of: tech/tools/git/branch-protection
last-synced: 2026-07-08
source-files:
  - README.md
  - first-run-enablement.md
  - github-cli.md
  - github-web-ui.md
  - gitlab-cli.md
  - gitlab-web-ui.md
  - workflow.md
token-estimate: 3150
---

# AGENTS

## Scope

Branch-protection workflow notes for the `develop` → tag → CI → `master` path, with GitHub and
GitLab CLI/UI runbooks plus the canonical strategy document.

## Key Points

- **Workflow**: `workflow.md` describes the branch-protection strategy and rationale.
- **First-run enablement**: `first-run-enablement.md` — after the first push, enable Actions/CI and
  set write permissions (GitHub: Actions → General → Read and write + allow Actions to create PRs;
  GitLab: enable CI/CD, let CI push to protected `master`, OIDC `id_tokens`). OIDC needs no
  repo-level switch on GitHub — `id-token: write` at job level suffices.
- **GitHub**: `github-cli.md` and `github-web-ui.md` cover the GitHub command-line and browser
  paths.
- **GitLab**: `gitlab-cli.md` and `gitlab-web-ui.md` cover the GitLab command-line and browser
  paths.
- **Layout**: `github/` and `gitlab/` hold ruleset, workflow, CI, and helper-script material.

## Source Map

| Topic                             | File / Subtree                      |
| --------------------------------- | ----------------------------------- |
| Canonical workflow strategy       | `workflow.md`                       |
| Enable Actions/CI + write perms   | `first-run-enablement.md`           |
| GitHub CLI and browser runbooks   | `github-cli.md`, `github-web-ui.md` |
| GitLab CLI and browser runbooks   | `gitlab-cli.md`, `gitlab-web-ui.md` |
| GitHub rulesets/workflows/scripts | `github/`                           |
| GitLab CI/scripts                 | `gitlab/`                           |

## Maintenance Notes

- The parent `tech/tools/git/` digest points here for the branch-protection subtree.
- Keep the README index aligned with the workflow docs and the two script/config subtrees.
- The abstract branch/release model (the `develop` → tag → CI-promote-`master` strategy) is owned by
  the general shelf `tech/programming/release-workflow/`; this subtree is the platform _enforcement_
  layer (GitHub Rulesets / GitLab protected-branch runbooks, rulesets, scripts, and the
  tag-triggered release-promote CI templates). Standardized on `develop`/`master`.
