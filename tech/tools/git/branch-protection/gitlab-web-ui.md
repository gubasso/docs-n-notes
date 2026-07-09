# Branch Protection — GitLab Web UI

Spec, strategy, prerequisites, caveats: [workflow](./workflow.md).

UI labels verified against docs.gitlab.com on 2026-04-22 for GitLab 17.x / 18.x.

---

## 1. Protect `master`

1. **Settings → Access tokens → Add new token**:
   - Token name: `ci-release-bot`
   - Expiration date: required (pick a renewal date)
   - Role: `Maintainer`
   - Scopes: `write_repository`

   Copy the token. Note the bot user (`project_NNN_bot_…`).

2. **Settings → CI/CD → Variables → Add variable**:
   - Key: `PROMOTE_TOKEN`
   - Value: the token from step 1
   - Visibility: `Masked` (or `Masked and hidden`, one-way)
   - [x] Protect variable

3. Unprotect the default `master` rule. **Settings → Repository → Protected branches** → `master`
   row → **More actions (⋮) → Delete protected branch** → type name to confirm.

4. **Settings → Repository → Protected branches → Add protected branch**:
   - Branch: `master`
   - Allowed to merge: `Maintainers`
   - Allowed to push and merge:
     - **Free**: `No one` (pair with §3.2 job-token toggle)
     - **Premium/Ultimate**: user picker → bot user from step 1
   - Allowed to force push: off
   - Require approval from code owners: enable if using `CODEOWNERS`
   - **Protect**

5. (Premium+, optional) **Settings → Repository → Push rules** — enable as needed:
   - Reject unsigned commits
   - Prevent pushing secret files
   - Commit author's email (regex)
   - Check whether the commit author is a GitLab user
   - Preventing Git tag removal

---

## 2. `develop` — integration branch

1. Project page → **branch dropdown → New branch** → name `develop`, source `master`.

2. **Settings → Repository → Protected branches → Add protected branch**:
   - Branch: `develop`
   - Allowed to merge: `Developers + Maintainers`
   - Allowed to push and merge: `No one`
   - Allowed to force push: off
   - **Protect**

3. (Premium) **Settings → Merge requests → Merge request approvals → Approval rules → Add approval
   rule**:
   - Rule name: `develop-review`
   - Target branch: `develop`
   - Approvals required: `1`
   - Eligible approvers: pick group/role

4. Still on **Settings → Merge requests**:
   - Merge method: `Fast-forward merge`
   - Squash commits when merging: `Encourage`
   - In the **Merge checks** subsection:
     - [x] Pipelines must succeed
     - [x] All threads must be resolved

5. **Settings → Repository → Branch defaults → Default branch** → `develop` → **Save changes**.

---

## 3. Protect `v*` tags + add release pipeline

1. **Settings → Repository → Protected tags → Add protected tag**:
   - Tag: `v*`
   - Allowed to create: `Maintainers`
   - **Protect**

2. Grant CI push access to protected `master`:
   - **17.2+**: **Settings → CI/CD → Job token permissions → Permissions → Allow Git push requests
     to the repository**.
   - **Older / stricter**: use `PROMOTE_TOKEN` from §1.2 and (Premium) add its bot user to **Allowed
     to push and merge** on `master`.

3. **Web IDE** or **Add file → New file** → path `.gitlab-ci.yml` (or include it). Paste from
   [`ci/release-promote.gitlab-ci.yml`](gitlab/ci/release-promote.gitlab-ci.yml). Commit on a
   feature branch, open MR into `develop`.

---

## Verify

- **Settings → Repository → Protected branches** — `master`, `develop` listed with expected
  allow-lists.
- **Settings → Repository → Protected tags** — `v*` listed, Allowed to create = `Maintainers`.
- **Settings → CI/CD → Job token permissions** — Git push toggle in the expected state.
- Run the [cross-platform checklist](./workflow.md#verification-checklist).
