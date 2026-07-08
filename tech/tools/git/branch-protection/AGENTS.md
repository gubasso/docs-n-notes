---
digest-of: tech/tools/git/branch-protection
last-synced: 2026-07-08
source-files:
  - README.md
  - workflow.md
  - first-run-enablement.md
  - github-web-ui.md
  - gitlab-web-ui.md
token-estimate: 2400
---

# AGENTS

## Scope

Branch-protection enforcement for the `develop` → tag → CI → `master` path: one setup script per
platform plus a point-and-click alternative, the canonical strategy doc, and the first-run host
toggles.

## Key Points

- **Workflow**: `workflow.md` describes the branch-protection strategy and rationale (the abstract
  branch/release _model_ lives in `tech/programming/release-workflow/`; this subtree is the platform
  _enforcement_ layer).
- **Apply it**: `github/setup.sh` (reads `OWNER_REPO`) and `gitlab/setup.sh` (reads `PROJECT`,
  `TIER=free|premium`) are the one-run-per-project entry points. Each applies the branch/tag
  protections, sets `develop` as default, verifies, and prints the manual host steps it cannot do
  via the API. `*-web-ui.md` are the point-and-click equivalents.
- **Required status checks are a parameter, not a hardcode**: pass `REQUIRED_CHECKS`
  (comma-separated contexts matching the job names the project's CI emits) to `github/setup.sh`. If
  unset, no status-check rule is added — the ruleset never blocks on a check that never reports. The
  check names are owned by the project's CI/language spec, not by this layer. GitLab gates on the
  pipeline (`only_allow_merge_if_pipeline_succeeds`), so it uses no named checks.
- **First-run enablement**: `first-run-enablement.md` — after the first push, enable Actions/CI and
  set write permissions (GitHub: Actions → General → Read and write + allow Actions to create PRs;
  GitLab: enable CI/CD, let CI push to protected `master`, OIDC `id_tokens`). OIDC needs no
  repo-level switch on GitHub — `id-token: write` at job level suffices.
- **Bypass actor**: `master` is written only by CI — GitHub default `github-actions` app id `15368`
  (override via `BYPASS_ACTOR_ID`); GitLab Premium allow-lists a Project Access Token bot user, Free
  relies on the 17.2+ job-token push toggle.
- **Layout**: `github/` holds `setup.sh`, the `rulesets/` payloads, and the release-promote
  workflow; `gitlab/` holds `setup.sh` and the release-promote CI template.

## Source Map

| Topic                              | File / Subtree                            |
| ---------------------------------- | ----------------------------------------- |
| Canonical workflow strategy        | `workflow.md`                             |
| One-shot setup per platform        | `github/setup.sh`, `gitlab/setup.sh`      |
| Enable Actions/CI + write perms    | `first-run-enablement.md`                 |
| Point-and-click runbooks           | `github-web-ui.md`, `gitlab-web-ui.md`    |
| GitHub ruleset payloads + workflow | `github/rulesets/`, `github/workflows/`   |
| GitLab release-promote CI template | `gitlab/ci/release-promote.gitlab-ci.yml` |

## Maintenance Notes

- The parent `tech/tools/git/` digest points here for the branch-protection subtree.
- Keep the README index and Usage block aligned with the two `setup.sh` entry points and the
  `rulesets/` / `ci/` template subtrees.
- The abstract branch/release model (the `develop` → tag → CI-promote-`master` strategy) is owned by
  the general shelf `tech/programming/release-workflow/`; this subtree is the platform _enforcement_
  layer (GitHub Rulesets / GitLab protected-branch runbooks, payloads, `setup.sh` scripts, and the
  tag-triggered release-promote CI templates). Standardized on `develop`/`master`.
- Status-check context names are intentionally not hardcoded: they must match each project's actual
  CI job names (per its language `release-workflow-spec`), supplied via `REQUIRED_CHECKS`.
