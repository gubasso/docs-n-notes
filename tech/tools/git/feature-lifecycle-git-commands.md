# Feature Lifecycle — Git Commands

Pure git commands implementing the feature lifecycle described in
[feature-lifecycle](./feature-lifecycle.md).

Uses `git clone --reference` to create isolated work-clones (feature directories) for each feature.

---

## Conventions

- Main repo: `~/Projects/org/repo`
- Work-clone: `~/Projects/org/repo.<issue>-<slug>` (e.g., `repo.42-add-auth-module`) — a
  `git clone --reference` of the main repo, sharing its object store
- Integration branch: `develop`
- Default branch: `master`
- Feature branch: `<issue>-<slug>` (e.g., `42-add-auth-module`)

---

## Creating a Work-Clone

Clone from the remote using the main repo as an alternates store. This avoids duplicating objects on
disk. The issue must exist first — the forge CLI creates the branch and owns the branch name.

```bash
git clone --reference ~/Projects/org/repo \
    git@github.com:org/repo.git \
    ~/Projects/org/repo.42-add-auth-module
```

Do not delete the main repo while work-clones exist — they depend on its object store.

---

## Entry Points

### From an existing issue

The issue already exists on the forge. Let the forge create and name the branch, then fetch it.

```bash
# 1. Let the forge create the branch (from the main repo)
gh issue develop 42 --base develop                 # GitHub — creates remote branch

# 2. Retrieve the branch name the forge chose
BRANCH=$(gh issue develop 42 --list --json headRefName --jq '.[0].headRefName')

# 3. Create work-clone using the forge-provided branch name
git clone --reference ~/Projects/org/repo \
    git@github.com:org/repo.git \
    ~/Projects/org/repo."$BRANCH"
cd ~/Projects/org/repo."$BRANCH"
git fetch origin "$BRANCH"
git checkout "$BRANCH"
```

On GitHub, `gh issue develop` creates the branch on the remote and links it in the issue's
Development sidebar. The branch name is determined by GitHub. On GitLab, there is no `issue develop`
equivalent; create the branch manually and link via `glab mr create --related-issue` later.

### From a new issue

Create the issue from the CLI first, then let the forge create and name the branch.

```bash
# 1. Create the issue
gh issue create --title "Add auth module"        # GitHub → returns URL with ID

# 2. Let the forge create the branch
gh issue develop 42 --base develop

# 3. Retrieve the branch name the forge chose
BRANCH=$(gh issue develop 42 --list --json headRefName --jq '.[0].headRefName')

# 4. Create work-clone using the forge-provided branch name
git clone --reference ~/Projects/org/repo \
    git@github.com:org/repo.git \
    ~/Projects/org/repo."$BRANCH"
cd ~/Projects/org/repo."$BRANCH"
git fetch origin "$BRANCH"
git checkout "$BRANCH"
```

### From uncommitted changes

Stash first, then create the issue, let the forge name the branch, clone, and apply.

```bash
# 1. Save uncommitted changes
cd ~/Projects/org/repo
git stash

# 2. Create the issue
gh issue create --title "Add auth module"        # → issue #42

# 3. Let the forge create the branch
gh issue develop 42 --base develop

# 4. Retrieve the branch name the forge chose
BRANCH=$(gh issue develop 42 --list --json headRefName --jq '.[0].headRefName')

# 5. Create work-clone using the forge-provided branch name
git clone --reference ~/Projects/org/repo \
    git@github.com:org/repo.git \
    ~/Projects/org/repo."$BRANCH"
cd ~/Projects/org/repo."$BRANCH"
git fetch origin "$BRANCH"
git checkout "$BRANCH"

# 6. Transfer stash from main repo (stash is repo-local)
git -C ~/Projects/org/repo stash show -p | git apply
```

Drop the stash in the main repo once the changes are confirmed in the work-clone.

```bash
git -C ~/Projects/org/repo stash drop
```

---

## Sync

Push the feature branch to origin and set up tracking. If the branch was created via
`gh issue develop`, the remote branch already exists; `git push -u` sets the local tracking
reference.

```bash
git push -u origin 42-add-auth-module
```

---

## Rebase

Keep the feature branch current with the integration branch.

```bash
git fetch origin
git rebase origin/develop
git push --force-with-lease
```

---

## Finish

Push the branch and open a PR on the forge.

```bash
cd ~/Projects/org/repo.42-add-auth-module
git push -u origin 42-add-auth-module

# GitHub
gh pr create --base develop --head 42-add-auth-module

# GitLab
glab mr create --target-branch develop --source-branch 42-add-auth-module
```

Add `--draft` for a draft PR or MR.

---

## Cleanup

After the PR is merged on the forge, pull the target branch and remove the work-clone.

```bash
# Pull the merged changes into the main repo
cd ~/Projects/org/repo
git checkout develop
git pull

# Remove the work-clone
rm -rf ~/Projects/org/repo.42-add-auth-module

# Delete the local feature branch (remote branch auto-deleted by forge on merge)
git branch -d 42-add-auth-module
```

---

## Release

From the main repo, open a PR from the integration branch into the default branch, merge on the
forge, then pull and tag locally.

```bash
# Open the release PR on the forge
cd ~/Projects/org/repo
gh pr create --base master --head develop --title "Release v1.0.0"   # GitHub
glab mr create --target-branch master --source-branch develop        # GitLab

# After the PR is merged on the forge — pull and tag locally
git checkout master
git pull
git tag -a v1.0.0 -m "v1.0.0"
git push origin v1.0.0
```

---

## Quick Reference

```text
CREATE WORK-CLONE:
  git clone --reference <main-repo> <remote-url> <work-clone>

FROM EXISTING ISSUE:
  gh issue develop <id> --base <branch>            # forge creates + names branch
  BRANCH=$(gh issue develop <id> --list ...)       # retrieve forge-chosen name
  git clone --reference ...                        # create work-clone
  git fetch origin $BRANCH && git checkout ...     # check out the branch

FROM NEW ISSUE:
  gh issue create --title "..."                    # create issue (→ ID)
  gh issue develop <id> --base <branch>            # forge creates + names branch
  BRANCH=$(gh issue develop <id> --list ...)       # retrieve forge-chosen name
  git clone --reference ...                        # create work-clone
  git fetch origin $BRANCH && git checkout ...     # check out the branch

FROM UNCOMMITTED CHANGES:
  git stash                                        # save changes in main repo
  gh issue create --title "..."                    # create issue (→ ID)
  gh issue develop <id> --base <branch>            # forge creates + names branch
  BRANCH=$(gh issue develop <id> --list ...)       # retrieve forge-chosen name
  git clone --reference ...                        # create work-clone
  git fetch origin $BRANCH && git checkout ...     # check out the branch
  git -C <main-repo> stash show -p | git apply     # transfer changes
  git -C <main-repo> stash drop                    # drop stash after confirm

SYNC:
  git push -u origin <branch>                      # push + track

REBASE:
  git fetch origin                                 # fetch upstream
  git rebase origin/develop                          # rebase onto integration
  git push --force-with-lease                      # force-push safely

FINISH:
  git push -u origin <branch>                      # push feature branch
  gh pr create --base develop                        # open PR (GitHub)

CLEANUP:
  cd <main-repo> && git checkout develop && git pull # pull merged changes
  rm -rf <work-clone>                              # delete work-clone
  git branch -d <branch>                           # delete local branch

RELEASE:
  gh pr create --base master --head develop          # open release PR (GitHub)
  git checkout master && git pull                  # pull after remote merge
  git tag -a <version> -m "<version>"              # tag release
  git push origin <version>                        # push tag
```

---

## Appendix — Local Merge

When no forge is available (offline, no remote access), merge locally instead of opening a PR.

Because the work-clone is a separate clone, either fetch from origin after pushing or add it as a
temporary remote.

**Option A — fetch from origin after pushing from the work-clone:**

```bash
# In the work-clone — push latest
cd ~/Projects/org/repo.42-add-auth-module
git push

# In the main repo — fetch and merge
cd ~/Projects/org/repo
git checkout develop
git fetch origin
git merge --no-ff origin/42-add-auth-module
```

**Option B — add work-clone as a temporary remote:**

```bash
cd ~/Projects/org/repo
git remote add temp-42 ~/Projects/org/repo.42-add-auth-module
git fetch temp-42
git checkout develop
git merge --no-ff temp-42/42-add-auth-module
git remote remove temp-42
```

For a local release merge (no forge PR):

```bash
cd ~/Projects/org/repo
git checkout master
git merge --no-ff develop
git tag -a v1.0.0 -m "v1.0.0"
git push origin master --follow-tags
```
