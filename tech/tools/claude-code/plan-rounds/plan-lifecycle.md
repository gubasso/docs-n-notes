# Plan Lifecycle & Executor Model

Shared specification for skills that produce implementation plans — single self-contained files for
simple work, directories of self-contained round files for complex work. Each round is sized for
execution by a single `/prex` run.

The `.implementation-plans/` tree is **flat and queue-driven**: a plan's status, order,
dependencies, and execution command live in YAML queue files — never in directory or file names.
There are no kanban state-directories and no numeric prefixes.

## Directory structure

```text
<repo-root>/.implementation-plans/
├── README.md                    static explainer of the plan system (bootstrapped once)
├── QUEUE.yaml                   top-level source of truth: every plan + status
└── plans/
    ├── <slug>.md                a single-file plan (S/M — exactly one round, self-contained)
    └── <slug>/                  one directory per multi-round plan (L/XL)
        ├── README.md            overview, strategy, decisions, rejected alternatives
        ├── STRATEGY.md          (XL plans only) architecture, dep graph, cross-cutting concerns
        ├── QUEUE.yaml           this plan's rounds, in execution order
        ├── <topic>.md           a round — self-contained task description (no number prefix)
        └── <topic>.md           another round
```

The complexity grade selects the plan format: **S/M plans are a single file** (`plans/<slug>.md`)
merging the decision record with the executable round body; **L/XL plans are a directory**
(`plans/<slug>/`). A single-file plan is a first-class, fully executable plan — not a draft awaiting
round-splitting.

The root `README.md` and `QUEUE.yaml` are bootstrapped by the generating skill the first time it
runs in a repo: `README.md` from its template (never overwritten afterwards), `QUEUE.yaml` with an
empty `plans:` list.

Whether `.implementation-plans/` is committed or gitignored is the **host repo's** choice — some
repos track plans as part of their history, others ignore them. The generating skill must not assume
one or modify `.gitignore`.

## Slug conventions

- 3–5 word lowercase slug derived from the plan orientation/goal.
- Characters: `[a-z0-9-]` only. Maximum 60 characters.
- Example: `refactor-auth-middleware`, `add-batch-export-api`.
- Round files use the same convention for their `<topic>` slug. **No `NN-` number prefix** — round
  order is defined by the order of entries in the plan's `QUEUE.yaml`.
- The slugs `readme`, `queue`, and `strategy` (case-insensitive) are **reserved** for both plan
  slugs and round topics — they collide with the meta files (`README.md`, `QUEUE.yaml`,
  `STRATEGY.md`).

## The queues are the source of truth

`status` is one of: `backlog | todo | doing | done`.

- **`.implementation-plans/QUEUE.yaml`** is the repo-wide ledger. It lists _every_ plan (full ledger
  — completed plans stay, as `status: done`). Each entry: `item` (a `<slug>` dir, or `<slug>.md` for
  a single-file plan), `status`, `depends_on` (list of other `item`s), `prompt` (exact execution
  command), `notes` (free-form). Entry order reflects execution priority: active items first, then
  backlog, then done.
- **`plans/<slug>/QUEUE.yaml`** lists that plan's `rounds:` in execution order. Each round entry has
  the same fields, with `item` = the round's `<topic>` and `prompt` =
  `/prex -ar .implementation-plans/plans/<slug>/<topic>.md`. Single-file plans have no inner queue —
  their status lives only in the top-level ledger.

**Every queue entry — both levels — carries a `prompt` field.**

## Round file contract

Each round file (`<topic>.md`) — and, identically, each single-file plan (`<slug>.md`) — is a
**self-contained task description** designed to be consumed directly by `/prex -ar <path>` or
included via `@` in `/prex -ar @<plan-dir>/`.

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

1. **Generation**: The planning skill bootstraps the root (`README.md`, `QUEUE.yaml`) if missing,
   writes the plan — `plans/<slug>.md` for S/M, or `plans/<slug>/` (`README.md`, round files, inner
   `QUEUE.yaml`, `STRATEGY.md` for XL) for L/XL — and registers the plan in the top-level
   `.implementation-plans/QUEUE.yaml`. It never executes rounds.
2. **Execution**: Rounds are executed **one at a time**, each in its own `/prex -ar` session. When
   handed the plan directory or its `README.md`, the executor reads the plan's `QUEUE.yaml`, runs
   the first round whose status is `todo`, then stops. When starting a round it sets that round's
   `status: doing`; after completing it, `status: done` — a crashed or interrupted session thus
   leaves a visible `doing` marker. Never batch multiple rounds into a single session — each round
   is a self-contained unit sized for one `/prex` run. For a single-file plan the same flips apply
   to the plan's entry in the top-level ledger.
3. **Completion**: After all rounds are done, set the plan's `status: done` in the top-level
   `.implementation-plans/QUEUE.yaml`. **Nothing moves on disk** — the plan file or directory stays
   where it is. Status, not path, records the lifecycle state.

## `README.md` and `QUEUE.yaml` roles

- **`plans/<slug>/QUEUE.yaml`** is the machine-readable source of truth for round order and status.
- **`plans/<slug>/README.md`** is the human-facing index and decision record: problem statement,
  strategy, execution commands (exact `/prex` invocations), architectural decisions, and rejected
  alternatives. It mirrors the queue for readers but must not become a competing source of truth for
  status — when in doubt, the `QUEUE.yaml` wins.
- **`.implementation-plans/README.md`** (root) is a static explainer of the whole system —
  structure, queue semantics, execution discipline. It carries no per-plan state.

## Migrating a legacy `.plan/` tree

Earlier versions of this spec used `<repo-root>/.plan/` with underscore-prefixed meta files.
Migration is manual:

1. `git mv .plan .implementation-plans` (or plain `mv` if untracked).
2. `mkdir .implementation-plans/plans` and move every `<slug>/` dir and `<slug>.md` plan into it.
3. Rename meta files: `_QUEUE.yaml` → `QUEUE.yaml` and `_README.md` → `README.md`, at both levels.
4. Rewrite every `prompt:` field to the new paths
   (`/prex -ar .implementation-plans/plans/<slug>/<topic>.md`, etc.).
5. Bootstrap the root `README.md` from the template on the next generating-skill run (or copy it
   manually).

The generating skill detects a legacy `.plan/` dir and informs the user, but never migrates
automatically.
