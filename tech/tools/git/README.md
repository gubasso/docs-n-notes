# Git

> $git

<!--TOC-->

- [hooks](#hooks)
- [Commands](#commands)
  - [Merge branches (one-liner)](#merge-branches-one-liner)
  - [Checkout vs Switch](#checkout-vs-switch)
- [Branches](#branches)
  - [Clone and switch to a branch](#clone-and-switch-to-a-branch)
  - [Rename a branch](#rename-a-branch)
  - [Delete branches](#delete-branches)
- [Merge / Diff conflicts](#merge--diff-conflicts)
  - [Merge just a file/path from another branch](#merge-just-a-filepath-from-another-branch)
  - [merge from stash](#merge-from-stash)
- [Development & release workflow](#development--release-workflow)
  - [External reading](#external-reading)
- [Related](#related)
- [Development Docs](#development-docs)
- [Resources](#resources)
- [General](#general)
- [References](#references)

<!--TOC-->

## hooks

- https://www.viget.com/articles/two-ways-to-share-git-hooks-with-your-team/

## Commands

### Merge branches (one-liner)

The easiest option is to merge the target branch (e.g. `develop`) into the feature branch using
something like the following:

```sh
git checkout feature
git merge develop
```

Or, you can condense this to a one-liner:

```sh
git merge feature develop
```

### Checkout vs Switch

- [What's the difference between git switch and git checkout branch](https://stackoverflow.com/questions/57265785/whats-the-difference-between-git-switch-and-git-checkout-branch)
  - Command comparison

## Branches

[Show git ahead and behind info for all branches, including remotes](https://stackoverflow.com/questions/7773939/show-git-ahead-and-behind-info-for-all-branches-including-remotes)

```sh
git for-each-ref --format="%(refname:short) %(upstream:track) %(upstream:remotename)" refs/heads
```

### Clone and switch to a branch

```sh
git checkout -b new-branch-name origin/new-branch-name
```

You can do it in one shot with `git`—create the local branch **with the same name** and set it to
track the remote branch.

Assuming the remote is `origin` and the branch is `my-feature`:

```bash
git fetch origin
git checkout -b my-feature origin/my-feature
```

That:

- creates local branch `my-feature`
- sets its upstream to `origin/my-feature` (so `git pull`/`git push` work without extra args)

---

On newer Git, there’s also this shorter form:

```bash
git fetch origin
git switch --track origin/my-feature
```

If the local branch doesn’t exist yet, this will:

- create a local `my-feature`
- automatically track `origin/my-feature`

You can confirm they’re associated with:

```bash
git status
# or
git branch -vv
```

### Rename a branch

- [Git Rename Branch – Learn How to Rename a Local and Remote Git Branch](https://www.hostinger.com/tutorials/how-to-rename-a-git-branch/#How_to_Rename_a_Local_Git_Branch)

Rename local branch:

```sh
git checkout old-name
git branch -m new-name
# or
git checkout master
git branch -m old-name new-name
```

Rename remote branch:

```sh
# deleting and creating new
git push origin --delete old-name
git push origin -u new-name
# or by by overwriting it
git push origin :old-name new-name
git push origin –u new-name
```

### Delete branches

delete branches multiple

- [Delete multiple remote branches in git](https://stackoverflow.com/questions/10555136/delete-multiple-remote-branches-in-git)

```sh
git branch -r | awk -F/ '/\/PREFIX/{print $2}' | xargs -I {} git push origin :{}
```

Clean branches fetched from other (remotes) repositories:

```sh
git remote update --prune
```

## Merge / Diff conflicts

https://github.com/sindrets/diffview.nvim
https://stackoverflow.com/questions/6412516/configuring-diff-tool-with-gitconfig
https://stackoverflow.com/questions/70552371/is-there-a-neovim-version-of-vimdiff
https://smittie.de/posts/git-mergetool/ simulate / create a merge conflict
https://www.rosipov.com/blog/use-vimdiff-as-git-mergetool/

### Merge just a file/path from another branch

merge file / merge path / merge dir

[How can I selectively merge or pick changes from another branch in Git?](https://stackoverflow.com/questions/449541/how-can-i-selectively-merge-or-pick-changes-from-another-branch-in-git)

tldr;

```sh
git checkout source_branch -- path/to/file
# resolve conflicts if any
git commit -am '...'
```

### merge from stash

- [How to resolve git stash conflict without commit?](https://stackoverflow.com/questions/7751555/how-to-resolve-git-stash-conflict-without-commit)

```sh
git restore --staged <file>...
git restore --staged .
```

## Development & release workflow

The canonical branch model and release process — `develop` integrates, `master` holds releases, and
CI promotes on a tag — now lives in the general shelf. This README keeps only the git command
mechanics; the workflow model and its per-language bindings are documented there:

- [Development & release workflow — general principles](../../programming/release-workflow/) — the
  `develop`/`master` branch model, the automated release-PR pattern, and Trusted Publishing / OIDC.
- [branch-protection/](./branch-protection/) — the platform runbooks and rulesets that **enforce**
  the model (GitHub Rulesets / GitLab protected branches, bypass actor, tag protection).
- [feature-lifecycle.md](./feature-lifecycle.md) + [rebase-workflow.md](./rebase-workflow.md) — the
  day-to-day feature-branch loop that feeds `develop`.

### External reading

- [Git Team Workflows: Merge or Rebase?](https://www.atlassian.com/git/articles/git-team-workflows-merge-or-rebase)
- [Distributed workflows (Pro Git)](https://git-scm.com/book/en/v2/Distributed-Git-Distributed-Workflows)
- [gitworkflows(7)](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/gitworkflows.html)
- [Branching patterns — Martin Fowler](https://martinfowler.com/articles/branching-patterns.html)
- [git-send-email.io](https://git-send-email.io/) — email-based git workflow

## Related

- [Gitolite](./gitolite.md)
  - manage git users and repositories

## Development Docs

- [feature-lifecycle.md](./feature-lifecycle.md)
  - feature-branch lifecycle from creation to merge
- [feature-lifecycle-git-commands.md](./feature-lifecycle-git-commands.md)
  - companion git commands for each lifecycle phase
- [rebase-workflow.md](./rebase-workflow.md)
  - rebasing feature branches onto upstream
- [glab-auth.md](./glab-auth.md)
  - checking, fixing, and setting up `glab` authentication (keyring + HTTPS credential helper)
- [gh-auth.md](./gh-auth.md)
  - checking, fixing, and setting up `gh` authentication (keyring + HTTPS credential helper)
- [branch-protection/](./branch-protection/)
  - GitHub/GitLab branch-protection rulesets, scripts, and workflows
- [workflows/](./workflows/)
  - end-to-end git workflow guides
- [cmds-examples.md](./cmds-examples.md)
  - assorted git command examples
- [diffs.md](./diffs.md)
  - diffing recipes
- [github.md](./github.md)
  - GitHub-specific notes
- [git-qa.md](./git-qa.md)
  - git questions and answers
- [git-commit-signing-with-ssh-git-commit-s-cheatsheet.md](./git-commit-signing-with-ssh-git-commit-s-cheatsheet.md)
  - SSH commit-signing cheatsheet

## Resources

[Git Rebase vs Merge Debate feat Theo : DevHour #1 - ThePrimeagen](https://www.youtube.com/watch?v=7gEbHsHXdn0)

[Solving git merge conflicts with VIM](https://medium.com/prodopsio/solving-git-merge-conflicts-with-vim-c8a8617e3633)
[Understanding Git conflict markers](https://wincent.com/wiki/Understanding_Git_conflict_markers)
[Git merge conflict cheatsheet](https://wincent.com/wiki/Git_merge_conflict_cheatsheet)
[Vim universe. Vim as a merge tool](https://www.youtube.com/watch?v=VxpCgQyUXlI)

## General

---

**git log to json**[^1]

- [mergestat-lite](https://github.com/mergestat/mergestat-lite)
  - cli to query git log as a SQL
  - outputs as json too

---

Personalize a ssh command used by git clone (example):

- [Git on custom SSH port](https://stackoverflow.com/questions/5767850/git-on-custom-ssh-port)

```sh
GIT_SSH_COMMAND="ssh -v -p 202 -o IdentitiesOnly=yes -i ~/.ssh/<private_key>" \
git clone <user>@<server>:gitolite-admin
```

```sh
# [Force git to use specific key.pub](https://stackoverflow.com/questions/41385199/force-git-to-use-specific-key-pub)
git config --local core.sshCommand 'ssh -i <path-to-key>'
```

- [A Beginner’s Guide to Git — What is a Changelog and How to Generate it](https://www.freecodecamp.org/news/a-beginners-guide-to-git-what-is-a-changelog-and-how-to-generate-it/)

squash commits

- [How to Squash Commits in Git](https://phoenixnap.com/kb/git-squash)

  - Squashing during git merge.
  - Squashing via interactive git rebase.
  - Squashing through a pull request.
  - Squashing via git reset.

- libgit2

  - python: https://www.pygit2.org/recipes/git-commit.html
  - rust: https://docs.rs/git2/latest/git2/
    - https://siciarz.net/24-days-rust-git2/

- Git Objects:
  [10.2 Git Internals - Git Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)

config git local info config
[How to store a git config as part of the repository?](https://stackoverflow.com/questions/18329621/how-to-store-a-git-config-as-part-of-the-repository)

```
git config --local include.path ../.gitconfig
```

---

Clear Entire Git Cache

```
git rm -r --cached .
git add .
git commit -am 'Removed files from the index (now ignored)'
```

---

Git add all[^1]

```
git add .
git add -A #--all
```

- `.`: from the relative path where command is executed
- `-A`/`--all`: recursevely, from the root of the project (`.git`), all the project files

---

- `git rm` = `rm` + `git add`

---

**git encryption / git secret**

- few files (.env, passwords, database logins, etc...)

- <https://git-secret.io/>

- <https://github.com/AGWA/git-crypt>

- <https://github.com/elasticdog/transcrypt>

- hole repository

- <https://gist.github.com/polonskiy/7e5d308ca6412765927a96bd74601a5e>

- <https://github.com/spwhitton/git-remote-gcrypt>

- <https://superuser.com/questions/1162907/setting-up-an-encrypted-git-repository>

- [https://git-annex.branchable.com/tips/fully\\\_encrypted\\\_git\\\_repositories\\\_with\\\_gcrypt/](https://git-annex.branchable.com/tips/fully%5C_encrypted%5C_git%5C_repositories%5C_with%5C_gcrypt/)

---

[^android_note_git] note taking markdown mobile android integrated with git:
https://play.google.com/store/apps/details?id=io.gitjournal.gitjournal
https://play.google.com/store/apps/details?id=io.spck
https://play.google.com/store/apps/details?id=com.foxdebug.acodefree
https://play.google.com/store/apps/details?id=com.rhmsoft.edit

- merge branch logic:

  - checkout the branch where you want to bring the commit
  - just as a remote (github): I'm working in my local, checked out, and run git remote to bring the
    changes from outside repos

- if you decide to quit the merge: `git merge --abort`

  - if you have already committed, to rollback and erase last commit, run:
    `git reset --hard ORIG_HEAD`

- https://github.com/rbong/vim-flog/

  - Flog is a lightweight and powerful git branch viewer that integrates with fugitive.

**git clients:**

- https://github.com/FredrikNoren/ungit
  - web interface
  - aur: nodejs-ungit
- https://github.com/git-up/GitUp
  - doesn't have in aur or archpkg

merge tools:

- https://github.com/samoshkin/vim-mergetool
  - [Vim universe. Vim as a merge tool](https://www.youtube.com/watch?v=VxpCgQyUXlI)
  - [Github samoshkin/vim-mergetool: Efficient way of using Vim as a Git mergetool](https://www.reddit.com/r/vim/comments/b0jjgw/github_samoshkinvimmergetool_efficient_way_of/)
    - difference between vim-mergetool and fugitive

## References

[^1]: [Git : How to recursively add all files or folders to a repository?](https://thispointer.com/git-how-to-recursively-add-all-files-or-folders-to-a-repository/)
