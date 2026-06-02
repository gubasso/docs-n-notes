# Plan Lifecycle & Executor Model

Shared specification for skills that produce implementation plans as directories of self-contained
round files. Each round is sized for execution by a single `/prex` run.

The `.plan/` tree is **flat and queue-driven**: a plan's status, order, dependencies, and execution
command live in YAML queue files — never in directory or file names. There are no kanban
state-directories and no numeric prefixes.

## Directory structure

```text
<repo-root>/.plan/
├── _README.md                   AI-friendly explanation of the queue system
├── _QUEUE.yaml                  top-level source of truth: every plan + status
├── <slug>/                      one directory per multi-round plan
│   ├── _README.md               overview, strategy, decisions, rejected alternatives
│   ├── STRATEGY.md              (XL plans only) architecture, dep graph, cross-cutting concerns
│   ├── _QUEUE.yaml              this plan's rounds, in execution order
│   ├── <topic>.md               a round — self-contained task description (no number prefix)
│   └── <topic>.md               another round
└── <slug>.md                    a single-file plan (a loose note, not yet round-split)
```

Whether `.plan/` is committed or gitignored is the **host repo's** choice — some repos track plans
as part of their history, others ignore them. The generating skill must not assume one or modify
`.gitignore`.

## Slug conventions

- 3–5 word lowercase slug derived from the plan orientation/goal.
- Characters: `[a-z0-9-]` only. Maximum 60 characters.
- Example: `refactor-auth-middleware`, `add-batch-export-api`.
- Round files use the same convention for their `<topic>` slug. **No `NN-` number prefix** — round
  order is defined by the order of entries in the plan's `_QUEUE.yaml`.

## The queues are the source of truth

`status` is one of: `backlog | todo | doing | done`.

- **`.plan/_QUEUE.yaml`** is the repo-wide ledger. It lists _every_ plan (full ledger — completed
  plans stay, as `status: done`). Each entry: `item` (a `<slug>` dir, or `<slug>.md` for a
  single-file plan), `status`, `depends_on` (list of other `item`s), `prompt` (exact execution
  command), `notes` (free-form). Entry order reflects execution priority: active items first, then
  backlog, then done.
- **`<slug>/_QUEUE.yaml`** lists that plan's `rounds:` in execution order. Each round entry has the
  same fields, with `item` = the round's `<topic>` and `prompt` =
  `/prex -ar .plan/<slug>/<topic>.md`.

**Every queue entry — both levels — carries a `prompt` field.**

## Round file contract

Each round file (`<topic>.md`) is a **self-contained task description** designed to be consumed
directly by `/prex -ar <path>` or included via `@` in `/prex -ar @<plan-dir>/`.

Self-containment rules:

- Contains the full problem statement and motivation — no "see the conversation" or "as discussed."
- Includes all code references (absolute paths, relevant excerpts) needed for THIS round.
- Describes what previous rounds produced (expected state) without requiring the executor to read
  those round files.
- Specifies what is in scope and out of scope for this round.
- Has its own acceptance criteria, independently verifiable.

## Executor capacity model

Rounds are sized against the capabilities of a single `/prex` run:

- **Codex timeout**: 600 seconds per stage (planning and implementation). A round must describe work
  completable within this window.
- **Single write session**: Codex implements in one continuous session. The round must be cohesive —
  changes that require iterative feedback loops across sessions should be separate rounds.
- **Quality threshold**: Quality degrades when a single prex run handles multiple loosely-related
  changes. Each round should address one cohesive chunk of work (one feature, one module refactor,
  one layer of the stack).
- **Practical sizing**: A well-scoped round delivers one coherent feature or architectural layer.
  File count is incidental — mechanically-coupled changes belong together regardless of count. A
  round description usually fits in under 300 lines of plan text.

## Lifecycle rules

1. **Generation**: The planning skill writes the plan directory into `.plan/<slug>/` (`_README.md`,
   round files, inner `_QUEUE.yaml`) and registers the plan in the top-level `.plan/_QUEUE.yaml`. It
   never executes rounds.
2. **Execution**: Rounds are executed **one at a time**, each in its own `/prex -ar` session. When
   handed the plan directory or `_README.md`, the executor reads the plan's `_QUEUE.yaml`, runs the
   first round whose status is `todo`, then stops. After completing a round, it sets that round's
   `status: done` in the inner `_QUEUE.yaml`. Never batch multiple rounds into a single session —
   each round is a self-contained unit sized for one `/prex` run.
3. **Completion**: After all rounds are done, set the plan's `status: done` in the top-level
   `.plan/_QUEUE.yaml`. **Nothing moves on disk** — the plan directory stays where it is. Status,
   not path, records the lifecycle state.

## `_README.md` and `_QUEUE.yaml` roles

- **`<slug>/_QUEUE.yaml`** is the machine-readable source of truth for round order and status.
- **`<slug>/_README.md`** is the human-facing index and decision record: problem statement,
  strategy, execution commands (exact `/prex` invocations), architectural decisions, and rejected
  alternatives. It mirrors the queue for readers but must not become a competing source of truth for
  status — when in doubt, the `_QUEUE.yaml` wins.
