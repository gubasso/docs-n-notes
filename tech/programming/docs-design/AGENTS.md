---
digest-of: tech/programming/docs-design
last-synced: 2026-06-30
source-files:
  - README.md
  - 00-overview.md
  - 01-diataxis-zones.md
  - 02-lean-adrs.md
  - 03-comments-and-code-as-sot.md
  - 04-single-source-of-truth.md
  - 05-drafts-and-promotion.md
  - 06-operational-docs.md
  - 07-ai-agent-considerations.md
  - 08-tracking-and-revalidation.md
  - 09-known-issues.md
  - 99-checklist.md
  - template-adr.md
token-estimate: 3350
---

# AGENTS

## Scope

Language-agnostic documentation design canon: Diataxis zones, lean ADRs, load-bearing comments,
single-source-of-truth placement, draft promotion, operational docs, agent-aware maintenance,
tracking and revalidation, and a review checklist for documentation changes.

## Key Points

### Overview (00)

- Default to four zones: decisions, guides, reference, explanation.
- Use lean ADRs, never-delete lifecycle, SoT placement, and load-bearing comments.
- Apply the pattern when projects have durable docs, multiple readers, or LLM agents in the loop.
- Keep the root docs README as an index, not a junk drawer for durable rules.

### Diataxis Zones (01)

- Guides answer task questions; reference answers lookup questions.
- Explanation teaches mental models; decisions record why.
- Use zone-first placement, then topic directories inside the zone.
- Split documents that try to satisfy multiple reader needs.

### Lean ADRs (02)

- Use the MADR-minimal sections: context, options, outcome, consequences, status.
- Filled ADR bodies stay at or below 350 words.
- Lifecycle is `Proposed -> Accepted -> Implemented -> Superseded | Rejected`.
- Never delete accepted decisions; link to successors or rejecting ADRs.
- Supporting data belongs in reference or explanation, linked from the ADR.

### Comments and Code as SoT (03)

- Code owns behavior; comments own rationale code cannot express.
- Keep comments for boundary conditions, invariants, surprising constraints, and ADR links.
- Delete comments that narrate obvious code or replace them with better names and types.
- Use tests and types for behavior contracts where they can enforce the rule.

### Single Source of Truth (04)

- Avoid Repetition In Documentation: write once at the owning home, link elsewhere.
- Project-wide rules live in author instructions; decisions in ADRs; exact facts in reference.
- Structure is owned by the filesystem; index files explain purpose and never replicate the tree.
- Resolve conflicts by editing non-owner files to link to the owner.
- A digest is a map; source chapters and project docs own the guidance.

### Drafts and Promotion (05)

- Drafts live outside shipped docs, normally in `<project>/.draft/`.
- Promotion rewrites the draft into the right zone and then deletes the draft.
- Split mixed drafts by reader need before promotion.
- Promote rejected paths as rejected ADRs only when the rejection has future value.

### Operational Docs (06)

- Runbooks and workflows are guides.
- Diagnostics and case studies are reference.
- Avoid top-level topic folders beside the Diataxis zones.
- Keep runbooks action-oriented and move exact signal interpretation to reference.

### AI Agent Considerations (07)

- Documentation bloat is context pollution.
- Semantic filenames and stable headings improve retrieval.
- `CLAUDE.md` or equivalent author instructions should include documentation maintenance rules.
- Agents should update docs for durable behavior, operations, or decisions, not every detail.

### Tracking and Revalidation (08)

- A tracking file is a machine-readable registry of perishable artifacts and their re-check cadence.
- The tracked artifact stays the source of truth; the registry keeps it from going stale.
- Overdue scanning is deterministic tooling; revalidation is judgment and should surface uncertain
  drift.
- Primary audience is coding agents sweeping the repo; humans benefit too.

### Known Issues (09)

- Bugs in external systems under test are tracked as known-issue cases under
  `<project>/docs/reference/known-issues/` (reference zone), not a top-level topic folder.
- One case = one directory `KI-<NNNN>-<slug>/` (sequential id, keyed on the internal id, not the
  upstream bug); skeleton is README/issue.yaml/investigation/escalation/optional
  mask/evidence/notes.
- Lifecycle `open → investigating → mitigated | masked → monitoring → resolved`; on resolution the
  directory collapses to one `resolved/` summary (issue/root-cause/resolution/recurrence), raw trail
  in VCS history.
- Link code to a case with a marker/comment carrying the id; mask suppressions carry a revert
  trigger and checklist; a registry index + CI check keep references and directories in sync.

### Checklist (99)

- Review placement, ADR length and status, draft handling, cross-links, agent readiness, known-issue
  cases, and hook validation before merging documentation changes.
- The checklist is the pre-merge guard for both human and agent-authored doc edits.

### ADR Template

- Copy `template-adr.md` into `<project>/docs/decisions/template.md`.
- Keep each field brief and split separate decisions into separate ADRs.
- The template is copied into a project; the filled ADR becomes the project source of truth.

## Source Map

| Topic                        | File                                 |
| ---------------------------- | ------------------------------------ |
| Shelf purpose and defaults   | `README.md`, `00-overview.md`        |
| Diataxis zones and placement | `01-diataxis-zones.md`               |
| ADR format and lifecycle     | `02-lean-adrs.md`, `template-adr.md` |
| Comments and code rationale  | `03-comments-and-code-as-sot.md`     |
| Source-of-truth rules        | `04-single-source-of-truth.md`       |
| Draft workflow               | `05-drafts-and-promotion.md`         |
| Operational docs             | `06-operational-docs.md`             |
| Agent considerations         | `07-ai-agent-considerations.md`      |
| Tracking and revalidation    | `08-tracking-and-revalidation.md`    |
| Known issues (external bugs) | `09-known-issues.md`                 |
| Review checklist             | `99-checklist.md`                    |

## Maintenance Notes

- Regenerate when any chapter file changes or a new chapter is added.
- Keep this digest derived from the listed source files; do not introduce new rules here.
- Agents should load this digest first, then read the source chapter that owns the current change.
- When the digest and a source chapter disagree, treat the source chapter as authoritative and
  regenerate the digest.
- Keep source-file ordering stable so context loaders can compare revisions predictably.
