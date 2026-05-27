---
digest-of: tech/tools/claude-code/plan-rounds
last-synced: 2026-05-27
source-files:
  - complexity-heuristic.md
  - plan-lifecycle.md
  - round-templates.md
token-estimate: 800
---

# AGENTS

## Scope

Implementation plan lifecycle: complexity grading, round splitting, plan directory structure, round
file contracts, and templates for README.md, round files, and STRATEGY.md.

## Key Points

### Complexity Heuristic

- Five axes (1-4 each): files to change, cross-cutting concerns, dependency chains, pattern novelty,
  risk/blast radius.
- Grades: S (5-7, 1 round), M (8-11, 1 round), L (12-15, 2-4 rounds), XL (16-20, 4-8 rounds).
- Override when: few files but 500+ LOC each, security-sensitive, or mechanical rename across many
  files.

### Plan Lifecycle

- Plans live in `.plan/01-todo/<slug>/`. Completed plans move to `.plan/02-done/<slug>/`.
- Each round file (`NN-<topic>.md`) is self-contained: full context, previous round summary, scope,
  implementation steps, acceptance criteria.
- Rounds sized for one Codex 600s session: 3-8 file changes, one cohesive chunk.
- Execution: `/prex -ar <round-file>`. README.md tracks progress via execution-order table.

### Round Splitting Rules (priority order)

1. Module/subsystem boundaries.
2. Layer boundaries (bottom-up: data -> logic -> API -> UI).
3. Dependency order (no circular deps between rounds).
4. Size cap (3-8 files per round).
5. Atomic changes never split across rounds.
6. Foundations first (types, interfaces, utilities in round 01).
7. Tests with code (same round), except dedicated integration round at end.

### Templates

- **Round file**: Context, Previous Rounds, Scope, Current State (key files + patterns),
  Implementation Steps, final step updates plan index, Acceptance Criteria, Next Round preview.
- **README.md**: Problem statement, strategy, execution order table, execution commands, decisions,
  rejected alternatives, risks.
- **STRATEGY.md** (XL only): Architectural overview, round dependency graph, risk mitigation,
  cross-cutting concerns.

## Source Map

| Topic                                                           | File                      |
| --------------------------------------------------------------- | ------------------------- |
| Five-axis scoring, grade mapping, override guidance             | `complexity-heuristic.md` |
| Directory structure, slug rules, round file contract, lifecycle | `plan-lifecycle.md`       |
| Template A (round), Template B (README), Template C (STRATEGY)  | `round-templates.md`      |

## Maintenance Notes

- Templates use `{{PLACEHOLDER}}` markers for skill substitution.
- The executor capacity model assumes Codex 600s timeout; update if timeout changes.
