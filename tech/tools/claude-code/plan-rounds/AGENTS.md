---
digest-of: tech/tools/claude-code/plan-rounds
last-synced: 2026-06-19
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
- Grades from adjusted score: S (≤7.0), M (7.1-11.0), L (11.1-15.0), XL (≥15.1). The grade is a
  descriptive difficulty signal; round count is uncapped and set by Layer-2 splitting rules.
- Every plan is a directory `plans/<slug>/`. Layer 1 splits work by domain/scope into flat sibling
  dirs related by top-level `queue-plans.yaml` `depends_on`; Layer 2 grades each dir and splits it
  into uncapped rounds in `queue-rounds.yaml`. Plan dirs are always direct children of `plans/` —
  **never nested**, never with plan subdirectories; ordering lives only in `depends_on` (a shared
  slug prefix is a naming convention, not a parent dir).
- Override when: few files but 500+ LOC each, security-sensitive, or mechanical rename across many
  files.

### Plan Lifecycle

- `.implementation-plans/` is flat and queue-driven: status/order/deps/command live in YAML, not in
  paths. No `01-todo`/`02-done` kanban dirs, no `NN-` prefixes. Plan dirs are a single level under
  `plans/` — never nested inside one another.
- Root holds `README.md` (static system explainer, bootstrapped once) and `queue-plans.yaml`
  (repo-wide ledger, all plans, full history). All plans live under `plans/` as directories:
  `plans/<slug>/` (`README.md` + `queue-rounds.yaml` + de-numbered `<topic>.md` round files +
  `STRATEGY.md` for XL).
- `plans/<slug>/queue-rounds.yaml` lists that plan's rounds in execution order.
  `status: backlog|todo|doing|done`. Every entry carries a `prompt`.
- Slugs `readme`, `queue`, `strategy`, `queue-plans`, `queue-rounds` are reserved (collide with meta
  files).
- Each round file (`<topic>.md`) is self-contained: full context, previous round summary, scope,
  implementation steps, acceptance criteria.
- Rounds sized for one Codex 600s session, delivering one cohesive feature/layer. File count is
  incidental — mechanically-coupled changes belong together regardless of count.
- Execution: `/prex -ar @.implementation-plans/plans/<slug>/` reads `queue-rounds.yaml`, runs the
  first `todo` round, stops. Flip `status` to `doing` when starting a round and `done` when
  finished; nothing moves on disk.
- Legacy `.plan/` trees migrate manually (rename root, move plans under `plans/`, drop `_` prefixes,
  rename queues to `queue-plans.yaml` / `queue-rounds.yaml`, rewrite `prompt:` paths); the
  generating skill detects them and informs, never auto-migrates.

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
  the plan's `queue-rounds.yaml`), Acceptance Criteria, Next Round preview.
- **Plan `README.md`** (Template B, directory plans): Problem statement, strategy, rounds overview,
  execution commands, execution discipline (one round per session, status flips), decisions,
  rejected alternatives, risks.
- **STRATEGY.md** (Template C, XL only): Architectural overview, round dependency graph, risk
  mitigation, cross-cutting concerns.
- **Queue files** (Template D): top-level `queue-plans.yaml` ledger + inner per-plan
  `queue-rounds.yaml` rounds list; fields `item/status/depends_on/prompt/notes`.
- **Root `README.md`** (Template F): static explainer of structure, queue semantics, and execution
  discipline; bootstrapped once, never overwritten.

## Source Map

| Topic                                                            | File                      |
| ---------------------------------------------------------------- | ------------------------- |
| Five-axis scoring, difficulty grade + round splitting, overrides | `complexity-heuristic.md` |
| Directory structure, slug rules, round contract, lifecycle,      | `plan-lifecycle.md`       |
| legacy `.plan/` migration                                        |                           |
| Templates A (round), B (plan README), C (STRATEGY), D (queues),  | `round-templates.md`      |
| F (root README)                                                  |                           |

## Maintenance Notes

- Templates use `{{PLACEHOLDER}}` markers for skill substitution.
- The executor capacity model assumes Codex 600s timeout; update if timeout changes.
