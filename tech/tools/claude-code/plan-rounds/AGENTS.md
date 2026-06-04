---
digest-of: tech/tools/claude-code/plan-rounds
last-synced: 2026-06-04
source-files:
  - complexity-heuristic.md
  - plan-lifecycle.md
  - round-templates.md
token-estimate: 950
---

# AGENTS

## Scope

Implementation plan lifecycle: complexity grading, round splitting, the `.implementation-plans/`
directory structure, round file contracts, and templates for plan files, queues, READMEs, and
STRATEGY.md.

## Key Points

### Complexity Heuristic

- Five axes (1-4 each): files to change, cross-cutting concerns, dependency chains, pattern novelty,
  risk/blast radius. Sum -> raw score (5-20).
- **Executor Factor (EF)**: divide raw score by EF to get adjusted score. Profiles: `prex` (default,
  EF 1.5), `single-pass` (EF 1.0), `limited` (EF 0.8). EF reflects in-round review capability.
- Grades from adjusted score: S (≤7.0, 1 round), M (7.1-11.0, 1 round), L (11.1-15.0, 2-3 rounds),
  XL (≥15.1, 4-8 rounds). Thresholds == historical raw cutpoints, so EF=1.0 recovers old behavior;
  EF=1.5 demotes borderline tasks one grade; EF=0.8 promotes them one grade.
- Grade selects the output format: S/M -> single-file plan `plans/<slug>.md`; L/XL -> plan directory
  `plans/<slug>/`.
- Override when: few files but 500+ LOC each, security-sensitive, or mechanical rename across many
  files.

### Plan Lifecycle

- `.implementation-plans/` is flat and queue-driven: status/order/deps/command live in YAML, not in
  paths. No `01-todo`/`02-done` kanban dirs, no `NN-` prefixes.
- Root holds `README.md` (static system explainer, bootstrapped once) and `QUEUE.yaml` (repo-wide
  ledger, all plans, full history). All plans live under `plans/`: single-file plans as
  `plans/<slug>.md` (S/M — first-class, fully executable), directory plans as `plans/<slug>/`
  (`README.md` + `QUEUE.yaml` + de-numbered `<topic>.md` round files + `STRATEGY.md` for XL).
- `plans/<slug>/QUEUE.yaml` lists that plan's rounds in execution order; single-file plans have no
  inner queue. `status: backlog|todo|doing|done`. Every entry carries a `prompt`.
- Slugs `readme`, `queue`, `strategy` are reserved (collide with meta files).
- Each round file (`<topic>.md`) is self-contained: full context, previous round summary, scope,
  implementation steps, acceptance criteria.
- Rounds sized for one Codex 600s session, delivering one cohesive feature/layer. File count is
  incidental — mechanically-coupled changes belong together regardless of count.
- Execution: `/prex -ar @.implementation-plans/plans/<slug>/` reads `QUEUE.yaml`, runs the first
  `todo` round, stops. Flip `status` to `doing` when starting a round and `done` when finished;
  nothing moves on disk. Single-file plans flip their entry in the top-level ledger.
- Legacy `.plan/` trees migrate manually (rename root, move plans under `plans/`, drop `_` prefixes,
  rewrite `prompt:` paths); the generating skill detects them and informs, never auto-migrates.

### Round Splitting Rules (priority order)

1. Module/subsystem boundaries.
2. Layer boundaries (bottom-up: data -> logic -> API -> UI).
3. Dependency order (no circular deps between rounds).
4. Cohesion over file count — one coherent feature or architectural layer per round; hard ceiling is
   work completable in one Codex 600s session. Prefer larger rounds for `prex`, smaller for
   `limited`.
5. Atomic changes never split across rounds.
6. Foundations first (types, interfaces, utilities in round 01).
7. Tests with code (same round), except dedicated integration round at end.

### Templates

- **Round file** (Template A): Context, Previous Rounds, Scope, Current State (key files +
  patterns), Implementation Steps (first step flips the round to `doing`, final step to `done` in
  the plan's `QUEUE.yaml`), Acceptance Criteria, Next Round preview.
- **Plan `README.md`** (Template B, directory plans): Problem statement, strategy, rounds overview,
  execution commands, execution discipline (one round per session, status flips), decisions,
  rejected alternatives, risks.
- **STRATEGY.md** (Template C, XL only): Architectural overview, round dependency graph, risk
  mitigation, cross-cutting concerns.
- **`QUEUE.yaml`** (Template D): top-level ledger + inner per-plan rounds list; fields
  `item/status/depends_on/prompt/notes`.
- **Single-file plan** (Template E, S/M): merges Template B's decision record with Template A's
  executable body; first/final steps flip the plan's entry in the top-level `QUEUE.yaml`.
- **Root `README.md`** (Template F): static explainer of structure, queue semantics, and execution
  discipline; bootstrapped once, never overwritten.

## Source Map

| Topic                                                           | File                      |
| --------------------------------------------------------------- | ------------------------- |
| Five-axis scoring, grade mapping, output format, override rules | `complexity-heuristic.md` |
| Directory structure, slug rules, round contract, lifecycle,     | `plan-lifecycle.md`       |
| legacy `.plan/` migration                                       |                           |
| Templates A (round), B (plan README), C (STRATEGY), D (QUEUE),  | `round-templates.md`      |
| E (single-file plan), F (root README)                           |                           |

## Maintenance Notes

- Templates use `{{PLACEHOLDER}}` markers for skill substitution.
- The executor capacity model assumes Codex 600s timeout; update if timeout changes.
