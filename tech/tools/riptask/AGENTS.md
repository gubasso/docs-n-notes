---
digest-of: tech/tools/riptask
last-synced: 2026-06-01
source-files:
  - README.md
  - commands.md
token-estimate: 600
---

# AGENTS

## Scope

`riptask` (`tsk` binary) plaintext issue tracker: CLI usage reference for skills that invoke `tsk` —
preflight/readiness checks, command overview, and the full `tsk new` contract. The `tsk` binary is
authoritative; these notes capture stable patterns.

## Key Points

### Preflight (before any `tsk` command)

- `tsk` must be on `$PATH`.
- Readiness gate for `tsk new` is **`$RIPTASK_REPO/config.yaml` existing** (what
  `require_shared_layer` stats); the default `templates/task.md` must also exist unless `-T` is
  passed.
- Resolve the store path from `tsk doctor` (it prints `riptask_repo = <path>`), then stat
  `config.yaml`. **`tsk doctor` always exits 0** — never gate on its exit code.
- Safe init fallback: `tsk init --system` **only when `config.yaml` is absent** (explicit scope =
  non-interactive). **Never `--force`** — it overwrites a complete config with defaults.
- `tsk new` works fully offline; backend registration is only for sync commands.

### `tsk new` contract

- Title/body: `-t/--title` bypasses AI title generation, `-d/--description` bypasses AI body
  generation; `--ai` forces generation of fields you did NOT provide (independent of `-d`).
- Other flags: `-p` project, `-b` board, `-s` status, `-P` priority, `-T` template, `-e` open
  `$EDITOR`.
- Long/multi-line bodies: write to a temp file, pass via `-d "$(cat "$BODY_FILE")"`. There is no
  `--description-file` or stdin mode.
- Output: non-TTY prints **ID on line 1** (optional remote URL on line 2 when synced); the **file
  path is NOT printed** — resolve it with `tsk path <id>`. TTY prints a decorated summary.
- `tsk new` reads the git working-tree diff for AI context **only when `-t` is omitted**; passing
  both `-t` and `-d` bypasses that, so the caller must read repo state itself.
- Non-zero exit means the issue was NOT created — do not swallow stderr.

## Source Map

| Topic                                                 | File          |
| ----------------------------------------------------- | ------------- |
| Overview and purpose                                  | `README.md`   |
| Preflight, command overview, full `tsk new` reference | `commands.md` |

## Maintenance Notes

- Usage patterns are tied to the `tsk` binary version (notes synced against riptask 0.2.0).
  Re-verify flags, output format, and the `require_shared_layer` gate when upgrading.
- Consumers: the `tsk-new`, `tsk-impl`, and `prex` Claude skills, which load `commands.md` via
  `$DOCS_NOTES_REPO/tech/tools/riptask/commands.md`.
