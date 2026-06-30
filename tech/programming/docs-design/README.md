# Documentation Design

Language-agnostic principles for organizing a software project's `docs/` directory. Use this shelf
when a project needs clear document ownership, lean decision records, operational docs that are easy
to find, and source-of-truth rules that humans and LLM agents can follow.

The pattern uses Diataxis zones, lean ADRs, single-source-of-truth placement, load-bearing comments,
gitignored drafts, and tracking for perishable facts. It is intentionally small: enough structure to
prevent drift, not enough to turn documentation into a separate process.

## How to use this shelf

1. Read [00 — Overview](00-overview.md) for the defaults and when to apply them.
1. Apply the zone map from [01 — Diataxis Zones](01-diataxis-zones.md).
1. Copy [template-adr.md](template-adr.md) into `<project>/docs/decisions/template.md`.
1. Enforce the lean ADR rules from [02 — Lean ADRs](02-lean-adrs.md).
1. Use [99 — Checklist](99-checklist.md) before merging documentation changes.

LLM agents should load [AGENTS.md](AGENTS.md) first for the digest, then read the source chapters
that own the current change.

For a new project, start small. Create only the zones that have real content, but keep the same
placement rules. Empty structure is not the goal; predictable ownership is.

For an existing project, migrate by ownership. Move decisions first, then operational guides and
reference material. Leave broad explanation until the factual sources of truth are clear.

## Index

| #        | Chapter                                                      | One-line hook                                                      |
| -------- | ------------------------------------------------------------ | ------------------------------------------------------------------ |
| 0        | [Overview](00-overview.md)                                   | Defaults, principles, and when this pattern is worth applying.     |
| 1        | [Diataxis Zones](01-diataxis-zones.md)                       | Decisions, guides, reference, and explanation by reader need.      |
| 2        | [Lean ADRs](02-lean-adrs.md)                                 | MADR-minimal records, 350-word cap, and never-delete lifecycle.    |
| 3        | [Comments and Code as SoT](03-comments-and-code-as-sot.md)   | Keep comments only when they carry rationale code cannot express.  |
| 4        | [Single Source of Truth](04-single-source-of-truth.md)       | Placement table and cross-link discipline for durable facts.       |
| 5        | [Drafts and Promotion](05-drafts-and-promotion.md)           | Keep drafts outside shipped docs and promote by reader need.       |
| 6        | [Operational Docs](06-operational-docs.md)                   | Place runbooks, diagnostics, case studies, and workflows in zones. |
| 7        | [AI Agent Considerations](07-ai-agent-considerations.md)     | Reduce context pollution with semantic names and tight docs.       |
| 8        | [Tracking and Revalidation](08-tracking-and-revalidation.md) | Track perishable facts and revalidate their sources on a cadence.  |
| 9        | [Known Issues](09-known-issues.md)                           | Track bugs in external systems under test; expand then collapse.   |
| 99       | [Checklist](99-checklist.md)                                 | Review checklist for docs changes.                                 |
| Template | [ADR template](template-adr.md)                              | Drop-in lean ADR template for project decisions.                   |

## Defaults

- Put decisions in `<project>/docs/decisions/`.
- Put task docs and runbooks in `<project>/docs/guides/`.
- Put lookup, diagnostics, and case studies in `<project>/docs/reference/`.
- Put architecture overviews and conceptual background in `<project>/docs/explanation/`.
- Keep filled ADRs at or below 350 words.
- Never delete accepted decisions; supersede or reject them.
- Keep drafts in `<project>/.draft/` or another gitignored workspace.
- Write each durable fact once and cross-link from everywhere else.
- Track bugs in external systems under test as known-issue cases under
  `<project>/docs/reference/known-issues/`; expand while hot, collapse to one summary when resolved.
- Track perishable facts in a machine-readable registry with a cadence and a `last_checked` date.
- Keep code comments load-bearing: rationale, invariants, boundary conditions, and links to owning
  decisions.
- Keep agent digests derived from source chapters; never let the digest become the source of truth.
- Keep the root docs README as navigation. If it starts carrying decisions, procedures, or
  diagnostic facts, move those facts to the owning zone and link back.
- Let the filesystem own structure: index files (README/AGENTS) explain purpose; they never
  replicate the directory tree.
