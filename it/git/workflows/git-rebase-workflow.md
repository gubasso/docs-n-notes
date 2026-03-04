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

# C) Push feature branch
git push origin new-feature                    # first time
git push --force-with-lease origin new-feature # subsequent pushes (history was rewritten)
```

### One-liner (A + B + C)

```bash
git fetch --all \
  && git switch master \
  && git merge --ff-only upstream/master \
  && git push origin master \
  && git switch new-feature \
  && git rebase master \
  && git push --force-with-lease origin new-feature
```

### Recommended global config

```bash
# Make --ff-only the default for pulls
git config --global pull.ff only

# Set master to track upstream/master by default
git switch master
git branch --set-upstream-to=upstream/master
```

### Useful checks

```bash
git config --list --show-origin   # all effective config
git config --get pull.ff          # current pull strategy
git branch -vv                    # branches + tracking info
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

### Step C — Push the rebased branch

Since the commit history was rewritten (new SHAs), a regular push is rejected if the branch was already pushed. `--force-with-lease` overwrites the remote but **only if** nobody else pushed to it in the meantime — safer than `--force`.

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

## merge --ff-only vs rebase on master

| Scenario | `merge --ff-only` | `rebase` |
|----------|-------------------|----------|
| master is behind upstream (no local commits) | Fast-forwards. Same result. | Fast-forwards. Same result. |
| master has diverged (local commits exist) | **Refuses.** Nothing changes. | Replays local commits on top of upstream. |

For this workflow, always use `--ff-only` on master — you don't want local commits there.
Use `rebase` on your feature branches to keep them linear.
