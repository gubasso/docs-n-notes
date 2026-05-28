---
digest-of: tech/tools/claude-code
last-synced: 2026-05-27
source-files:
  - README.md
  - codex-conventions.md
token-estimate: 600
---

# AGENTS

## Scope

Top-level index for Claude Code and Codex CLI operational guidance. Subdirectories cover
orchestration, planning rounds, skill authoring, merge queue, and implementation review.

## Key Points

- **Codex wrapper**: All Codex invocations use `codex-session` (not raw `codex`). Always
  `--account auto` for quota-aware selection.
- **Sandbox**: Resume-compatible workflows use `--dangerously-bypass-approvals-and-sandbox` for all
  calls. One-shot workflows may use native sandbox flags. See `codex-conventions.md` §Unified
  Sandbox for Resume Workflows.
- **Safety rules**: Stages 1-2 read-only, stage 3 is the only write stage. Always `< /dev/null` to
  prevent stdin blocking. 600s Bash timeout for all Codex calls.
- **Session resumption**: `exec resume <thread-id>` preserves context. Original and resumed calls
  must use the same sandbox flags (see Resume Constraint in `codex-conventions.md`).
- **Behavioral orientation**: Every prompt starts with READ-ONLY or WRITE orientation block.
- **Git**: Codex must never run git commands; all git operations belong to the Claude Code
  orchestrator.

## Source Map

| Topic                                                            | Path                     |
| ---------------------------------------------------------------- | ------------------------ |
| Codex CLI conventions, sandbox, safety rules                     | `codex-conventions.md`   |
| Orchestration patterns (proof-of-delegation, locks, review-loop) | `orchestration/`         |
| Plan lifecycle, round templates, complexity heuristic            | `plan-rounds/`           |
| Skill specification, house style                                 | `skill-authoring/`       |
| Merge protocol, usage examples                                   | `merge-queue/`           |
| Review report template, severity levels                          | `implementation-review/` |

## Maintenance Notes

- Each subdirectory has its own AGENTS.md for detailed digests.
- Codex CLI conventions should be re-verified when `codex-session` major version changes.
