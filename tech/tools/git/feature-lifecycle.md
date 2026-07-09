# Feature Lifecycle

Every code change starts from a forge issue. Three entry points — from an existing issue, from a new
issue, and from uncommitted changes — converge on a shared lifecycle of sync, work, finish, cleanup,
and release.

A **work-clone** is an isolated clone of the repository created with `git clone --reference`, placed
as a sibling directory: `~/Projects/<org>/<repo>.<issue>-<slug>`. It shares the main repo's object
store so disk usage is minimal. See
[feature-lifecycle-git-commands](./feature-lifecycle-git-commands.md) for the exact commands.

Related docs:

- [feature-lifecycle-git-commands](./feature-lifecycle-git-commands.md) — companion git commands for
  each phase
- [rebase-workflow](./rebase-workflow.md) — branching and rebase conventions

---

## Entry Points

### From an existing issue

Pick up a planned or triaged issue that already exists on the forge.

1. Use the forge CLI to create a branch from the issue — the forge names the branch automatically
2. Fetch the branch and create a work-clone using the forge-provided branch name
3. Optionally open the work-clone in a new terminal window with a standard layout for editing and
   running agents

### From a new issue

No existing issue yet — create one from the CLI (preferred) or the web UI.

1. Create the issue on the forge — the CLI returns the ID
2. Use the forge CLI to create a branch from the issue — the forge names the branch automatically
3. Fetch the branch and create a work-clone using the forge-provided branch name
4. Optionally open the work-clone in a new terminal window with a standard layout for editing and
   running agents

### From uncommitted changes

Start here when you already have uncommitted changes on the integration branch and want to move them
into their own issue and work-clone.

1. Save any uncommitted changes in the main repository
2. Create a new issue on the forge with a title and optional labels (labels are auto-created on the
   forge if they don't exist)
3. Use the forge CLI to create a branch from the issue — the forge names the branch automatically
4. Fetch the branch and create a work-clone using the forge-provided branch name
5. Restore the saved changes into the work-clone
6. Optionally open a draft pull request against the integration branch

---

## Shared Lifecycle

### Sync

Push the feature branch to the remote to keep local and remote in sync. Mark the issue as
in-progress on the forge, either through the CLI or the web UI.

The branch and work-clone share the same name, derived from the issue slug.

### Work

Commit and push changes in the work-clone. Rebase onto the integration branch as needed to stay
current. See [rebase-workflow](./rebase-workflow.md) for the rebasing strategy.

### Finish

Two paths, both initiated from the work-clone:

- **Draft pull request** — push the branch and open a draft PR or MR on the forge. The work-clone
  stays open for further work.
- **Pull request** — push the branch and open a full PR or MR. The work-clone stays open until the
  PR is merged.

Both paths print the PR URL and exit.

### Cleanup

After the PR is merged on the forge:

1. Pull the target branch in the main repo to pick up the merge
2. Remove the work-clone
3. Delete the local feature branch — the forge auto-deletes the remote branch on merge
4. Close the terminal window if one was opened

### Release

From the main repository, open a PR from the integration branch into the default branch on the
forge, merge remotely, pull locally, tag the release, and push the tag. See
[feature-lifecycle-git-commands](./feature-lifecycle-git-commands.md) for the full command
reference.

---

## Forge Support

GitHub and GitLab are auto-detected from the origin remote URL. All workflow commands use the same
detection logic.

Labels provided during the "from uncommitted changes" entry point are auto-created on the forge if
they don't already exist.

### Native Issue-Branch Linking

- **GitHub**: `gh issue develop` creates a linked branch visible in the issue's Development sidebar.
  The workflow calls this automatically before creating the work-clone.
- **GitLab**: linking happens via MR creation with `glab mr create --related-issue`.

---

## Planned

- Local issue management as an alternative to forge issues for offline and local-first workflows
- Kanban automation to move issues between board columns on state transitions (in-progress on branch
  push, done on merge)
