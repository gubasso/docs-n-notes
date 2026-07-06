---
digest-of: tech/tools/git/branch-protection
last-synced: 2026-07-06
source-files:
  - README.md
  - github-cli.md
  - github-web-ui.md
  - gitlab-cli.md
  - gitlab-web-ui.md
  - workflow.md
token-estimate: 2850
---

# AGENTS

## Scope

Branch-protection workflow notes for the `develop` → tag → CI → `master` path, with GitHub and
GitLab CLI/UI runbooks plus the canonical strategy document.

## Key Points

- **Workflow**: `workflow.md` describes the branch-protection strategy and rationale.
- **GitHub**: `github-cli.md` and `github-web-ui.md` cover the GitHub command-line and browser
  paths.
- **GitLab**: `gitlab-cli.md` and `gitlab-web-ui.md` cover the GitLab command-line and browser
  paths.
- **Layout**: `github/` and `gitlab/` hold ruleset, workflow, CI, and helper-script material.

## Source Map

| Topic                             | File / Subtree                      |
| --------------------------------- | ----------------------------------- |
| Canonical workflow strategy       | `workflow.md`                       |
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
