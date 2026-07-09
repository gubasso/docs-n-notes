# CLAUDE.md

## Purpose

This repository is the single source of truth (SoT) for long-lived LLM agent reference material,
including human-authored technical notes and generated agent digests.

## Repository Scope

- Human-authored notes are the canonical source content.
- `AGENTS.md` files are generated digests that summarize existing source notes for agent
  consumption.
- No generated file may become the canonical source for technical decisions.

## Single Source of Truth (SoT) & DRY

- Every technical fact lives in exactly **one** canonical place; other pages link to it rather than
  restate it. When two pages would state the same fact, one owns it and the rest link.
- Layered overlays are **not** duplication: a language/tool binding may state its own specifics and
  link up to the general principle it overlays, but must not restate that general principle. Local
  operational summaries and `AGENTS.md` digests are likewise not duplication.
- **Cookbook exception.** A cookbook / TLDR runbook — a self-contained, top-to-bottom task recipe
  that lives in a `cookbook/` directory and/or opens with a TLDR/cookbook header — **may
  inline-duplicate** content from canonical specs so it stays self-contained. It MUST footnote/link
  each borrowed snippet to the spec that owns it, and MUST NOT be treated as the SoT for any
  decision (on disagreement, the spec wins). The DRY discipline does not apply to cookbooks, and
  SoT/de-duplication passes skip them. Rationale:
  [design-decisions/cookbook-duplication-exception.md](tech/programming/design-decisions/cookbook-duplication-exception.md).

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
- Use `README.md` as the **semantic index** for each directory — it defines the directory's domain
  and organization, not a mirror of the file listing. See
  [README Content Rule](#readme-content-rule).
- Use kebab-case file and directory names.
- Prefer shallow, navigable trees unless depth is needed for clear separation.

## README Content Rule

`README.md` defines its directory's **domain, organization, and semantics** — what kind of content
the directory reserves ("here we keep X"), how the area is arranged, and what its parts mean. That
is the durable, human-facing meaning of the directory.

- **Do not replicate disk state.** No ASCII directory trees, and no exhaustive `ls`-style
  enumerations of child files/subdirectories. The filesystem is the SoT for _what exists_ and drifts
  fast; a README that mirrors it goes stale silently.
- **Links are allowed when justified.** Point to a specific file or directory when the link carries
  organizational/semantic meaning (a curated landmark), not as a mechanical listing. Test: does this
  README own the meaning of that part of the tree, or is it just echoing `ls`?
- **Auto-generated tables of contents are exempt.** A ToC block delimited by generator markers (e.g.
  `<!--TOC-->` … `<!--TOC-->` or `<!-- toc -->` … `<!-- tocstop -->`) lists the page's **own
  headings** and is produced by tooling, so it is allowed — do not hand-trim it; let the generator
  refresh it when the page's sections change. (This exemption is only for tool-managed in-page ToCs;
  it does not license a hand-written enumeration of sibling files.)
- **`AGENTS.md` is exempt** — mapping sources (including a file-level `Source Map`) is its job.

Rationale:
[design-decisions/readme-semantic-not-structural.md](tech/programming/design-decisions/readme-semantic-not-structural.md).

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
