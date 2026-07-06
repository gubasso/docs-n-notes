# Branch Protection — GitLab CLI

Spec, strategy, prerequisites, caveats: [workflow](workflow.md).

Commands read `PROJECT_ID` from the environment. Scripts live under [`gitlab/`](gitlab/).

```bash
export PROJECT_ID=$(bash .../gitlab/scripts/get-project-id.sh)
```

- script: [`scripts/get-project-id.sh`](gitlab/scripts/get-project-id.sh)

---

## 1. Protect `master`

1. Create a Project Access Token (**Settings → Access tokens**, role `Maintainer`, scope
   `write_repository`) and capture its bot user id:

   - script: [`scripts/get-bot-user-id.sh`](gitlab/scripts/get-bot-user-id.sh)

2. Remove GitLab's default protection on `master`:

   - script: [`scripts/unprotect-master.sh`](gitlab/scripts/unprotect-master.sh)

3. Apply protection — pick your tier:

   - **Free** (pushes blocked; CI job-token toggle handles the release job):
     [`scripts/protect-master-free.sh`](gitlab/scripts/protect-master-free.sh)
   - **Premium/Ultimate** (only `BOT_USER_ID` may push):
     [`scripts/protect-master-premium.sh`](gitlab/scripts/protect-master-premium.sh)

4. (Premium+, optional) project push rules:

   - script: [`scripts/push-rules.sh`](gitlab/scripts/push-rules.sh)

---

## 2. `develop` — integration branch

```bash
git checkout -b develop && git push -u origin develop
```

1. Protect — Developers may merge via MR but not push:

   - script: [`scripts/protect-develop.sh`](gitlab/scripts/protect-develop.sh)

2. (Premium) Require approvals on MRs targeting `develop`. Resolve the protected-branch id first:

   ```bash
   glab api "projects/${PROJECT_ID}/protected_branches/develop" --jq '.id'
   ```

   - script: [`scripts/require-approvals.sh`](gitlab/scripts/require-approvals.sh)

3. Project MR hygiene (green pipeline + resolved discussions + fast-forward):

   - script: [`scripts/project-mr-settings.sh`](gitlab/scripts/project-mr-settings.sh)

4. Set default branch:

   - `BRANCH=develop` [`scripts/set-default-branch.sh`](gitlab/scripts/set-default-branch.sh)

---

## 3. Protect `v*` tags + add release pipeline

1. Protect `v*` tags:

   - script: [`scripts/protect-tags.sh`](gitlab/scripts/protect-tags.sh)

2. Grant CI push access to protected `master`:

   - **17.2+**: Web UI only — **Settings → CI/CD → Job token permissions → Allow Git push requests
     to the repository**. No API equivalent yet ([#494324][gl-494324]).
   - **Older**: `PROMOTE_TOKEN` + Premium allow-list (see
     [`scripts/protect-master-premium.sh`](gitlab/scripts/protect-master-premium.sh)).

3. Copy the release job into `.gitlab-ci.yml`:

   - source: [`ci/release-promote.gitlab-ci.yml`](gitlab/ci/release-promote.gitlab-ci.yml)

---

## Verify

- script: [`scripts/verify.sh`](gitlab/scripts/verify.sh)
- Then run the [cross-platform checklist](workflow.md#verification-checklist).

[gl-494324]: https://gitlab.com/gitlab-org/gitlab/-/issues/494324
