# Exec-Queue Entry Schema

Shared schema for entries in the file-based exec-queue system. All `xq-add-*` skills construct
entries following this schema. The `xq-start` coordinator dispatches entries by reading the `kind`
field and validating the payload against the per-kind definition below.

## Top-Level Structure

Every entry is a JSON file in `$COORD_DIR/pending/` with this shape:

```json
{
  "id": "<ENTRY_ID>",
  "kind": "<kind>",
  "payload": {},
  "branch_name": "auto/<ENTRY_ID>",
  "base_branch": "<BASE_BRANCH>",
  "enqueued_at": "<UTC ISO 8601>",
  "enqueued_from_pid": "<PPID as number>",
  "attempts": 0
}
```

### Field definitions

| Field               | Type   | Description                                                         |
| ------------------- | ------ | ------------------------------------------------------------------- |
| `id`                | string | Unique ID: `YYYYMMDDTHHMMSS-<slug>` (UTC, kebab-case slug)          |
| `kind`              | string | Entry type — determines payload schema and executor skill           |
| `payload`           | object | Kind-specific fields (see below)                                    |
| `branch_name`       | string | Git branch for the execution: `auto/<id>`                           |
| `base_branch`       | string | Branch to base the work on (usually current branch at enqueue time) |
| `enqueued_at`       | string | ISO 8601 UTC timestamp of enqueue time                              |
| `enqueued_from_pid` | number | PID of the Claude Code session that enqueued the entry              |
| `attempts`          | number | Retry counter, starts at 0                                          |

## Per-Kind Payload Schemas

### `plan-md`

Executor: `plan-exec` skill.

```json
{
  "plan_path": "<absolute path to plan .md file>",
  "request": "<human-readable description of what the plan does>",
  "review_loop": true | false
}
```

### `prex-resume`

Executor: `prex-resume` skill.

```json
{
  "run_dir": "<absolute path to copied run directory>",
  "plan_thread_id": "<Codex thread ID from stage 1>",
  "review_loop": true | false,
  "original_run_dir": "<path to the source run directory>",
  "request_summary": "<first 200 chars of request.md>"
}
```

### `spec-md`

Executor: `spec-impl` skill.

```json
{
  "spec_path": "<absolute path to spec .md file>",
  "mode": "auto-approve"
}
```

### `task`

Executor: `prex` skill.

```json
{
  "description": "<task description text>",
  "mode": "auto-approve-review-loop"
}
```

## Entry Lifecycle

```text
pending/  ──[coordinator claims via atomic mv]──→  processing/
                                                       │
                                          ┌────────────┴────────────┐
                                          ▼                         ▼
                                     completed/                  failed/
```

- **Claiming**: atomic `mv` from `pending/` to `processing/`. Only the coordinator does this.
- **Completion**: `mv` from `processing/` to `completed/` after successful execution.
- **Failure**: `mv` from `processing/` to `failed/` with `attempts` incremented.
- **Retry**: `xq-retry` moves from `failed/` back to `pending/`.
