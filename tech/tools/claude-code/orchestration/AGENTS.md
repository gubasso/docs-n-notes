---
digest-of: tech/tools/claude-code/orchestration
last-synced: 2026-05-27
source-files:
  - orchestration-patterns.md
  - queue-entry-schema.md
  - verdict-model.md
token-estimate: 800
---

# AGENTS

## Scope

Reusable orchestration patterns for multi-stage Claude Code + Codex workflows: sandbox detection,
proof-of-delegation, lock files, review-loop handoff, exec-queue schema, and verdict/severity model.

## Key Points

### Sandbox Detection

- Run once per workflow, not per stage. Persist `SANDBOX_MODE` by literal substitution.
- Fallback: `-c 'sandbox_permissions=...'` for read-only;
  `--dangerously-bypass-approvals-and-sandbox` for write.

### Proof-of-Delegation

- Pre-snapshot -> delegate via Agent tool -> post-snapshot + diff -> validate output file and proof
  diff exist.
- Fail closed on missing evidence. Never retry automatically; never fall back to inline work.

### Lock File Management

- Location: `${XDG_RUNTIME_DIR:-/tmp}/`. Two-line content: `$RUN_DIR` path and owning `$PPID`.
- Atomic creation via write-to-tmp + `mv`. Release before user-facing pauses; reacquire after.

### Exec-Queue Entry Schema

- Top-level: `id`, `kind`, `payload`, `branch_name`, `base_branch`, `enqueued_at`, `attempts`.
- Kinds: `plan-md`, `prex-resume`, `spec-md`, `task`.
- Lifecycle: `pending/` -> `processing/` (atomic `mv`) -> `completed/` or `failed/`.

### Verdict and Severity Model

- Verdicts: `APPROVED`, `APPROVED_WITH_CONDITIONS`, `CHANGES_REQUIRED`, `REJECTED`.
- Severities: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`, `INFO`.
- Categories: correctness, security, performance, reliability, maintainability, compatibility.

## Source Map

| Topic                                                 | File                        |
| ----------------------------------------------------- | --------------------------- |
| Sandbox probe, delegation, locks, review-loop handoff | `orchestration-patterns.md` |
| Queue entry JSON schema (4 kinds)                     | `queue-entry-schema.md`     |
| Verdict enum, severity levels, finding categories     | `verdict-model.md`          |

## Maintenance Notes

- Patterns here are contracts used by multiple skills (prex, plan-exec, review-loop, merge-queue).
- Queue schema must stay backward-compatible; new kinds are additive.
