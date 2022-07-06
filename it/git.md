# Git
> $git

<!-- vim-markdown-toc GitLab -->

* [Related](#related)
* [Resources](#resources)
* [General](#general)

<!-- vim-markdown-toc -->

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

- `git rm` = `rm` + `git add`

---

**git workflows:**

* <https://git-scm.com/book/en/v2/Distributed-Git-Distributed-Workflows>
* <https://mirrors.edge.kernel.org/pub/software/scm/git/docs/gitworkflows.html>
* <https://martinfowler.com/articles/branching-patterns.html>

**git encryption**

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
