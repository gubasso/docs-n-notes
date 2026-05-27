---
digest-of: tech/tools/claude-code/merge-queue
last-synced: 2026-05-27
source-files:
  - merge-protocol.md
  - usage-examples.md
token-estimate: 700
---

# AGENTS

## Scope

Merge queue protocol internals and usage patterns for coordinated multi-feature merges with
AI-assisted conflict resolution and regression prevention.

## Key Points

### Protocol Stages

1. FETCH_BRANCH: fetch from remote, verify exists.
2. PRE_MERGE_VALIDATION: check PR approval, run pre-merge tests.
3. CONFLICT_DETECTION: dry-run merge (`--no-commit --no-ff`), detect conflicts.
4. EXECUTE_MERGE: clean merge or delegate conflict resolution via Agent tool.
5. POST_MERGE_VALIDATION: run post-merge tests, delegate regression fix if needed.
6. FINALIZE: push, close PR, update metadata.

### State Transitions

- `pending/` -> (atomic `mv`) -> `processing/` -> `completed/` or `failed/`.
- Progress tracked in `.claude-merge-queue/.progress.json`.

### Delegation Protocol

- Conflict resolution: snapshot prex dirs -> delegate to Agent tool (not Skill tool) -> validate
  proof artifacts -> verify merge commit.
- Regression fix: capture test output -> delegate -> re-run tests -> if still failing:
  retry/manual/revert.
- Always `--no-ff` merges. Proof-of-delegation required for both conflict resolution and regression
  fixes.

### Configuration

- `.claude-merge-queue/config.json`: `auto_push`, `auto_close_pr`, `require_pr_approval`,
  `pre_merge_command`, `post_merge_command`, `max_retry_attempts`.

### Error Recovery

- Branch not found -> failed. PR not approved -> failed (retry after approval). Pre-merge tests fail
  -> ABORT.
- Post-merge tests fail -> delegate fix. Push/PR-close fails -> mark merge succeeded, record
  failure.

## Source Map

| Topic                                                                    | File                |
| ------------------------------------------------------------------------ | ------------------- |
| Six-stage protocol, delegation, git operations, config, recovery         | `merge-protocol.md` |
| Basic workflow, concurrent development, delegation flow, troubleshooting | `usage-examples.md` |

## Maintenance Notes

- Sequential processing is current; parallel pre-validation is future work.
- Delegation uses Agent tool (not Skill tool) to avoid nested skill loading issues.
