# Claude Code Invocation Cheatsheet

One-page reference for invoking the user-facing orchestrator skills. If you hit a "Skill X cannot be
used with Skill tool due to `disable-model-invocation`" error, jump to
[Troubleshooting](#troubleshooting).

For the full delegation/dispatch model and the empirical findings behind this cheatsheet, see Skills
and Orchestration.

## Plan-review-exec (Codex plans, Claude reviews, Codex implements, Claude reviews)

| Invocation                   | Mode                       | Behavior                          |
| ---------------------------- | -------------------------- | --------------------------------- |
| `/prex <task>`               | manual                     | Explicit user approval at stage 2 |
| `/prex -a <task>`            | auto-approve               | Display reviewed plan, proceed    |
| `/prex --auto <task>`        | auto-approve               | (long form of `-a`)               |
| `/prex -ar <task>`           | auto-approve + review-loop | Proceed and always run stage 5    |
| `/prex --auto-review <task>` | auto-approve + review-loop | (long form of `-ar`)              |

## Troubleshooting

### `Skill <name> cannot be used with Skill tool due to disable-model-invocation`

You just hit a broken shim. The target skill has `disable-model-invocation: true`, which blocks the
Skill tool from dispatching it regardless of where the Skill tool call originates (command shim
body, nested skill, etc.). The fix is always the same: invoke the skill directly.

| If you typed    | Use instead        |
| --------------- | ------------------ |
| `/pre <task>`   | `/prex <task>`     |
| `/prea <task>`  | `/prex -a <task>`  |
| `/prear <task>` | `/prex -ar <task>` |

The short shims (`/pre`, `/prea`, `/prear`) have been deleted because chain-expansion through a shim
body does not work — Claude Code injects shim bodies as literal prompt text and does not recursively
re-parse them for nested slash commands. See Skills and Orchestration §Invocation Patterns for the
empirical test that confirmed this.
