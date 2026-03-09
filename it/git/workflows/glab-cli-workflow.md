# glab cli workflow

## 01 — Open an Issue

```bash
glab issue create \
  -t "feat: short title" \
  -d "description" \
  -a @me \
  -l "b: in-progress"
```

> Board column movement requires the UI. Use labels (`in-progress`, `review`) as CLI proxies.

---

## 02 — Create MR + Branch from Issue

```bash
glab mr create --related-issue <issueID>
```

Mirrors the "Create merge request" button in the GitLab UI:
- Branch → `<issue-id>-issue-title-slug`
- MR title → `Draft: Resolve "<issue title>"`
- MR description → auto-contains `Closes #<issue-id>`

---

## 03 — Pull Branch Locally

```bash
glab mr checkout <mr-id>
```

---

## 04 — Work & Sync (Rebase Workflow)

```bash
git fetch origin
git rebase origin/master
git push --force-with-lease origin <branch>

# Check CI
glab ci status
glab ci view    # interactive TUI
```

---

## 05 — Mark Ready for Review

```bash
glab mr update <mr-id> --ready
glab mr update <mr-id> --reviewer username
glab issue update <issue-id> -l "review"
```

---

## 06 — Merge into Master

```bash
glab mr merge <mr-id> --rebase --remove-source-branch
glab mr merge 4 --rebase --remove-source-branch

# Close issue if not auto-closed
glab issue close <issue-id>
```

> Issue auto-closes on merge because `glab mr for` adds `Closes #<id>` to the MR description.

---

## Quick Reference

| Action | Command |
|---|---|
| List your open MRs | `glab mr list --assignee @me` |
| List open issues | `glab issue list` |
| Open MR in browser | `glab mr view --web` |
| Open issue in browser | `glab issue view <id> --web` |
| Approve an MR | `glab mr approve <mr-id>` |
| Add MR comment | `glab mr note <mr-id> -m "comment"` |
| Auth status | `glab auth status` |
