# Branch Protection — GitHub CLI

Spec, strategy, prerequisites, caveats: [workflow](workflow.md).

Commands read `OWNER_REPO=owner/repo` from the environment. Payloads and scripts live under
[`github/`](github/).

```bash
export OWNER_REPO=owner/repo
```

---

## 1. Protect `main`

1. (Skip if using default `github-actions` app id `15368` — already baked into the payload.) Resolve
   bypass actor id:

   - [`scripts/lookup-bypass-actor.sh`](github/scripts/lookup-bypass-actor.sh)

2. Apply the ruleset:

   - payload: [`rulesets/main.json`](github/rulesets/main.json)
   - script: [`scripts/apply-main-ruleset.sh`](github/scripts/apply-main-ruleset.sh)

---

## 2. `develop` — integration branch

```bash
git checkout -b develop && git push -u origin develop
```

1. Apply the ruleset:

   - payload: [`rulesets/develop.json`](github/rulesets/develop.json)
   - script: [`scripts/apply-develop-ruleset.sh`](github/scripts/apply-develop-ruleset.sh)

2. Set default branch:

   - `BRANCH=develop` [`scripts/set-default-branch.sh`](github/scripts/set-default-branch.sh)

---

## 3. Protect `v*` tags + add promotion workflow

1. Apply tag ruleset:

   - payload: [`rulesets/tags.json`](github/rulesets/tags.json)
   - script: [`scripts/apply-tag-ruleset.sh`](github/scripts/apply-tag-ruleset.sh)

2. Copy the promotion workflow into the target repo at `.github/workflows/release-promote.yml`:

   - source: [`workflows/release-promote.yml`](github/workflows/release-promote.yml)

---

## Verify

- script: [`scripts/verify.sh`](github/scripts/verify.sh)
- Then run the [cross-platform checklist](workflow.md#verification-checklist).
