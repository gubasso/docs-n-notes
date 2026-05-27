---
digest-of: tech/tools/claude-code/skill-authoring
last-synced: 2026-05-27
source-files:
  - skill-spec.md
  - skill-style.md
token-estimate: 900
---

# AGENTS

## Scope

Official Claude Code skill specification (pinned from docs) and the dotfiles house style for
authoring skills.

## Key Points

### Official Spec (skill-spec.md)

- Frontmatter fields: `name` (<=64 chars), `description` (recommended, 1536-char cap with
  `when_to_use`), `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`,
  `allowed-tools`, `model`, `effort`, `context`, `agent`, `hooks`, `paths`, `shell`.
- String substitutions: `$ARGUMENTS`, `$ARGUMENTS[N]`, `$name`, `${CLAUDE_SESSION_ID}`,
  `${CLAUDE_SKILL_DIR}`.
- Dynamic shell injection: `` !`cmd` `` inline, `` ```! `` block (preprocessing).
- Scope precedence: enterprise > personal > project. Plugin skills namespaced.
- Token budgets: body loaded on trigger (<500 lines), bundled resources on demand, auto-compaction
  keeps first 5000 tokens per skill, 25000 combined cap.

### House Style (skill-style.md)

- Frontmatter minimum: `name`, `description: >` (folded scalar), `argument-hint`.
- Description pattern: what-it-does -> when-to-use -> `Triggers: "phrase 1", "phrase 2"` trailer. Be
  "pushy" on triggers.
- Body: imperative voice, phased (approval gates) or stepped (straight-line), rules section,
  guardrails section.
- No emojis. Fenced code blocks with language tags. Bold for important phrases. NEVER/ALWAYS in caps
  for non-negotiables.
- Preflight `!`-injection for env/git state before Claude reads the body.
- Agent delegation: thin dispatch via Agent tool (not Skill tool for nested delegation).
- Templates: lightweight (~40 lines), mid (~180 lines with approval gate), heavy (~270 lines with
  preflight + retry).
- Staging discipline for `claude/.claude/**`: write to `$RUN_DIR/staging/dotclaude/<rel>`, install
  atomically at end.

## Source Map

| Topic                                                         | File             |
| ------------------------------------------------------------- | ---------------- |
| Official frontmatter fields, substitutions, token budgets     | `skill-spec.md`  |
| House style, description pattern, body conventions, templates | `skill-style.md` |

## Maintenance Notes

- `skill-spec.md` is pinned from `https://code.claude.com/docs/en/skills`; re-fetch on major Claude
  Code releases.
- House style evolves with the dotfiles skill collection.
