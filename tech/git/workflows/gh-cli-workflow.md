# gh cli workflow

> This keeps `master` to mirror your original flow. If your repository uses a different default branch (for example `main`), replace `master` accordingly. `gh issue develop` defaults to the repository’s default branch unless you pass `--base`, and `gh pr create` also defaults to the configured merge base or repo default branch when `--base` is omitted. ([GitHub CLI][1])

## 00 — Check Auth

```bash
gh auth status
```

## 01 — Open an Issue

```bash
gh issue create \
  --title "feat: short title" \
  --body "description" \
  --assignee @me \
  --label "in-progress"
```

> `gh issue create` supports `--title`, `--body`, `--assignee`, and `--label`. If you also use GitHub Projects, `--project` is available, but project operations require the `project` scope. GitHub Projects status can also be edited from CLI with `gh project item-edit`, though that is heavier than using labels as workflow proxies. ([GitHub CLI][2])

---

## 02 — Create PR + Branch from Issue

```bash
# If no new commits or changes yet
git commit --allow-empty \
  -m "chore: open draft PR for #<issue-id>" \
  -m "Temporary empty commit used to trigger CI and open a draft PR for issue #<issue-id>."
git push -u origin HEAD

gh issue develop <issue-id> \
  --checkout \
  --name "<issue-id>-issue-title-slug" \
  --base master

gh pr create \
  --draft \
  --base master \
  --title 'Draft: Resolve "<issue title>"' \
  --body "Closes #<issue-id>"
```

Closest equivalent to GitLab’s “Create merge request” flow:

* Branch → use `gh issue develop <issue-id> --name "<issue-id>-issue-title-slug"` to create and link a branch to the issue
* PR title → set explicitly with `--title 'Draft: Resolve "<issue title>"'`
* PR description → include `Closes #<issue-id>` in `--body` so the issue auto-closes on merge

> `gh issue develop` is the GitHub CLI command for linked issue branches and can check the branch out immediately. `gh pr create` supports `--draft`, `--base`, `--title`, and `--body`. GitHub closes linked issues automatically when the PR body contains a closing keyword like `Closes #123` or `Fixes #123`. Unlike `glab mr create --related-issue`, this is a two-command flow in `gh`. ([GitHub CLI][1])

---

## 03 — Pull Branch Locally

```bash
gh pr checkout <pr-id>
```

> `gh pr checkout` checks out a specific pull request locally; by default it uses the PR head branch name as the local branch name. ([GitHub CLI][3])

---

## 04 — Work & Sync (Rebase Workflow)

```bash
git fetch origin
git rebase origin/master
git push --force-with-lease origin HEAD

# Check CI
gh pr checks --watch
gh run watch    # watch a workflow run
gh run view     # summary/logs for a run
```

> `gh pr checks` shows CI status for the PR and supports `--watch`. `gh run watch` watches a workflow run until completion, and `gh run view` shows a workflow run summary. ([GitHub CLI][4])

---

## 05 — Mark Ready for Review

```bash
gh pr ready <pr-id>
gh pr edit <pr-id> --add-reviewer username
gh issue edit <issue-id> --remove-label "in-progress" --add-label "review"
```

> `gh pr ready` marks a draft PR as ready for review. Reviewers are added with `gh pr edit --add-reviewer`. Issue labels can be updated with `gh issue edit --add-label` and `--remove-label`. ([GitHub CLI][5])

---

## 06 — Merge into Master

```bash
gh pr merge <pr-id> --rebase --delete-branch

# Close issue if not auto-closed
gh issue close <issue-id>
```

> `gh pr merge` supports `--rebase` and `--delete-branch`. The issue auto-closes if the PR body contains `Closes #<issue-id>` or `Fixes #<issue-id>`; otherwise `gh issue close` is the manual fallback. ([GitHub CLI][6])

---

## Quick Reference

| Action                | Command                                    |
| --------------------- | ------------------------------------------ |
| List your open PRs    | `gh pr list --assignee "@me" --state open` |
| List open issues      | `gh issue list`                            |
| Open PR in browser    | `gh pr view <pr-id> --web`                 |
| Open issue in browser | `gh issue view <id> --web`                 |
| Approve a PR          | `gh pr review <pr-id> --approve`           |
| Add PR comment        | `gh pr comment <pr-id> --body "comment"`   |
| Auth status           | `gh auth status`                           |

> Current `gh` supports PR listing/filtering by assignee, issue listing, PR/issue browser opening, PR approval, PR comments, and auth status with the commands above. ([GitHub CLI][7])

[1]: https://cli.github.com/manual/gh_issue_develop "GitHub CLI | Take GitHub to the command line"
[2]: https://cli.github.com/manual/gh_issue_create "GitHub CLI | Take GitHub to the command line"
[3]: https://cli.github.com/manual/gh_pr_checkout?utm_source=chatgpt.com "GitHub CLI | Take GitHub to the command line"
[4]: https://cli.github.com/manual/gh_pr_checks "GitHub CLI | Take GitHub to the command line"
[5]: https://cli.github.com/manual/gh_pr_ready "GitHub CLI | Take GitHub to the command line"
[6]: https://cli.github.com/manual/gh_pr_merge "GitHub CLI | Take GitHub to the command line"
[7]: https://cli.github.com/manual/gh_pr_list "GitHub CLI | Take GitHub to the command line"
