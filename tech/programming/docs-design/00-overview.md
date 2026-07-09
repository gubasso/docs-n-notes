# 00 — Overview

This shelf defines a project-agnostic pattern for organizing software project documentation. It is
for projects that need durable docs, clear decision history, and instructions that both humans and
LLM agents can load without wasting attention on duplicates.

## Problem

Most project documentation decays for predictable reasons. A rule starts in a design note, gets
copied into a README, is restated in an onboarding guide, and then changes in only one place. A
draft records useful reasoning but never becomes a decision. A troubleshooting page grows into a
mixed bag of runbooks, diagnostics, background, and stale conclusions. Eventually readers stop
trusting the docs and fall back to guessing from code, chat history, or old issues.

The cure is not more ceremony. The cure is a small set of homes with clear ownership. Each fact
should have one durable source of truth. Each document should serve one reader need. Each decision
should stay short enough to be reviewed, indexed, and superseded when it stops being true.

This pattern uses Diataxis for reader needs, lean ADRs for decision history, ARID for
single-source-of-truth placement, and load-bearing comments for rationale that belongs next to code.
See <https://diataxis.fr/> and <https://www.writethedocs.org/guide/writing/docs-principles/>.

## Defaults

- Use four documentation zones: decisions, guides, reference, and explanation.
- Put architecture decisions in lean ADRs under `<project>/docs/decisions/`.
- Keep filled ADRs at or below 350 words.
- Never delete accepted decisions. Mark them superseded or rejected and link forward.
- Put task instructions and runbooks under `<project>/docs/guides/`.
- Put lookup material, diagnostics, and case studies under `<project>/docs/reference/`.
- Put cross-cutting architecture and conceptual background under `<project>/docs/explanation/`.
- Keep project-wide authoring rules in `<project>/CLAUDE.md` or the local equivalent.
- Keep code rationale in code comments only when the comment is load-bearing.
- Keep drafts outside shipped docs, normally under `<project>/.draft/`.

The point is not to force every project into a heavy documentation system. The point is to make
common placement decisions boring. When a new doc appears, the maintainer should know where it
belongs before writing the second paragraph.

## Principles

**Lean ADRs.** Architecture decision records are for the decision, not the whole debate. A useful
ADR names the problem, lists serious options, records the chosen option, states consequences, and
declares status. If the record cannot fit within 350 words, the project probably made multiple
decisions and should split them.

**Never-delete lifecycle.** Decision history is evidence. If a decision becomes wrong, mark it
`Superseded` and link to the replacement. If the project considered and rejected an option, keep
that rejection when it prevents repeated debate. Deletion is reserved for drafts that never became
project state.

**Single-source-of-truth placement.** Write once at the owning home and link from other places.
Restatement creates drift. A README can point to the ADR. A guide can link to reference material. An
agent digest can summarize a chapter, but the chapter remains the source.

**Comments as load-bearing documentation.** A comment earns its place when deleting it would confuse
a future maintainer. Good comments explain why a surprising boundary exists, which invariant must be
preserved, or which external constraint forced the shape. Comments that narrate obvious code should
be removed or replaced with better names and types.

## When to apply

Apply this pattern to any project with a `docs/` directory, more than one maintainer, recurring
design decisions, operational procedures, or an LLM agent in the loop. The pattern is especially
useful when project knowledge must survive handoffs, code review, and future automation.

Use it early enough that docs do not sprawl. A small project can start with only `docs/decisions/`,
`docs/guides/`, and `docs/reference/`; the zones do not require many files. The layout becomes
valuable as soon as the first reader asks whether a document is a how-to, a lookup page, background
explanation, or a recorded decision.

## When not to apply

Do not spend time on this structure for a throwaway spike with no readers beyond the author. Do not
create empty directories to signal maturity. Do not write an ADR for a choice that is local,
obvious, and fully expressed by a type name or function signature. Do not promote a draft just
because it exists.

The pattern should reduce maintenance load. If applying it creates more documents than the project
can keep truthful, shrink the set of documents. Keep the placement rules; reduce the inventory.

## See also

- [01 — Diataxis Zones](./01-diataxis-zones.md) defines the reader-needs layout.
- [02 — Lean ADRs](./02-lean-adrs.md) defines decision records and lifecycle.
- [03 — Comments and Code as SoT](./03-comments-and-code-as-sot.md) defines when rationale belongs
  next to code.
- [04 — Single Source of Truth](./04-single-source-of-truth.md) defines placement and cross-link
  discipline.
