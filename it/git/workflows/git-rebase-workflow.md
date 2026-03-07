# Git Rebase Workflow: Upstream Fork with Linear Feature Branches

## Remotes & Branches

| Remote | Branch | Role |
|--------|--------|------|
| `upstream` | `master` | Source of truth (original repo) |
| `origin` | `master` | Your fork |
| local | `master` | Always identical to `upstream/master` |
| local | `new-feature` | Your work, rebased on top of `master` |

---

## Cheatsheet

```bash
# A) Sync master: upstream → local → origin (fast-forward only)
git fetch --all
git switch master
git merge --ff-only upstream/master
git push origin master

# B) Rebase feature branch onto updated master
git switch new-feature
git rebase master

# C) Clean up commits before pushing (optional but recommended)
git rebase -i master          # squash, fixup, reorder

# D) Push feature branch
git push origin new-feature                    # first time
git push --force-with-lease origin new-feature # after any rebase (history rewritten)
```

### Recommended global config

```bash
git config --global pull.ff only          # pull only fast-forwards; never creates merge commits
git config --global rebase.autostash true # auto stash/unstash dirty tree around rebases
git config --global fetch.prune true      # remove stale origin/* refs on every fetch

# Set master to track upstream/master
git switch master
git branch --set-upstream-to=upstream/master
```

### Useful checks

```bash
git config --list --show-origin   # all effective config and where it comes from
git config --get pull.ff          # current pull strategy
git branch -vv                    # branches + tracking info + ahead/behind
```

---

## How It Works

### Starting state

Upstream moved ahead. Your feature branch is based on an older `master`.

```
upstream/master:   A─B─C─D─E
local master:      A─B─C
origin/master:     A─B─C
new-feature:           └─f1─f2   (based on C)
```

### Step A — Sync master (fast-forward only)

`git merge --ff-only upstream/master` slides the `master` pointer forward.
If local `master` has diverged (has commits not in upstream), the command **fails** — this protects the rule that `master` stays identical to upstream.

```
upstream/master:   A─B─C─D─E
local master:      A─B─C─D─E   ✓ moved forward
origin/master:     A─B─C─D─E   (after git push)
new-feature:           └─f1─f2   (still on old C)
```

### Step B — Rebase feature onto master

`git rebase master` replays `f1` and `f2` on top of `E`, producing new commits `f1'` and `f2'` (same diffs, new SHAs).

```
upstream/master:   A─B─C─D─E
local master:      A─B─C─D─E
new-feature:                  └─f1'─f2'
```

### Step C — Clean up commits (interactive rebase)

Before pushing, squash or reorder commits so the branch tells a clean story:

```bash
git rebase -i master     # opens editor with all commits since master
git rebase -i HEAD~3     # alternatively, edit only the last 3 commits
```

Common actions in the editor: `pick`, `squash` / `s`, `fixup` / `f`, `reword` / `r`, `drop` / `d`.

### Step D — Push the rebased branch

Since the commit history was rewritten (new SHAs), a regular push is rejected if the branch was already pushed. `--force-with-lease` overwrites the remote **only if** nobody else pushed to it in the meantime — safer than `--force`.

```
origin/new-feature:           └─f1'─f2'
local  new-feature:           └─f1'─f2'
```

### Result: fully linear history

```
A─B─C─D─E─f1'─f2'
```

No merge commits. Clean `git log`.

---

## Handling Conflicts During Rebase

```bash
# 1. Fix the conflicting files
# 2. Stage them
git add <files>
# 3. Continue
git rebase --continue
# Or bail out entirely
git rebase --abort
```

---

## Recovery

### Undo a bad rebase

`reflog` records every position HEAD was at, including before the rebase started.

```bash
git reflog                  # find the SHA labeled before the rebase
git reset --hard HEAD@{3}   # replace 3 with the correct index
```

### Accidentally committed on master

```bash
git switch -c rescue-branch      # save your commits on a new branch first
git switch master
git reset --hard upstream/master  # restore master to upstream state exactly
```

---

## Stacked Feature Branches

If `feature-b` is based on `feature-a` (not on `master`), and you rebase `feature-a`, use `--onto` to re-root `feature-b`:

```bash
git rebase --onto master old-feature-a-tip feature-b
```

Where `old-feature-a-tip` is the SHA of the last commit of `feature-a` *before* it was rebased. Without `--onto`, `feature-b` will still point to the old `feature-a` commits.

---

## `merge --ff-only` vs `rebase` on master

| Scenario | `merge --ff-only` | `rebase` |
|----------|-------------------|----------|
| master is behind upstream (no local commits) | Fast-forwards. Same result. | Fast-forwards. Same result. |
| master has diverged (local commits exist) | **Refuses.** Nothing changes. | Replays local commits on top of upstream. |

Always use `--ff-only` on master — you never want local commits there.
Use `rebase` on feature branches to keep history linear.
