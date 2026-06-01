# tsk CLI Specification

> Shared reference for LLM skills and processes that invoke `tsk` (the `riptask` plaintext issue
> tracker). Read this before running any `tsk` command. The `tsk` binary is the source of truth —
> this file captures the stable usage patterns; when in doubt, run `tsk <command> --help`. Consumers
> today: the `tsk-new`, `tsk-impl`, and `prex` Claude skills, which resolve this file via
> `$DOCS_NOTES_REPO/tech/tools/riptask/commands.md`.

## What is tsk

`tsk` is a plaintext issue tracker — manage issues, boards, and sync from the terminal. Issues are
stored as files in a tsk-initialized workspace and can be synced to GitHub / GitLab.

## Preflight

Before invoking any `tsk` command, verify:

1. **`tsk` is in `$PATH`:**

   ```bash
   command -v tsk >/dev/null 2>&1 || { echo "tsk not installed"; exit 1; }
   ```

2. **The shared store is initialized.** The readiness gate for `tsk new` is
   **`$RIPTASK_REPO/config.yaml` existing** — that is exactly what `require_shared_layer` stats. The
   default `templates/task.md` must also exist (needed unless `-T` is passed). Discover the resolved
   store path from `tsk doctor` (it prints `riptask_repo = <path>`), then check the file:

   ```bash
   REPO="$(tsk doctor 2>/dev/null \
     | sed -n 's/^[[:space:]]*riptask_repo[[:space:]]*=[[:space:]]*//p' | head -n1)"
   REPO="${REPO:-${RIPTASK_REPO:-${XDG_DATA_HOME:-$HOME/.local/share}/riptask}}"
   [ -f "$REPO/config.yaml" ] || echo "store not initialized at $REPO"
   ```

   **Do NOT gate on `tsk doctor`'s exit code — it always exits 0**, even when the effective config
   fails to load. Use it only to read the resolved path and the `[x]/[ ]` layer checklist.

   Safe init fallback: run `tsk init --system` **only when `config.yaml` is absent** (explicit scope
   = non-interactive). **Never `--force`** — it overwrites an existing complete config with
   defaults, clobbering customizations.
3. **Backend registration is only needed for sync-related commands.** `tsk new` works fully offline.

## Top-level commands (overview)

| Command                              | Purpose                               |
| ------------------------------------ | ------------------------------------- |
| `tsk new`                            | Create a new issue                    |
| `tsk ls`                             | List issues                           |
| `tsk show <id>`                      | Display issue details                 |
| `tsk edit <id>`                      | Open issue in `$EDITOR`               |
| `tsk close <id>` / `tsk reopen <id>` | Change open/closed state              |
| `tsk rm <id>`                        | Permanently remove an issue           |
| `tsk path <id>`                      | Print on-disk path of an issue        |
| `tsk status <id> <status>`           | Change issue status                   |
| `tsk branch`                         | Create/switch/delete issue branch     |
| `tsk id`                             | Print issue id for current git branch |
| `tsk commit`                         | AI-assisted git commit                |
| `tsk pr`                             | Create/edit/show a PR/MR              |
| `tsk start` / `tsk done`             | Workflow helpers                      |
| `tsk clone` / `tsk unclone`          | Work-clone management                 |
| `tsk sync`                           | Sync with GitHub/GitLab               |
| `tsk board` / `tsk view`             | Board views                           |
| `tsk init`                           | Initialize a workspace                |
| `tsk template`                       | Manage issue templates                |

Run `tsk <command> --help` for authoritative flag lists.

## `tsk new`

Creates a new issue. `tsk` generates the timestamp and slug automatically — do NOT try to construct
an ID by hand.

Flags:

| Flag                        | Purpose                                                                                        |
| --------------------------- | ---------------------------------------------------------------------------------------------- |
| `-t, --title <TITLE>`       | Explicit title. Bypasses AI title generation.                                                  |
| `-d, --description <DESC>`  | Explicit body. Bypasses AI body generation.                                                    |
| `--ai`                      | Force AI to fill missing fields (use when only `-t` is given and you want the body generated). |
| `-p, --project <PROJECT>`   | Target project.                                                                                |
| `-b, --board <BOARD>`       | Board to assign.                                                                               |
| `-s, --status <STATUS>`     | Initial status.                                                                                |
| `-P, --priority <PRIORITY>` | Priority level.                                                                                |
| `-T, --template <TEMPLATE>` | Template to use.                                                                               |
| `-e, --edit`                | Open in `$EDITOR` after creation.                                                              |

### Canonical invocation (fully specified, no AI)

```bash
tsk new -t "<full descriptive title>" -d "<body>"
```

### Long or multi-line bodies

Do NOT inline multi-line content on the command line — shell quoting breaks on backticks, `$`, and
mismatched quotes. Instead, write the body to a temp file, then substitute:

```bash
STAGE_DIR="$(mktemp -d /tmp/tsk-new-XXXXXX)"
BODY_FILE="$STAGE_DIR/body.md"
# Write the body to $BODY_FILE first (Write tool or heredoc).
tsk new -t "$TITLE" -d "$(cat "$BODY_FILE")"
```

`$(cat file)` preserves newlines and UTF-8 intact when passed as a single `-d` argument. There is no
`--description-file` or `-d -` stdin mode.

### What `tsk new` prints

On success:

- **Non-TTY (piped/redirected):** the created issue **ID on line 1**, and an optional **remote URL
  on line 2** (only when the issue is backend-synced). The **file path is NOT printed.**
- **TTY:** a decorated multi-line summary (ID, Title, Project, Board, Status, Priority, optional
  URL).

To get the on-disk path, resolve it explicitly with `tsk path <id>` — `tsk new` does not emit it.

### AI / git-context behavior

`tsk new` only reads the git working-tree diff (for AI title/body generation) when `-t` is
**omitted**. A caller that passes both `-t` and `-d` bypasses that path entirely — so such a caller
must read repo state itself if it wants the diff to inform the title/body.

### What `tsk new` does NOT do

- Does not open `$EDITOR` unless `-e` is passed.
- Does not require network access.
- Does not accept stdin. Long bodies go through `$(cat file)`.

## Related commands a skill may need

- `tsk path <id>` — resolve an ID back to its file path.
- `tsk show <id>` — dump the created issue for verification.
- `tsk ls` — confirm the new issue landed.

## Gotchas

- **`--ai` and `-d` are independent.** `-d` bypasses body AI generation; `--ai` forces generation of
  fields you did NOT provide.
- **`-T/--template` affects body scaffolding.** If a template is specified, the `-d` body may be
  merged into the template — keep that in mind when body structure must be exact.
- **Exit codes are meaningful.** A non-zero exit means the issue was NOT created. Do NOT swallow
  stderr.
