# Git Rebase Workflow

A step-by-step guide for teams using rebase to maintain clean, linear history.

---

## Branch Structure

```text
master          ← stable releases, version tags (v1.0, v1.1, ...)
  └── devel     ← integration branch, all features merge here
       ├── feature/*   ← new functionality
       ├── fix/*       ← bug fixes
       └── chore/*     ← refactors, CI, docs, dependencies
```

### Rules

- `master` and `devel` are shared branches. Never rebase them, only merge into them.
- `feature/*`, `fix/*`, `chore/*` are personal branches. Rebase freely before merging.
- Every commit on `devel` should compile and pass tests.
- `master` only receives merges from `devel` at release time.

---

## The Workflow

### 1. Start a feature branch

Always branch from the latest `devel`.

```bash
git checkout devel
git pull origin devel
git checkout -b feature/auth
```

```text
devel:          A --- B --- C
                             \
feature/auth:                 (empty, starts here)
```

### 2. Work on your feature

Make commits as you go. Do not worry about perfect commit messages yet.

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
devel:          A --- B --- C
                             \
feature/auth:                 F --- G --- H
```

Push your branch to remote regularly (backup + visibility):

```bash
git push origin feature/auth
```

### 3. Meanwhile, devel moves forward

Other people merge their work into `devel`. Your branch falls behind.

```text
devel:          A --- B --- C --- D --- E
                             \
feature/auth:                 F --- G --- H    (based on old C)
```

### 4. Clean up your commits (interactive rebase)

Before opening a PR, clean up messy commits. This is optional but recommended.

```bash
git rebase -i HEAD~3
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

Example: squash a WIP commit into the previous one:

```text
pick   F  setup auth module skeleton
fixup  G  wip stuff
pick   H  add token refresh logic
```

Result: 2 clean commits instead of 3.

Save and close the editor. Git replays the commits with your changes.

**Interactive rebase cheat sheet**

```text
Available actions (replace "pick" with):

  pick   (p)  Keep commit as-is
  reword (r)  Keep commit, edit message
  edit   (e)  Pause to amend the commit
  squash (s)  Meld into previous commit, combine messages
  fixup  (f)  Meld into previous commit, discard this message
  drop   (d)  Remove the commit entirely
  (reorder)   Move lines up/down to reorder commits

Commits are listed oldest -> newest (top to bottom),
opposite of git log.
```

Common patterns:

```text
# Squash all into one commit
pick   a1b2c3 setup auth module
squash d4e5f6 wip auth stuff
squash g7h8i9 fix auth typo

# Fix a bad commit message
reword a1b2c3 bad message here
pick   d4e5f6 add login endpoint
pick   g7h8i9 add token refresh

# Drop a commit you don't want
pick   a1b2c3 setup auth module
drop   d4e5f6 debug garbage
pick   g7h8i9 add token refresh

# Reorder commits (just move the lines)
pick   g7h8i9 add token refresh
pick   a1b2c3 setup auth module
```

### 5. Rebase onto latest devel

Bring your branch up to date with `devel` without creating merge commits.

```bash
git fetch origin
git rebase origin/devel
```

What happens internally:

```text
Step 1: Git removes your commits temporarily

  devel:          A --- B --- C --- D --- E
  patches on the table: [F] [H]

Step 2: Points your branch to the tip of devel

  feature/auth:   A --- B --- C --- D --- E

Step 3: Replays your commits one by one

  feature/auth:   A --- B --- C --- D --- E --- F'
  feature/auth:   A --- B --- C --- D --- E --- F' --- H'

Done:

  devel:          A --- B --- C --- D --- E
                                           \
  feature/auth:                             F' --- H'
```

### 6. Resolve conflicts (if any)

If a replayed commit touches the same lines that changed in `devel`, Git stops and asks you to
resolve.

```bash
git status

# Open the file, look for conflict markers:
#   <<<<<< HEAD
#       the code from devel
#   ======
#       your code from the commit being replayed
#   >>>>>> F: setup auth module skeleton

# Fix it: pick one side, combine both, or rewrite entirely
# Then:
git add <fixed-file>
git rebase --continue
```

If you get lost or break something:

```bash
git rebase --abort
```

### 7. Force-push your rebased branch

Rebase rewrites commit hashes (`F` became `F'`, `H` became `H'`). The remote still has the old
hashes, so a normal push is rejected.

```bash
git push origin feature/auth --force-with-lease
```

Why `--force-with-lease` instead of `--force`:

- `--force` overwrites the remote unconditionally.
- `--force-with-lease` checks that nobody else pushed to your branch since your last fetch. If they
  did, it fails safely instead of destroying their work.

### 8. Open a Pull Request

Open a PR from `feature/auth` to `devel` on GitHub or GitLab.

At this point your PR shows a clean diff against the latest `devel` with no merge commits and no
conflicts.

Code review happens here.

### 9. Merge into devel

After approval, merge with `--no-ff` to preserve the branch context in history.

```bash
git checkout devel
git pull origin devel
git merge --no-ff feature/auth -m "Merge feature/auth: add authentication module"
git push origin devel
```

On GitHub: use the "Create a merge commit" option, not squash and not rebase, because you already
rebased.

Result:

```text
devel:   A --- B --- C --- D --- E ----------- M
                                          \   /
feature/auth:                              F' - H'
```

The merge commit `M` records when and what was integrated. The individual commits `F'` and `H'` are
preserved with clean history.

### 10. Delete the feature branch

```bash
git branch -d feature/auth
git push origin --delete feature/auth
```

---

## Release Flow

When `devel` is stable and ready for release:

```bash
git checkout master
git pull origin master
git merge --no-ff devel -m "Release v1.1"
git tag v1.1
git push origin master --tags
```

```text
master:   v1.0 ---------------- v1.1 (tag)
            \                    ↑
devel:       o-o-o-- M1 --o-- M2 -┘
                 \   ↑  \     ↑
feature/auth:     F-H┘   \   |
                           \  |
fix/login-bug:              X-Y┘
```

---

## Conflict Scenario: Full Example

You are working on `feature/auth`. A teammate merges `fix/login-bug` into `devel` that touches the
same file you edited.

```text
devel:          A --- B --- C --- D (teammate's fix, touches auth.py)
                             \
feature/auth:                 F --- G (your work, also touches auth.py)
```

You rebase:

```bash
git fetch origin
git rebase origin/devel
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
vim src/auth.py
git add src/auth.py
git rebase --continue
```

If `G` also conflicts, repeat. If not, rebase finishes:

```text
devel:          A --- B --- C --- D
                                   \
feature/auth:                       F' --- G'
```

Push and open PR:

```bash
git push origin feature/auth --force-with-lease
```

---

## Multiple Rebases

It is normal to rebase multiple times during a long-lived branch. Each time `devel` moves forward:

```bash
git fetch origin
git rebase origin/devel
# resolve conflicts if any
git push origin feature/auth --force-with-lease
```

Some teams rebase daily to avoid large conflict pileups at the end.

---

## Quick Reference

```text
START FEATURE:
  git checkout devel && git pull origin devel
  git checkout -b feature/my-thing

WORK:
  git add -A && git commit -m "description"
  git push origin feature/my-thing

CLEAN UP (optional):
  git rebase -i HEAD~N

REBASE ONTO DEVEL:
  git fetch origin
  git rebase origin/devel
  # fix conflicts: edit file -> git add -> git rebase --continue
  # abort if stuck: git rebase --abort
  git push origin feature/my-thing --force-with-lease

MERGE (after PR approval):
  git checkout devel && git pull origin devel
  git merge --no-ff feature/my-thing
  git push origin devel

CLEANUP:
  git branch -d feature/my-thing
  git push origin --delete feature/my-thing

RELEASE:
  git checkout master && git pull origin master
  git merge --no-ff devel -m "Release vX.Y"
  git tag vX.Y
  git push origin master --tags
```

---

## Common Mistakes

### Rebasing a shared branch

Never run `git rebase` on `devel` or `master`. These are shared branches, and rebasing them rewrites
history and breaks everyone else's local copy.

### Forgetting to fetch before rebase

Always `git fetch origin` first. Without it you rebase onto your local, stale copy of `devel`, not
the actual latest.

### Using `--force` instead of `--force-with-lease`

`--force` blindly overwrites. `--force-with-lease` checks first. Always use `--force-with-lease`.

### Rebasing with uncommitted changes

Stash or commit before rebasing. Rebase will not start with a dirty working tree.

```bash
git stash
git rebase origin/devel
git stash pop
```

### Panicking during conflict resolution

`git rebase --abort` takes you back to exactly where you were before the rebase. Use it freely.
