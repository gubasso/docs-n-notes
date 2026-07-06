# Git Rebase Workflow

A step-by-step guide for teams using rebase to maintain clean, linear history.

---

## Branch Structure

```text
master          ← stable releases, version tags (v1.0, v1.1, ...)
  └── develop   ← integration branch, all features merge here
       ├── feature/*   ← new functionality
       ├── fix/*       ← bug fixes
       └── chore/*     ← refactors, CI, docs, dependencies
```

### Rules

- `master` and `develop` are **shared branches** — never rebase them, only merge into them.
- `feature/*`, `fix/*`, `chore/*` are **personal branches** — rebase freely before merging.
- Every commit on `develop` should compile and pass tests.
- `master` only receives merges from `develop` at release time.

---

## The Workflow

### 1. Start a feature branch

Always branch from the latest `develop`.

```bash
git checkout develop
git pull origin develop
git checkout -b feature/auth
```

```text
develop:        A --- B --- C
                             \
feature/auth:                 (empty, starts here)
```

### 2. Work on your feature

Make commits as you go. Don't worry about perfect commit messages yet.

```bash
# ... write code ...
git add -A
git commit -m "setup auth module skeleton"

# ... write more code ...
git add -A
git commit -m "add login endpoint"

# ... write more code ...
git add -A
git commit -m "add token refresh logic"
```

```text
develop:        A --- B --- C
                             \
feature/auth:                 F --- G --- H
```

Push your branch to remote regularly (backup + visibility):

```bash
git push origin feature/auth
```

### 3. Meanwhile, develop moves forward

Other people merge their work into `develop`. Your branch falls behind.

```text
develop:        A --- B --- C --- D --- E
                             \
feature/auth:                 F --- G --- H    (based on old C)
```

### 4. Clean up your commits (interactive rebase)

Before opening a PR, clean up messy commits. This is optional but recommended.

```bash
git rebase -i HEAD~3    # interactive rebase last 3 commits
```

Your editor opens:

```text
pick F  setup auth module skeleton
pick G  add login endpoint
pick H  add token refresh logic
```

Options for each line:

```text
pick   = keep the commit as-is
reword = keep the commit, change the message
squash = merge into previous commit, combine messages
fixup  = merge into previous commit, discard this message
drop   = delete the commit entirely
```

Example — squash a WIP commit into the previous one:

```text
pick   F  setup auth module skeleton
fixup  G  wip stuff                      ← fold into F, discard message
pick   H  add token refresh logic
```

Result: 2 clean commits instead of 3.

Save and close the editor. Git replays the commits with your changes.

**Interactive rebase cheat sheet:**

```text
Available actions (replace "pick" with):

  pick   (p)  Keep commit as-is
  reword (r)  Keep commit, edit message
  edit   (e)  Pause to amend the commit
  squash (s)  Meld into previous commit, combine messages
  fixup  (f)  Meld into previous commit, discard this message
  drop   (d)  Remove the commit entirely
  (reorder)   Move lines up/down to reorder commits

Commits are listed oldest → newest (top to bottom),
opposite of git log.
```

Common patterns:

```text
# Squash all into one commit
pick   a1b2c3 setup auth module
squash d4e5f6 wip auth stuff
squash g7h8i9 fix auth typo

# Fix a bad commit message
reword a1b2c3 bad message here       ← editor opens to rewrite
pick   d4e5f6 add login endpoint
pick   g7h8i9 add token refresh

# Drop a commit you don't want
pick   a1b2c3 setup auth module
drop   d4e5f6 debug garbage           ← gone from history
pick   g7h8i9 add token refresh

# Reorder commits (just move the lines)
pick   g7h8i9 add token refresh       ← was third, now first
pick   a1b2c3 setup auth module       ← was first, now second
```

### 5. Rebase onto latest develop

Bring your branch up to date with `develop` without creating merge commits.

```bash
git fetch origin
git rebase origin/develop
```

What happens internally:

```text
Step 1: Git removes your commits temporarily

  develop:        A --- B --- C --- D --- E
  patches on the table: [F] [H]

Step 2: Points your branch to the tip of develop

  feature/auth:   A --- B --- C --- D --- E

Step 3: Replays your commits one by one

  feature/auth:   A --- B --- C --- D --- E --- F'
  feature/auth:   A --- B --- C --- D --- E --- F' --- H'

Done:

  develop:        A --- B --- C --- D --- E
                                           \
  feature/auth:                             F' --- H'
```

### 6. Resolve conflicts (if any)

If a replayed commit touches the same lines that changed in `develop`, git stops and asks you to
resolve.

```bash
# Git tells you which file conflicts
git status

# Open the file, look for conflict markers (shown indented here):
    <<<<<<< HEAD
    the code from develop
    =======
    your code from the commit being replayed
    >>>>>>> F: setup auth module skeleton

# Fix it: pick one side, combine both, or rewrite entirely
# Then:
git add <fixed-file>
git rebase --continue     # continue replaying remaining commits
```

If you get lost or break something:

```bash
git rebase --abort        # undo everything, go back to before rebase
```

### 7. Force-push your rebased branch

Rebase rewrites commit hashes (F became F', H became H'). The remote still has the old hashes, so a
normal push is rejected.

```bash
git push origin feature/auth --force-with-lease
```

Why `--force-with-lease` instead of `--force`:

- `--force` overwrites the remote unconditionally
- `--force-with-lease` checks that nobody else pushed to your branch since your last fetch — if they
  did, it fails safely instead of destroying their work

### 8. Open a Pull Request

Open a PR from `feature/auth` → `develop` on GitHub/GitLab.

At this point your PR shows a clean diff against the latest `develop` with no merge commits and no
conflicts.

Code review happens here.

### 9. Merge into develop

After approval, merge with `--no-ff` (no fast-forward) to preserve the branch context in history.

```bash
git checkout develop
git pull origin develop
git merge --no-ff feature/auth -m "Merge feature/auth: add authentication module"
git push origin develop
```

On GitHub: use the "Create a merge commit" option (not squash, not rebase — you already rebased).

Result:

```text
develop: A --- B --- C --- D --- E ----------- M
                                          \   /
feature/auth:                              F' - H'
```

The merge commit `M` records when and what was integrated. The individual commits `F'` and `H'` are
preserved with clean history.

### 10. Delete the feature branch

```bash
git branch -d feature/auth               # delete local
git push origin --delete feature/auth     # delete remote
```

---

## Release Flow

When `develop` is stable and ready for release:

```bash
git checkout master
git pull origin master
git merge --no-ff develop -m "Release v1.1"
git tag v1.1
git push origin master --tags
```

```text
master:   v1.0 ──────────────── v1.1 (tag)
            \                    ↑
develop:     o─o─o── M₁ ──o── M₂ ─┘
                 \   ↑  \     ↑
feature/auth:     F-H┘   \   |
                           \  |
fix/login-bug:              X-Y┘
```

---

## Conflict Scenario — Full Example

You're working on `feature/auth`. A teammate merges `fix/login-bug` into `develop` that touches the
same file you edited.

```text
develop:        A --- B --- C --- D (teammate's fix, touches auth.py)
                             \
feature/auth:                 F --- G (your work, also touches auth.py)
```

You rebase:

```bash
git fetch origin
git rebase origin/develop
```

Git starts replaying. Commit `F` conflicts:

```text
CONFLICT (content): Merge conflict in src/auth.py
error: could not apply F... setup auth module
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add" then run "git rebase --continue"
```

Fix it:

```bash
vim src/auth.py                   # resolve the conflict markers
git add src/auth.py
git rebase --continue             # git now replays G
```

If `G` also conflicts, repeat. If not, rebase finishes:

```text
develop:        A --- B --- C --- D
                                   \
feature/auth:                       F' --- G'
```

Push and open PR:

```bash
git push origin feature/auth --force-with-lease
```

---

## Multiple Rebases

It's normal to rebase multiple times during a long-lived branch. Each time develop moves forward:

```bash
git fetch origin
git rebase origin/develop
# resolve conflicts if any
git push origin feature/auth --force-with-lease
```

Some teams rebase daily to avoid large conflict pileups at the end.

---

## Quick Reference

```text
START FEATURE:
  git checkout develop && git pull origin develop
  git checkout -b feature/my-thing

WORK:
  git add -A && git commit -m "description"
  git push origin feature/my-thing

CLEAN UP (optional):
  git rebase -i HEAD~N

REBASE ONTO DEVELOP:
  git fetch origin
  git rebase origin/develop
  # fix conflicts: edit file → git add → git rebase --continue
  # abort if stuck: git rebase --abort
  git push origin feature/my-thing --force-with-lease

MERGE (after PR approval):
  git checkout develop && git pull origin develop
  git merge --no-ff feature/my-thing
  git push origin develop

CLEANUP:
  git branch -d feature/my-thing
  git push origin --delete feature/my-thing

RELEASE:
  git checkout master && git pull origin master
  git merge --no-ff develop -m "Release vX.Y"
  git tag vX.Y
  git push origin master --tags
```

---

## Common Mistakes

**Rebasing a shared branch:** Never `git rebase` on `develop` or `master`. These are shared — other
people pull from them. Rebase rewrites history and breaks everyone else's local copy.

**Forgetting to fetch before rebase:** Always `git fetch origin` first. Without it you rebase onto
your local (stale) copy of develop, not the actual latest.

**Using `--force` instead of `--force-with-lease`:** `--force` blindly overwrites.
`--force-with-lease` checks first. Always use `--force-with-lease`.

**Rebasing with uncommitted changes:** Stash or commit before rebasing. Rebase won't start with a
dirty working tree.

```bash
git stash
git rebase origin/develop
git stash pop
```

**Panicking during conflict resolution:** `git rebase --abort` always takes you back to exactly
where you were before the rebase. No damage done. Use it freely.

---

## Syncing a Fork from Upstream

The workflow above assumes a single shared repository. When you work against a **fork** of an
upstream project, the mainline branch is not integrated locally — instead it mirrors the upstream
project and is only ever fast-forwarded. Feature branches are still rebased on top of it exactly as
above.

In this model `master` is the release/mainline branch name, and it tracks the upstream project's
default branch (kept byte-for-byte identical to `upstream/master`, never diverged locally).

### Remotes & branches

| Remote     | Branch        | Role                                  |
| ---------- | ------------- | ------------------------------------- |
| `upstream` | `master`      | Source of truth (original repo)       |
| `origin`   | `master`      | Your fork                             |
| local      | `master`      | Always identical to `upstream/master` |
| local      | `new-feature` | Your work, rebased on top of `master` |

### Cheatsheet

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

Useful checks:

```bash
git config --list --show-origin   # all effective config and where it comes from
git config --get pull.ff          # current pull strategy
git branch -vv                    # branches + tracking info + ahead/behind
```

### How it works

**Starting state.** Upstream moved ahead. Your feature branch is based on an older `master`.

```text
upstream/master:   A─B─C─D─E
local master:      A─B─C
origin/master:     A─B─C
new-feature:           └─f1─f2   (based on C)
```

**Step A — Sync master (fast-forward only).** `git merge --ff-only upstream/master` slides the
`master` pointer forward. If local `master` has diverged (has commits not in upstream), the command
**fails** — this protects the rule that `master` stays identical to upstream.

```text
upstream/master:   A─B─C─D─E
local master:      A─B─C─D─E   ✓ moved forward
origin/master:     A─B─C─D─E   (after git push)
new-feature:           └─f1─f2   (still on old C)
```

**Step B — Rebase feature onto master.** `git rebase master` replays `f1` and `f2` on top of `E`,
producing new commits `f1'` and `f2'` (same diffs, new SHAs).

```text
upstream/master:   A─B─C─D─E
local master:      A─B─C─D─E
new-feature:                  └─f1'─f2'
```

**Step C — Clean up commits (interactive rebase).** Before pushing, squash or reorder commits so the
branch tells a clean story:

```bash
git rebase -i master     # opens editor with all commits since master
git rebase -i HEAD~3     # alternatively, edit only the last 3 commits
```

Common actions in the editor: `pick`, `squash` / `s`, `fixup` / `f`, `reword` / `r`, `drop` / `d`.

**Step D — Push the rebased branch.** Since the commit history was rewritten (new SHAs), a regular
push is rejected if the branch was already pushed. `--force-with-lease` overwrites the remote **only
if** nobody else pushed to it in the meantime — safer than `--force`.

```text
origin/new-feature:           └─f1'─f2'
local  new-feature:           └─f1'─f2'
```

**Result: fully linear history.**

```text
A─B─C─D─E─f1'─f2'
```

No merge commits. Clean `git log`.

---

## Recovering with reflog

### Undo a bad rebase

`reflog` records every position HEAD was at, including before the rebase started.

```bash
git reflog                  # find the SHA labeled before the rebase
git reset --hard HEAD@{3}   # replace 3 with the correct index
```

### Accidentally committed on master

```bash
git switch -c rescue-branch       # save your commits on a new branch first
git switch master
git reset --hard upstream/master  # restore master to upstream state exactly
```

---

## Stacked Branches with `git rebase --onto`

If `feature-b` is based on `feature-a` (not on `master`), and you rebase `feature-a`, use `--onto`
to re-root `feature-b`:

```bash
git rebase --onto master old-feature-a-tip feature-b
```

Where `old-feature-a-tip` is the SHA of the last commit of `feature-a` _before_ it was rebased.
Without `--onto`, `feature-b` will still point to the old `feature-a` commits.

---

## `merge --ff-only` vs `rebase` on master

| Scenario                                     | `merge --ff-only`             | `rebase`                                  |
| -------------------------------------------- | ----------------------------- | ----------------------------------------- |
| master is behind upstream (no local commits) | Fast-forwards. Same result.   | Fast-forwards. Same result.               |
| master has diverged (local commits exist)    | **Refuses.** Nothing changes. | Replays local commits on top of upstream. |

Always use `--ff-only` on master — you never want local commits there. Use `rebase` on feature
branches to keep history linear.
</content>
</invoke>
