# 00 — Branch model

The workflow is built on two long-lived branches and short-lived feature branches. This chapter
defines them and the one-way promotion that turns an integrated `develop` into a published `master`.

## The branches

- **`develop`** — the integration branch and the **release trigger**. Feature branches merge here
  via reviewed PRs with green CI. Release automation watches `develop`.
- **`master`** — the release branch: a mirror of the latest published version. **No human ever
  writes to it.** CI fast-forwards it on release. (`main` is the common alias for `master` in repos
  that use that name; pick one and standardize.)
- **Feature branches** — short-lived (`feat/…`, `fix/…`, `chore/…`), branched off `develop`, kept
  linear with [rebase](../../tools/git/rebase-workflow.md), merged back into `develop` through a
  reviewed PR.

```text
feat/*  ──PR──▶  develop  ──release──▶  (tag vX.Y.Z)  ──CI promote──▶  master
                    ▲                                                     │
                    └──────────────── never edited by hand ──────────────┘
```

## Why a separate release branch

`master` gives you a branch that always points at exactly the last published release, with a linear,
fast-forward-only history and no in-progress work. Anyone can check out `master` and know it is the
released code; CI, tags, and `master` agree by construction. The cost is one promotion step — which
CI does automatically — in exchange for a release branch that cannot drift.

## Promotion: `develop` → `master`

On release, CI:

1. Determines the release **tag** the release tool just created (e.g. `v1.4.0`).
2. **Verifies the tagged commit is an ancestor of `develop`** — a tag on a commit not reachable from
   `develop` must be rejected, never promoted.
3. **Fast-forwards `master` to that tag** (`git merge --ff-only`). If `master` does not exist yet
   (first release), it is created at the tag.
4. Pushes `master`.

Fast-forward-only promotion is what keeps `master` linear and honest: it can only ever advance to a
commit already integrated on `develop`.

### Who is allowed to push `master`

Only the CI service identity — a GitHub App, `github-actions[bot]`, or a GitLab Project Access
Token. Enforce this with branch protection so a human `git push origin master` is rejected. See the
platform runbooks and rulesets in [branch-protection/](../../tools/git/branch-protection/) for the
exact GitHub Rulesets / GitLab protected-branch setup (bypass actor, tag protection, required linear
history).

> **CI retrigger caveat.** On GitHub, a push made with the default `GITHUB_TOKEN` does **not**
> trigger further workflows. If `master` needs its own CI to run on promotion, either run the
> promotion as a job in the same release run, or mint a GitHub App token so its push retriggers
> downstream workflows. See [03 — Tooling by ecosystem](./03-tooling-by-ecosystem.md) and the rust
> binding for a worked example.

## Feeding `develop`

The day-to-day loop that produces the commits `develop` accumulates:

- [Feature lifecycle](../../tools/git/feature-lifecycle.md) — issue → branch → work → PR → merge.
- [Rebase workflow](../../tools/git/rebase-workflow.md) — keep the feature branch linear on top of
  `develop` before merging.

## Reference

- [branch-protection/ — Branch protection & CI-driven release](../../tools/git/branch-protection/)
- [The Cargo Book / GitHub / GitLab platform docs are cited in the branch-protection runbooks.]
