# Round Plan Templates

Templates for the files generated in a `.plan/01-todo/<slug>/` directory. Use `{{PLACEHOLDER}}`
markers — the generating skill substitutes them with actual values.

All templates follow the repo's markdown rules: fenced code blocks must have language specifiers
(MD040). Use `text` when no specific syntax applies.

## Template A — Round file (`NN-<topic>.md`)

Each round file is a self-contained task description for `/prex -ar`.

````markdown
# Round {{NN}}: {{Title}}

> Plan: {{SLUG}} | Round: {{NN}} of {{TOTAL}} | Complexity: {{GRADE}} Generated: {{ISO_8601}} |
> Repo: {{REPO_ROOT}}

## Context

{{Full problem statement and motivation. Written so someone with ZERO prior context understands the
"why". Compact but complete — 10–20 lines of focused context. Do NOT reference external documents or
"the conversation".}}

## Previous Rounds

{{If NN > 01: describe what prior rounds produced — specific files created/modified, patterns
established, types introduced. Describe the EXPECTED state, not actual (the executor adapts to what
it finds). If NN == 01: "This is the first round — no prior rounds."}}

## Scope of This Round

{{Precise description of what this round implements. Explicitly state:}} {{- IN scope: what this
round delivers.}} {{- OUT of scope: what is deferred to later rounds (scope creep prevention).}}

## Current State

### Key Files

{{For each file relevant to THIS round:}}

- `{{absolute path}}` — {{role/purpose}} {{Key excerpts, signatures, or structural observations when
  needed.}}

### Existing Patterns

{{Conventions, naming patterns, structural rules the implementation must follow.}}

## Implementation Steps

### Step 1: {{title}}

{{Which file to create or modify (absolute path). What to add, change, or remove — specific enough
to implement. Why this step is needed. Ordering dependencies on other steps within this round.}}

### Step 2: {{title}}

{{details}}

### Final Step: Update plan index

Update the plan's `README.md` (in the same directory as this round file) to record completion:

1. In the `## Execution Order` table, find the row for round {{NN}}.
2. Change `Status` from `todo` to `done`.
3. Change `Completed` from `--` to today's date (`YYYY-MM-DD`).

{{If this is the final round, also:}}

4. In the README.md header blockquote, change `Status: todo` to `Status: done`.
5. Move the plan directory to done:

```bash
mkdir -p .plan/02-done && mv .plan/01-todo/{{SLUG}} .plan/02-done/{{SLUG}}
```

## Acceptance Criteria

{{Concrete, checkable criteria specific to THIS round. Each independently verifiable.}}

- [ ] {{criterion 1}}
- [ ] {{criterion 2}}
- [ ] Plan `README.md` execution order table shows round {{NN}} as `done` with today's date {{If
      this is the final round:}}
- [ ] Plan `README.md` header status is `done`
- [ ] Plan directory moved from `.plan/01-todo/{{SLUG}}` to `.plan/02-done/{{SLUG}}`

## Next Round

{{If not the last round: brief preview of what comes next and what this round enables for it. If the
last round: "This is the final round."}}
````

### Round file guidelines

- The `## Context` section must be self-contained. Repeat the essential problem statement — do not
  say "see README" or "as discussed."
- `## Previous Rounds` describes expected output of prior rounds, not actual. The executor adapts to
  the real codebase state.
- `## Scope of This Round` prevents scope creep — the executor knows what NOT to do.
- `## Next Round` gives the executor awareness of the bigger picture without requiring it to read
  ahead.
- Implementation steps are in dependency order within the round.
- Every round file must end with a "Final Step: Update plan index" that instructs the executor to
  mark the round as `done` with today's date in the README.md execution order table.
- The **final round** must additionally instruct the executor to set the README.md header status to
  `done` and move the plan directory from `.plan/01-todo/` to `.plan/02-done/`.
- Include enough code context (quoted lines, signatures) for the executor to locate exact insertion
  points. Do not just cite line numbers — they shift.

## Template B — `README.md`

The plan's index, progress tracker, and decision record.

````markdown
# {{Plan Title}}

> Complexity: {{GRADE}} | Rounds: {{TOTAL}} | Generated: {{ISO_8601}} Repo: {{REPO_ROOT}} Status:
> todo

## Problem Statement

{{Why this work is needed. Full motivation and background.}}

## Strategy

{{High-level approach. How the work is split into rounds and why this splitting was chosen. For S/M
plans, this is 2–3 sentences. For L/XL, summarize and point to STRATEGY.md.}}

## Execution Order

| Round | File              | Topic     | Status | Completed |
| ----- | ----------------- | --------- | ------ | --------- |
| 01    | `01-{{topic}}.md` | {{topic}} | todo   | --        |
| 02    | `02-{{topic}}.md` | {{topic}} | todo   | --        |

## Execution Commands

```bash
# Execute a single round:
/prex -ar .plan/01-todo/{{SLUG}}/01-{{topic}}.md

# Execute rounds sequentially (run each after the previous completes):
/prex -ar .plan/01-todo/{{SLUG}}/01-{{topic}}.md
/prex -ar .plan/01-todo/{{SLUG}}/02-{{topic}}.md

# Execute with full directory context:
/prex -ar @.plan/01-todo/{{SLUG}}/
```

## Execution Discipline

**Rounds must be executed one at a time.** Each round is a self-contained unit of work designed for
a single `/prex` session. Do not attempt to implement multiple rounds in one session.

After completing a round:

1. Consult the **Execution Order** table above.
2. Find the next round with status `todo`.
3. Execute it in a **fresh** `/prex` session.
4. Repeat until all rounds show status `done`.

## Decisions & Constraints

{{Architectural decisions made during the interview. Include the reasoning behind each. Constraints
that apply across all rounds.}}

## Rejected Alternatives

{{Approaches considered and dismissed, with the reason for rejection.}}

## Risks & Edge Cases

{{Known risks that span the full implementation. For each, note whether it needs handling or is
accepted.}}

## Completion

When all rounds are done:

```bash
# Update status in this file to "done"
# Fill in completion timestamps in the execution order table
mv .plan/01-todo/{{SLUG}} .plan/02-done/{{SLUG}}
```
````

## Template C — `STRATEGY.md` (XL plans only)

Generated only for XL-grade plans where the round structure and cross-cutting concerns need detailed
documentation.

````markdown
# Strategy: {{Plan Title}}

## Architectural Overview

{{How the pieces fit together. The big picture of what is being built/changed and why the work is
structured this way.}}

## Round Dependency Graph

{{Which rounds depend on which. Why this ordering was chosen. Identify the critical path.}}

```text
Round 01 (foundations) ──→ Round 02 (core logic)
                      └──→ Round 03 (API layer) ──→ Round 04 (integration tests)
```

## Risk Mitigation

{{How the round splitting reduces risk. What happens if a round fails mid-way. Rollback
considerations. Which rounds are independently revertable.}}

## Cross-Cutting Concerns

{{Concerns that span multiple rounds. Each round file references this document for shared decisions.
Examples: error handling patterns, logging conventions, configuration approach, naming conventions
introduced in round 01 that later rounds must follow.}}
````
