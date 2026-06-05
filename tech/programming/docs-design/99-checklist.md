# 99 — Checklist

Use this checklist before merging new or changed documentation. If a box is unchecked, fix the doc
or record an explicit exception in the owning source of truth.

## New or changed docs

- [ ] The file has one primary reader need: task, lookup, understanding, or decision.
- [ ] The file lives in the matching zone from [01 — Diataxis Zones](01-diataxis-zones.md).
- [ ] The file does not restate a fact already owned elsewhere.
- [ ] Cross-links point to the owning source instead of copying it.
- [ ] No filesystem trees are pasted into markdown.
- [ ] Project-agnostic docs use `<angle>` placeholders for project-specific names.
- [ ] The root docs README remains an index, not a duplicate source of rules.

## ADRs

- [ ] New ADRs use the sections from [02 — Lean ADRs](02-lean-adrs.md).
- [ ] The filled ADR body is at or below 350 words.
- [ ] The ADR has exactly one canonical `Status:`.
- [ ] Status is one of `Proposed`, `Accepted`, `Implemented`, `Superseded`, or `Rejected`.
- [ ] Implemented ADRs link to the code, config, or docs that enact them when a stable target
      exists.
- [ ] Superseded ADRs link to the successor.
- [ ] Rejected ADRs explain enough to prevent repeated debate without new evidence.
- [ ] The project did not delete an accepted or implemented decision.
- [ ] Supporting data too large for the ADR lives in reference or explanation and is linked.

## Placement

- [ ] Project-wide rules live in `<project>/CLAUDE.md` or the local equivalent.
- [ ] Architecture decisions live in `<project>/docs/decisions/`.
- [ ] Step-by-step workflows and runbooks live in `<project>/docs/guides/`.
- [ ] Lookup, diagnostics, and case studies live in `<project>/docs/reference/`.
- [ ] Cross-cutting overview or architecture lives in `<project>/docs/explanation/`.
- [ ] Non-obvious local code rationale lives in code comments, not distant prose.
- [ ] Behavior contracts are expressed by names, types, and tests where possible.
- [ ] The file that owns the fact is clear enough that future edits have one target.

See [04 — Single Source of Truth](04-single-source-of-truth.md).

## Drafts

- [ ] Drafts stay outside `<project>/docs/`.
- [ ] Promotion rewrites the draft into a durable doc instead of moving it unchanged.
- [ ] The promoted document has one reader need.
- [ ] The old draft is deleted or remains clearly local and ignored.
- [ ] No draft is the only home for a real project decision.
- [ ] Promotion removed temporary reasoning and repeated facts.

See [05 — Drafts and Promotion](05-drafts-and-promotion.md).

## Agent readiness

- [ ] Filenames expose purpose before content is opened.
- [ ] Headings are stable and direct.
- [ ] `CLAUDE.md` or the local author-instructions file does not contradict the docs.
- [ ] `AGENTS.md` digests summarize source files only.
- [ ] Oversized ADRs, repeated tables, stale drafts, and broad summaries have been trimmed.
- [ ] Filenames can be understood from search results without opening the files.

See [07 — AI Agent Considerations](07-ai-agent-considerations.md).

## Verification

- [ ] Cross-links pass the project's link-check hook.
- [ ] Spelling and markdown hooks pass.
- [ ] Operational docs are under guides or reference, not topic directories beside the Diataxis
      zones.
- [ ] Comments added with the docs change are load-bearing per
      [03 — Comments and Code as SoT](03-comments-and-code-as-sot.md).
- [ ] The reviewer can name the source of truth for every durable fact touched by the change.
- [ ] Any generated digest was updated from source files and does not introduce new guidance.
