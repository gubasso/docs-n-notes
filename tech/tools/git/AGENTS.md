---
digest-of: tech/tools/git
last-synced: 2026-07-06
source-files:
  - README.md
  - cmds-examples.md
  - diffs.md
  - feature-lifecycle-git-commands.md
  - feature-lifecycle.md
  - git-commit-signing-with-ssh-git-commit-s-cheatsheet.md
  - git-qa.md
  - github.md
  - gitolite.md
  - glab-https-git-credential-helper-setup.md
  - rebase-workflow.md
  - workflows/gh-cli-workflow.md
  - workflows/glab-cli-workflow.md
  - workflows/make-origin-match-your-local-branch-state.md
token-estimate: 14700
---

# AGENTS

## Scope

Git command references and workflow notes. Top-level material covers day-to-day commands, branching,
diffs, and repo administration; subtrees cover branch protection and workflow-specific runbooks.

## Key Points

- **Commands**: Practical command snippets for checkout, branching, merge handling, and conflict
  recovery.
- **Branching**: Feature-lifecycle notes and related command sequences for local and remote branch
  work.
- **Administration**: GitHub, Gitolite, and GitLab credential or repository management notes.
- **Workflows**: Rebase and origin-state runbooks for repeatable branch operations.
- **Comparison material**: Diffs and command examples complement the workflow guides.

## Source Map

| Topic                                  | File / Subtree                                                          |
| -------------------------------------- | ----------------------------------------------------------------------- |
| Command examples and conflict handling | `cmds-examples.md`, `diffs.md`                                          |
| Feature lifecycle and branch commands  | `feature-lifecycle*.md`                                                 |
| Commit signing and QA notes            | `git-commit-signing-with-ssh-git-commit-s-cheatsheet.md`, `git-qa.md`   |
| GitHub, Gitolite, GitLab setup         | `github.md`, `gitolite.md`, `glab-https-git-credential-helper-setup.md` |
| Rebase workflow reference              | `rebase-workflow.md`                                                    |
| Branch protection workflows            | `branch-protection/`                                                    |
| Workflow runbooks                      | `workflows/`                                                            |

## Maintenance Notes

- Branch protection has its own AGENTS digest.
- Workflow runbooks are summarized here because they do not have a separate digest.
