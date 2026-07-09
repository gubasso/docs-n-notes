# CLAUDE.md

## Purpose

This repository is the single source of truth (SoT) for long-lived LLM agent reference material,
including human-authored technical notes and generated agent digests.

## Repository Scope

- Human-authored notes are the canonical source content.
- `AGENTS.md` files are generated digests that summarize existing source notes for agent
  consumption.
- No generated file may become the canonical source for technical decisions.

## Standard Repository Path

Use `$DOCS_NOTES_REPO` as the canonical environment variable for path resolution.

- Primary resolution target: `/home/gu/Projects/docs-n-notes`
- Legacy symlink path may exist: `/home/gu/DocsNNotes`
- Scripts and skills should resolve and operate on `$DOCS_NOTES_REPO`, not hardcoded paths.

## AGENTS.md Convention

`AGENTS.md` is a generated index/digest file intended for LLM runtime context loading.

### Placement

- Place `AGENTS.md` in directories that need an agent-oriented summary of local notes.
- A directory may contain zero or one `AGENTS.md`.
- Digest scope is the directory where `AGENTS.md` lives (and optionally selected descendants, as
  declared).

### Frontmatter Schema (Required)

Each `AGENTS.md` must begin with YAML frontmatter containing exactly these keys:

- `digest-of`
- `last-synced`
- `source-files`
- `token-estimate`

Example:

```yaml
---
digest-of: tech/programming
last-synced: 2026-05-27
source-files:
  - README.md
  - principles/some-topic.md
token-estimate: 1200
---
```

Field rules:

- `digest-of`: repo-relative directory path the digest represents.
- `last-synced`: ISO date (`YYYY-MM-DD`) when digest was regenerated from sources.
- `source-files`: ordered list of repo-relative source files used to produce the digest.
- `token-estimate`: integer estimate of digest size for context budgeting.

### Body Structure (Required)

Use this structure and heading order:

1. `# AGENTS`
2. `## Scope`
3. `## Key Points`
4. `## Source Map`
5. `## Maintenance Notes`

Body rules:

- Keep content concise, factual, and derived from listed `source-files`.
- `Key Points` should capture stable concepts, constraints, and decision defaults.
- `Source Map` should map major topics to specific source files.
- `Maintenance Notes` should include regeneration triggers and known gaps.

## Generation and Maintenance Rules

- Generate `AGENTS.md` from existing human-authored files only.
- Do not introduce new technical guidance in `AGENTS.md` that is absent from source files.
- On regeneration:
  - update `last-synced`
  - refresh `source-files`
  - recalculate `token-estimate`
  - remove stale or orphaned statements
- If source files conflict, `AGENTS.md` must note the conflict in `Maintenance Notes` rather than
  silently choosing one.
- Prefer incremental regeneration scoped to changed directories.

## LLM-Authored Content Policy

- `AGENTS.md` is the only LLM-generated artifact allowed in this repository.
- All non-`AGENTS.md` documentation is human-authored unless explicitly approved by repository
  maintainers.
- LLMs may propose edits to source notes, but proposed content must be reviewed and committed as
  human-owned documentation.

## Directory Organization Principles

- Keep topic boundaries aligned to existing top-level taxonomy:
  - `tech/programming` for language-agnostic software engineering topics
  - `tech/languages/<lang>` for language-specific guidance
  - `tech/tools/<tool>` for tool-specific usage and workflows
  - `tech/platforms`, `tech/infra`, `tech/systems`, `tech/data`, `tech/workflows` for their domain
    scopes
- Use `README.md` as the index file for each directory.
- Use kebab-case file and directory names.
- Prefer shallow, navigable trees unless depth is needed for clear separation.

## Skill Consumption Order

When an LLM skill/process consumes repository context, use this order:

1. Read nearest `AGENTS.md` first (if present) for scoped digest context.
2. Read the directory `README.md` for index and navigation.
3. Read referenced source files from `source-files` and `Source Map`.
4. If details are missing or ambiguous, read primary notes directly and treat them as authoritative
   over `AGENTS.md`.

## Authoring and Formatting Notes

- Use fenced code blocks with explicit language identifiers.
- Keep examples minimal and operational.
- Maintain stable headings to support deterministic context loading.
