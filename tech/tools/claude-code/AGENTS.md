---
digest-of: tech/tools/claude-code
last-synced: 2026-05-28
source-files:
  - README.md
  - codex-conventions.md
  - invocation-cheatsheet.md
  - models-reference.md
  - skills-and-orchestration.md
token-estimate: 10400
---

# AGENTS

## Scope

Top-level index for Claude Code and Codex CLI operational guidance. Subdirectories cover
orchestration, plan rounds, skill authoring, and implementation review practices.

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

| Topic                                                 | File                          |
| ----------------------------------------------------- | ----------------------------- |
| Claude Code operational index                         | `README.md`                   |
| Codex CLI conventions, sandbox, safety rules          | `codex-conventions.md`        |
| Invocation patterns and command cheat sheet           | `invocation-cheatsheet.md`    |
| Model aliases, effort, knowledge cutoffs              | `models-reference.md`         |
| Skills/orchestration integration                      | `skills-and-orchestration.md` |
| Orchestration contracts and patterns                  | `orchestration/`              |
| Plan lifecycle, round templates, complexity heuristic | `plan-rounds/`                |
| Skill specification and house style                   | `skill-authoring/`            |
| Review report template, severity levels               | `implementation-review/`      |

## Maintenance Notes

- Each subdirectory has its own AGENTS.md for detailed digests.
- Claude Code conventions should be re-verified when major upstream behavior changes.
