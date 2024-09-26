# Git
> $git

<!-- toc -->

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
- [Git Workflow / gitflow](#git-workflow--gitflow)
  - [Git Feature Branch Workflow](#git-feature-branch-workflow)
- [Related](#related)
- [Resources](#resources)
- [General](#general)
- [References:](#references)

<!-- tocstop -->

## hooks

- https://www.viget.com/articles/two-ways-to-share-git-hooks-with-your-team/

## Commands

### Merge branches (one-liner)

The easiest option is to merge the main branch into the feature branch using something like the following:

```sh
git checkout feature
git merge main
```

Or, you can condense this to a one-liner:

```sh
git merge feature main
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
https://smittie.de/posts/git-mergetool/
simulate / create a merge conflict
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

## Git Workflow / gitflow

- [Git Team Workflows Best Practices: Merge or Rebase?](https://www.atlassian.com/git/articles/git-team-workflows-merge-or-rebase)
- Learn to use email with git! https://git-send-email.io/ (git email workflow)
* <https://git-scm.com/book/en/v2/Distributed-Git-Distributed-Workflows>
* <https://mirrors.edge.kernel.org/pub/software/scm/git/docs/gitworkflows.html>
* <https://martinfowler.com/articles/branching-patterns.html>

### Git Feature Branch Workflow


Project branches:

- master: code in production
- staging: code to be tested
- develop: code in development
    - branches of develop: issues/features/elements to be implemented

#### A) Implementation: `user-dev`

1) Update develop branch

```sh
git checkout develop
git fetch origin
git reset --hard origin/develop
```

2) Create a new branch with the name of the issue/feature/element

```sh
git checkout -b new-feature
```

3) Update, add, commit, and push changes
4) Push feature branch to remote

#### B) Review: Open Pull Request (PR)

1) `user-dev` opens a PR
    - can be just a tag inside the issue `new-feature`
2) `user-reviewr` pulls `new-feature` and starts reviewing the PR's `new-feature` branch

```sh
git pull origin new-feature
git checkout new-feature
```

3) `user-reviewr` reviews `user-dev`'s code
4) `user-dev` can make any adjustments in his local repository and push changes to remote
5) `user-reviewr` pulls new `user-dev` changes and review cicle continues
6) `user-dev` pushes final branch version
7) `user reviewr` pull/pushes final reviewd code, sealing this branch

#### C) Close PR: Merge/Publish feature

1) Merge `develop` to `new-feature` branch

a) ensure that HEAD is pointing to the correct merge-receiving branch
b) Make sure the receiving branch and the merging branch are up-to-date
```sh
git checkout receiving-branch
git fetch
git reset --hard origin/develop
git merge develop
```

2) `user-authority` merges `new-feature` branch to `develop`

2.1) Possible merge strategies:

a) simple merge commit

```sh
git checkout develop
git merge new-feature
```

b) squashes your `new-feature` branch down to one commit

```sh
# https://randyfay.com/comment/1093#comment-1093
git switch develop
git merge --squash new-feature
# above is equal to the following:
git switch feature
git diff main > feature.patch
git switch main
patch -p1 < feature.patch
git add .
```
or
```sh
# merge "dry-run"
# [Is there a git-merge --dry-run option?](https://stackoverflow.com/questions/501407/is-there-a-git-merge-dry-run-option)
git merge --no-commit --no-ff $BRANCH
# to examine the staged changes:
git diff --cached
# And you can undo the merge, even if it is a fast-forward merge:
git merge --abort
```

3) delete that brach from local and remote (if needed)

```sh
git branch -d branch-name
# to delete remote branch too
git push origin -d branch-name
```

Or, to cleanup branches from project, see[^clear-branches].

#### References

- [Git Feature Branch Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow)
- [What is the difference between git pull and git reset --hard origin/<branch>?](https://stackoverflow.com/questions/43037293/what-is-the-difference-between-git-pull-and-git-reset-hard-origin-branch)
- [Git merge conflicts](https://www.atlassian.com/git/tutorials/using-branches/merge-conflicts)
[^clear-branches] [How to Delete Already Merged Git Branches (local and remote)](https://www.w3docs.com/snippets/git/how-to-delete-already-merged-git-branches.html)
    - https://github.com/hartwork/git-delete-merged-branches


## Related

- [Gitolite](./it/git-gitolite.md)
    - manage git users and repositories

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

[^1]: [Git log in JSON format - Full discussion gist](https://gist.github.com/varemenos/e95c2e098e657c7688fd)

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

- Git Objects: [10.2 Git Internals - Git Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects)

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

* few files (.env, passwords, database logins, etc...)
* <https://git-secret.io/>
* <https://github.com/AGWA/git-crypt>
* <https://github.com/elasticdog/transcrypt>

* hole repository
* <https://gist.github.com/polonskiy/7e5d308ca6412765927a96bd74601a5e>
* <https://github.com/spwhitton/git-remote-gcrypt>
* <https://superuser.com/questions/1162907/setting-up-an-encrypted-git-repository>
* [https://git-annex.branchable.com/tips/fully\\\_encrypted\\\_git\\\_repositories\\\_with\\\_gcrypt/](https://git-annex.branchable.com/tips/fully%5C_encrypted%5C_git%5C_repositories%5C_with%5C_gcrypt/)

---

[^android_note_git]
note taking markdown mobile android integrated with git:
https://play.google.com/store/apps/details?id=io.gitjournal.gitjournal
https://play.google.com/store/apps/details?id=io.spck
https://play.google.com/store/apps/details?id=com.foxdebug.acodefree
https://play.google.com/store/apps/details?id=com.rhmsoft.edit

- graphical and simple git log terminal:
    - `git log --online --graph master feature -m 15`
- merge branch logic:
    - checkout the branch where you want to bring the commit
    - just as a remote (github): I'm working in my local, checked out, and run git remote to bring the changes from outside repos
- if you decide to quit the merge: `git merge --abort`
    - if you have already commited, to rollback and erase last commit, run: `git reset --hard ORIG_HEAD`

- https://github.com/rbong/vim-flog/
    - Flog is a lightweight and powerful git branch viewer that integrates with fugitive.

**git clients:**

- https://github.com/FredrikNoren/ungit
    - web interface
    - aur: nodejs-ungit
- https://github.com/git-up/GitUp
    - doen't have in aur or archpkg

merge tools:

- https://github.com/samoshkin/vim-mergetool
    - [Vim universe. Vim as a merge tool](https://www.youtube.com/watch?v=VxpCgQyUXlI)
    - [Github samoshkin/vim-mergetool: Efficient way of using Vim as a Git mergetool](https://www.reddit.com/r/vim/comments/b0jjgw/github_samoshkinvimmergetool_efficient_way_of/)
        - difference between vim-mergetool and fugitive


## Download changes to another branch

You:

I am at master branch and run:
git fetch origin develop:develop

ChatGPT:

The command you ran (`git fetch origin develop:develop`) fetches the `develop` branch from the remote repository (in this case, `origin`) and updates (or creates) a local branch called `develop` to match the remote one.
Here’s a breakdown of the command:

- `git fetch`: Fetches changes from the remote repository without modifying your working directory or active branch.
- `origin`: Refers to the remote repository, which by default is often named `origin`.
- `develop:develop`: The syntax `remote_branch:local_branch`. This means you are fetching the `develop` branch from `origin` and updating or creating a local branch called `develop`.
Since you're currently on the `master` branch, this will not affect your current branch. The fetched branch (`develop`) will be available in your local repository but won't be checked out or merged into `master` unless you explicitly switch to `develop` or merge it.If you want to merge the `develop` branch into `master` after fetching, you could do:

```bash
git merge develop
```
Or, if you want to check out `develop`, you would do:

```bash
git checkout develop
```

## Get the diff from the start of a branch

To get the diff from the start of a branch in Git, you can use the following command:

```bash
git diff $(git merge-base --fork-point <branch_name>)..<branch_name>
```

Here's how it works:
 
1. `git merge-base --fork-point <branch_name>`: This finds the point where the branch diverged from its upstream (i.e., where the branch started).
 
2. `git diff <starting_point>..<branch_name>`: This command then shows the difference between the starting point (where the branch started) and the current state of the branch.

If you're already on the branch, you can simplify it to:


```bash
git diff $(git merge-base --fork-point HEAD)
```

This will show you all the changes from the start of the branch to your current working state.

Let me know if you need further clarification or assistance!

## References:

[^1]: [Git : How to recursively add all files or folders to a repository?](https://thispointer.com/git-how-to-recursively-add-all-files-or-folders-to-a-repository/)
