# Plan Lifecycle & Executor Model

Shared specification for skills that produce implementation plans as directories of self-contained
round files. Each round is sized for execution by a single `/prex` run.

## Directory structure

```text
<repo-root>/.plan/
├── 01-todo/                     plans awaiting execution
│   └── <slug>/                  one directory per plan
│       ├── README.md            overview, strategy, execution order, checklist
│       ├── STRATEGY.md          (XL plans only) architecture, dep graph, cross-cutting concerns
│       ├── 01-<topic>.md        round 1 — self-contained task description
│       ├── 02-<topic>.md        round 2
│       └── ...
└── 02-done/                     completed plans (moved from 01-todo after all rounds finish)
    └── <slug>/
```

`.plan/` must be listed in the repo's `.gitignore`. If it is not, the generating skill should
suggest adding it (but must not auto-modify `.gitignore`).

## Slug conventions

- 3–5 word lowercase slug derived from the plan orientation/goal.
- Characters: `[a-z0-9-]` only. Maximum 60 characters.
- Example: `refactor-auth-middleware`, `add-batch-export-api`.

## Round file contract

Each round file (`NN-<topic>.md`) is a **self-contained task description** designed to be consumed
directly by `/prex -ar <path>` or included via `@` in `/prex -ar @<plan-dir>/`.

Self-containment rules:

- Contains the full problem statement and motivation — no "see the conversation" or "as discussed."
- Includes all code references (absolute paths, relevant excerpts) needed for THIS round.
- Describes what previous rounds produced (expected state) without requiring the executor to read
  those round files.
- Specifies what is in scope and out of scope for this round.
- Has its own acceptance criteria, independently verifiable.

Round numbering: two-digit zero-padded prefix (`01-`, `02-`, ..., `99-`).

## Executor capacity model

Rounds are sized against the capabilities of a single `/prex` run:

- **Codex timeout**: 600 seconds per stage (planning and implementation). A round must describe work
  completable within this window.
- **Single write session**: Codex implements in one continuous session. The round must be cohesive —
  changes that require iterative feedback loops across sessions should be separate rounds.
- **Quality threshold**: Quality degrades when a single prex run handles multiple loosely-related
  changes. Each round should address one cohesive chunk of work (one feature, one module refactor,
  one layer of the stack).
- **Practical sizing**: A well-scoped round typically touches 3–8 files, introduces or modifies one
  coherent feature or subsystem, and can be described in under 300 lines of plan text.

## Lifecycle rules

1. **Generation**: The planning skill writes the plan directory into `.plan/01-todo/<slug>/`. It
   never executes rounds or moves directories.
2. **Execution**: The user runs `/prex -ar <round-file>` or `/prex -ar @<plan-dir>/` to execute
   rounds. The executor updates the README.md checklist as rounds complete.
3. **Completion**: After all rounds are done, the user (or a lifecycle skill) moves the directory:
   `mv .plan/01-todo/<slug> .plan/02-done/<slug>` and updates the README.md status to `done`.

## README.md role

The README.md serves as the plan's index and progress tracker:

- Links to all round files with their topics and status.
- Contains the execution commands (exact `/prex` invocations).
- Records architectural decisions and rejected alternatives that span the full plan.
- Tracks completion timestamps per round in the execution order table.
