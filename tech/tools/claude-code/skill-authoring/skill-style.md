# Dotfiles House Style for Agent Skills

> Local knowledge: how skills in `/workspaces/.dotfiles/claude/.claude/skills/` are written. Match
> these conventions so new skills feel native to the repo.

## Frontmatter conventions

**Canonical minimum** (matches 80%+ of existing skills):

```yaml
---
name: <skill-name>
description: >
  <what it does in one or two sentences>.
  Triggers: "phrase one", "phrase two", "phrase three".
argument-hint: "<short format hint>"
---
```

**Add only when the skill genuinely needs it:**

| Field                            | When to add                                                                   | Example in repo           |
| -------------------------------- | ----------------------------------------------------------------------------- | ------------------------- |
| `disable-model-invocation: true` | Skill has side effects users should opt into (git ops, deploys, queue writes) | `prex`                    |
| `allowed-tools`                  | Narrow bash whitelist gives a real safety story                               | `commit` (git verbs only) |
| `context: fork` + `agent`        | Skill runs as a forked subagent with no conversation history                  | `review-loop` delegators  |
| `model: haiku`                   | Skill is mechanical/templated enough to run on haiku                          | `commit`                  |
| `effort: high`                   | Skill is orchestration-heavy and must not be downgraded                       | `merge-queue`             |
| `user-invocable: false`          | Skill is internal-only, called by other skills                                | (internal helpers)        |

**Do not invent fields** outside `references/spec.md`.

## Description pattern

Use YAML folded scalar (`description: >`) for anything longer than one line. Single-line form is OK
only for a truly short description (see `commit`).

Structure: **what-it-does → when-to-use → Triggers trailer.**

```yaml
description: >
  One or two sentences on what the skill does and the boundary conditions
  that matter. Keep "when to use" concrete (symptoms, contexts, inputs).
  Triggers: "exact phrase 1", "exact phrase 2", "exact phrase 3".
```

The `Triggers: "..."` trailer is a local convention (see `claudemd`, `merge-queue`,
`plan-reviewer`). It pushes against Claude's tendency to under-invoke skills — spell out the phrases
users actually say. Keep the total `description + when_to_use` text under 1,536 chars (official cap
— see spec.md).

Follow Anthropic's guidance to be **"pushy"** about when to trigger, and Obra's guidance that
triggers should be **symptoms/contexts, not workflow summaries** (otherwise Claude may follow the
description instead of reading the body).

## Body conventions

**Structure (imperative, numbered, sectioned):**

```markdown
# <Title Case Name>

<one-paragraph intro: purpose + scope + any notable boundary>

## Inputs # only if the skill takes arguments

<parse $ARGUMENTS; validate; resolve>

## Steps # straight procedure, OR

## Phase 0 — … # gated workflow (preferred when there's an approval step)

## Phase 1 — …

...

## Rules # NEVER/ALWAYS assertions for runtime behaviour

## Guardrails # override rules at the very end (approval gates, safety)
```

**Tone:**

- Imperative voice ("Do X", "Reject Y"). No "you should".
- **NEVER / ALWAYS / CRITICAL** in caps for non-negotiables.
- **Bold** inline for important phrases.
- No emojis. (Repo-wide CLAUDE.md rule.)
- Plain tables for classification or reference data.
- Fenced code blocks for shell, YAML, and JSON with explicit language tags (markdownlint MD040).

**When to use phased vs stepped:**

- **Phased** (`## Phase 0 — …`) if there is a user-approval gate, or branching paths that need named
  checkpoints. Reference: `claudemd/SKILL.md`.
- **Stepped** (`## Steps` with `1.`, `2.`, …) for straight-line procedures. Reference:
  `retitle/SKILL.md`.
- **Task + Execution** for heavy procedures with a preflight `!`-block and tiered retry logic.
  Reference: `commit/SKILL.md`.

## Preflight `!`-injection pattern

When the skill needs filesystem/git/env state captured _before_ Claude reads the body, use
`!`-prefixed lines. Output is inlined pre-send.

```markdown
## Step 0 — MUST run first

Current branch: !`git branch --show-current` Status: !`git status --porcelain=v1`
```

See `commit/SKILL.md:69-73` and `claudemd/SKILL.md:15`. Use sparingly — only for information the
skill must condition its logic on. Can be disabled by user via `"disableSkillShellExecution": true`,
so the skill should still function (perhaps less efficiently) if the `!`-lines come back empty.

## Agent delegation pattern

When the work belongs in a subagent (isolation, parallelism, protecting the parent context), the
skill stays thin and dispatches a single `Agent` call. Reference: `ask/SKILL.md:22-36`.

```markdown
## Execution

1. Parse $ARGUMENTS: <flag handling>.
2. Dispatch one Agent call:
   - `subagent_type`: "Explore" | "Plan" | "general-purpose"
   - prompt: <self-contained brief; the agent has no prior context>
3. Relay the agent's response verbatim.
```

Alternative: set `context: fork` + `agent: …` in frontmatter so the skill body _is_ the task prompt.
This loses interactivity — use only when the skill does not need to ask follow-up questions.

## Mini-templates

### Lightweight (~40 lines, self-contained, no gates)

Reference exemplar: `retitle/SKILL.md`.

````markdown
---
name: <name>
description: >
  <one sentence>. Triggers: "phrase1", "phrase2".
argument-hint: "<hint>"
---

# <Title>

<one-paragraph intro>

## Steps

1. **<step 1>:** <detail>.
2. **<step 2>** by running this:
   ```bash
   <command using $ARGUMENTS>
   ```

3. Confirm the result.

## Notes

- <edge case>
- <gotcha>
````

### Mid (~180 lines, phased with approval gate)

Reference exemplar: `claudemd/SKILL.md`.

```markdown
---
name: <name>
description: >
  <what it does, when to use>. Triggers: "phrase1", "phrase2", "phrase3".
argument-hint: "[path or input]"
---

# <Title>

<intro>

<optional preflight: !`<command>`>

## Inputs

<parse $ARGUMENTS>

## Phase 0 — <locate / measure / load>

## Phase 1 — <analyse / classify>

## Phase 2 — <draft changes>

## Phase 3 — Validate

## Phase 4 — Present for approval

**NEVER auto-apply. ALWAYS present the full proposal.**

## Phase 5 — Apply

## Guardrails
```

### Heavy (~270 lines, preflight + numbered task + retry loop)

Reference exemplar: `commit/SKILL.md`. Use only when the skill has real operational weight
(orchestrating shell, handling hook failures, tiered escalation). Most skills should choose
lightweight or mid.

## Staging discipline (for skills targeting `claude/.claude/`)

When a skill writes into `~/.dotfiles/claude/.claude/**`, **all writes must go through
`$RUN_DIR/staging/dotclaude/<relative-path>` first**, then install atomically. See
`/workspaces/.dotfiles/CLAUDE.md` section "Editing `claude/.claude/` files" for the full rule.

```bash
# single file
install -D -m 0644 \
  "$RUN_DIR/staging/dotclaude/<rel>" \
  "$HOME/.dotfiles/claude/.claude/<rel>"

# whole directory
cp -a "$RUN_DIR/staging/dotclaude/<rel>/." "$HOME/.dotfiles/claude/.claude/<rel>/"
```

A PreToolUse hook at `.claude/hooks/block-claude-dir-edits.sh` rejects direct
`Edit`/`Write`/`NotebookEdit` into protected paths; it permits paths matching
`/tmp/**/staging/dotclaude/**`. Bash-driven `install`/`cp` is not hook-matched.

After install, remind the user to run `dots claude` to deploy the dotfiles symlinks.
