# Workflows

Cross-cutting workflow notes that are not tied to one language or tool.

- [development-tools-workflow.md](development-tools-workflow.md) — the three-role project convention
  (Nix/devShell environment + dependency manager + task runner).
- [mise.md](mise.md) — the `mise` version manager.
- [claude-self-debug-loop.md](claude-self-debug-loop.md) — a Claude self-debugging loop.

## Moved

The development/release workflow docs that used to live here have been reorganized:

- The **general release workflow** (branch model, release-PR pattern, Trusted Publishing) now lives
  at [tech/programming/release-workflow/](../programming/release-workflow/), with per-language
  bindings under `tech/languages/*/release-workflow-spec/`.
- The **bash program release** guide moved to
  [tech/languages/bash/release-workflow-spec/](../languages/bash/release-workflow-spec/).
- The duplicated **git rebase** reference was merged into the canonical
  [tech/tools/git/rebase-workflow.md](../tools/git/rebase-workflow.md).
