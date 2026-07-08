# Branch Protection — GitHub Web UI

Spec, strategy, prerequisites, caveats: [workflow](workflow.md).

UI labels verified against docs.github.com on 2026-04-22.

---

## 1. Protect `master`

**Settings → Code and automation → Rules → Rulesets → New ruleset → New branch ruleset**.

- **Ruleset name**: `master-protection`
- **Enforcement status**: `Active`
- **Bypass list → Add bypass** → `github-actions` (GitHub Apps) → **Bypass mode**: `Always allow`
- **Target branches → Add a target** → **Include default branch**
- Enable:
  - [x] Restrict deletions
  - [x] Block force pushes
  - [x] Require linear history
  - [x] Require a pull request before merging
    - Required approvals: `1`
    - Dismiss stale pull request approvals when new commits are pushed
    - Require approval of the most recent reviewable push
    - Require conversation resolution before merging
    - Allowed merge methods: Merge, Squash, Rebase
  - [x] Require status checks to pass before merging
    - Require branches to be up to date before merging
    - Add: `ci/build`, `ci/test`
- **Create**

---

## 2. `develop` — integration branch

1. Repo root → **branch dropdown** → type `develop` → **Create branch: develop from master**.

2. **Settings → Code and automation → Rules → Rulesets → New ruleset → New branch ruleset**:

   - **Ruleset name**: `develop-protection`
   - **Enforcement status**: `Active`
   - **Target branches → Add a target → Include by pattern** → `develop`
   - Enable:
     - [x] Restrict deletions
     - [x] Block force pushes
     - [x] Require a pull request before merging
       - Required approvals: `1`
       - Dismiss stale pull request approvals when new commits are pushed
       - Require approval of the most recent reviewable push
       - Require conversation resolution before merging
       - Allowed merge methods: Squash, Merge
     - [x] Require status checks to pass before merging
       - Require branches to be up to date before merging
       - Add your project's actual CI check names (e.g. `ci/build`, `ci/test`) — the job names your
         CI emits; see your language's `release-workflow-spec`.
   - **Create**

3. **Settings** → scroll to **Default branch** section → **Switch to another branch** icon →
   `develop` → **Update** → confirm **I understand, update the default branch.**

---

## 3. Protect `v*` tags + add promotion workflow

1. **Settings → Code and automation → Rules → Rulesets → New ruleset → New tag ruleset**:

   - **Ruleset name**: `release-tags`
   - **Enforcement status**: `Active`
   - **Target tags → Add a target → Include by pattern** → `v*`
   - Enable:
     - [x] Restrict deletions
     - [x] Block force pushes
     - [x] Restrict updates
   - **Create**

2. **Add file → Create new file** → path `.github/workflows/release-promote.yml`. Paste from
   [`workflows/release-promote.yml`](github/workflows/release-promote.yml). Commit on a feature
   branch, open PR into `develop`.

---

## Verify

- **Settings → Code and automation → Rules → Rulesets** — each ruleset shows `Active` with expected
  target count.
- Run the [cross-platform checklist](workflow.md#verification-checklist).
