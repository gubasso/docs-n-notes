# Claude Code Agent Skills — Official Specification

> **Last verified:** 2026-04-22 **Source:** <https://code.claude.com/docs/en/skills>
>
> This file is the **pinned, authoritative reference** for `skill-builder`. Training data lags the
> spec; trust this file over memory. When the official spec changes, re-fetch the source and update
> both the table and the `Last verified` line.

## Frontmatter fields

All fields live between `---` markers at the top of `SKILL.md`. Every field is technically optional;
only `description` is _recommended_ so automatic invocation works.

| Field                      | Required    | Description                                                                                                                                                                                 |
| -------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`                     | No          | Display name + slash-command. Lowercase letters, digits, and hyphens only (max 64 chars). Defaults to directory name.                                                                       |
| `description`              | Recommended | What the skill does + when to use it. Front-load the key use case. Combined with `when_to_use`, truncated at **1,536 chars** in the skill listing.                                          |
| `when_to_use`              | No          | Extra trigger phrases / example requests. Appended to `description` in the listing; counts toward the 1,536-char cap.                                                                       |
| `argument-hint`            | No          | Autocomplete hint, e.g. `[issue-number]` or `[filename] [format]`.                                                                                                                          |
| `arguments`                | No          | Named positional args for `$name` substitution. Accepts a space-separated string or a YAML list.                                                                                            |
| `disable-model-invocation` | No          | `true` = user-only (no auto-load by Claude). Use for side-effect workflows (`/deploy`, `/commit`). Default: `false`.                                                                        |
| `user-invocable`           | No          | `false` = hide from `/` menu. Use for background knowledge users should not call directly. Default: `true`.                                                                                 |
| `allowed-tools`            | No          | Tools Claude may use without asking while the skill is active. Pre-approves; does not restrict. Accepts space-separated string or YAML list. Example: `Bash(git add:*) Bash(git commit:*)`. |
| `model`                    | No          | Per-skill model override. Same values as `/model`, or `inherit`. Scoped to the turn.                                                                                                        |
| `effort`                   | No          | `low` \| `medium` \| `high` \| `xhigh` \| `max` (availability depends on model).                                                                                                            |
| `context`                  | No          | `fork` to run the skill in a forked subagent context.                                                                                                                                       |
| `agent`                    | No          | Subagent type when `context: fork` is set (e.g. `Explore`, `Plan`, `general-purpose`, or a custom `.claude/agents/<name>`).                                                                 |
| `hooks`                    | No          | Skill-lifecycle hooks.                                                                                                                                                                      |
| `paths`                    | No          | Glob patterns that limit auto-activation to matching files. Accepts CSV or YAML list.                                                                                                       |
| `shell`                    | No          | `bash` (default) or `powershell`. Controls `` !`cmd` `` and `` ```! `` blocks.                                                                                                              |

> **Note:** `license` is **not** a SKILL.md frontmatter field. License is declared at the repository
> level (Anthropic's own skills use Apache-2.0 at the repo root).

## String substitutions

Available anywhere in skill content:

| Variable               | Meaning                                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| `$ARGUMENTS`           | All arguments passed to the skill. If absent from content, appended as `ARGUMENTS: <value>`.           |
| `$ARGUMENTS[N]`        | Specific argument by 0-based index.                                                                    |
| `$N`                   | Shorthand for `$ARGUMENTS[N]`.                                                                         |
| `$name`                | Named argument declared in `arguments` frontmatter (positional).                                       |
| `${CLAUDE_SESSION_ID}` | Current session ID.                                                                                    |
| `${CLAUDE_SKILL_DIR}`  | Directory containing the skill's `SKILL.md`. Use to reference bundled scripts/files regardless of CWD. |

**Dynamic shell injection:** `` !`<cmd>` `` inline, or a fenced `` ```! `` block for multi-line.
Runs _before_ Claude sees the content (preprocessing, not something Claude executes). Disable
globally with `"disableSkillShellExecution": true` in settings.

## Scope and precedence

| Scope      | Path                               | Applies to                  |
| ---------- | ---------------------------------- | --------------------------- |
| Enterprise | managed settings                   | Whole org                   |
| Personal   | `~/.claude/skills/<name>/SKILL.md` | All your projects           |
| Project    | `.claude/skills/<name>/SKILL.md`   | One repo                    |
| Plugin     | `<plugin>/skills/<name>/SKILL.md`  | Where the plugin is enabled |

Precedence: **enterprise > personal > project**. Plugin skills are namespaced as
`plugin-name:skill-name`. Nested `.claude/skills/` directories in monorepos are auto-discovered.
`--add-dir` directories also contribute their `.claude/skills/`. Live change detection is on; adding
a _new_ top-level skills directory requires a restart.

## Progressive disclosure and token budgets

- **Metadata** (name + description + when_to_use) — always in context. Combined description +
  when_to_use is truncated at **1,536 chars** in the skill listing.
- **SKILL.md body** — loaded when the skill triggers. **Keep under 500 lines.** If approaching the
  limit, move detail into sibling files and reference them.
- **Bundled resources** — loaded on demand when SKILL.md links to them.
- **Skill listing budget** — dynamic (~1% of context window, fallback 8,000 chars). Raise via
  `SLASH_COMMAND_TOOL_CHAR_BUDGET`.
- **Auto-compaction** — each re-attached skill keeps its first **5,000 tokens**; all re-attached
  skills share a combined **25,000-token budget**, filled most-recent first. Older skills can be
  dropped.
- Including the literal keyword `ultrathink` in skill content enables extended thinking for that
  turn.

## Directory layout

```text
my-skill/
├── SKILL.md           # required entrypoint
├── reference.md       # optional, loaded only when SKILL.md links to it
├── examples.md        # optional
├── scripts/           # optional, executable (Python, bash, etc.)
│   └── helper.py
└── assets/            # optional static files (templates, fonts, icons)
```

Always reference supporting files _from_ SKILL.md via markdown links, with guidance on when to open
them. If a reference file exceeds 300 lines, include a table of contents at the top so Claude can
jump to the relevant section.

**Domain organization** — when a skill supports multiple backends/frameworks, organize by variant so
only the relevant reference loads:

```text
cloud-deploy/
├── SKILL.md           # workflow + variant selection
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

## Invocation control

| Goal                                                  | Field setting                    |
| ----------------------------------------------------- | -------------------------------- |
| Both user and Claude can invoke (default)             | —                                |
| Only user can invoke manually (side-effect workflows) | `disable-model-invocation: true` |
| Only Claude can invoke (hidden background knowledge)  | `user-invocable: false`          |

## Content lifecycle

When a skill fires, its body enters the conversation as a single message and stays for the rest of
the session. Claude does **not** re-read `SKILL.md` on later turns. Write standing instructions that
apply throughout the task, not one-time steps.
