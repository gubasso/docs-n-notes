# 07 — AI Agent Considerations

LLM agents consume documentation differently from humans, but they suffer from the same failure
modes: unclear ownership, stale repetition, vague names, and oversized context. A docs system that
is easy for a maintainer to navigate is usually easier for an agent to use.

## Context pollution

Documentation bloat is context pollution. Every duplicated rule, stale draft, and oversized ADR
competes with source code, test output, and the user's current request. Agents do not need more
text; they need the right text at the right path.

Lean docs help because they reduce retrieval ambiguity. A file named
`<project>/docs/decisions/ADR-<number>-<decision>.md` tells the agent it is reading why. A file
under `<project>/docs/guides/<topic>/` tells the agent it is reading a procedure. A reference page
tells the agent to look for exact values.

The same logic appears in context-engineering discussions: retrieval quality and context selection
matter as much as raw model capacity. See <https://arxiv.org/html/2510.21413v1> and
<https://mem0.ai/blog/context-engineering-ai-agents-guide>.

Context pollution has a practical cost. The agent may miss the active rule because an older copy
appears earlier in search results. It may summarize a draft as if it were project state. It may
spend tokens comparing two duplicated tables instead of editing the code. The documentation system
should make the right file obvious.

Short documents are not automatically good, but focused documents are easier to retrieve and verify.
The 350-word ADR cap exists because decision records are frequently loaded into reviews, prompts,
and maintenance sessions.

Agents also amplify stale docs. A human might notice that a page is old from surrounding context. An
agent may quote it confidently if the path and heading look authoritative. This is another reason
drafts must stay out of shipped docs and superseded decisions must link forward.

## Semantic names

Names are retrieval hints. Use names that expose document purpose before the file is opened:

- `ADR-<number>-<decision>.md` for decisions.
- `<task>-runbook.md` for runbooks.
- `<topic>-diagnostics.md` for diagnostic lookup.
- `<subsystem>-architecture.md` for explanation.
- `template-adr.md` for reusable templates.

Avoid names like `notes.md`, `misc.md`, `new-plan.md`, and `final-v2.md`. They force humans and
agents to inspect content. They also make search results noisy.

Headings matter too. Stable headings let agents skim and anchor edits. Prefer direct headings such
as `## Status values`, `## Placement rules`, and `## Verification` over clever prose.

Use consistent vocabulary across files. If the project calls a document a runbook in one place and a
recovery play in another, search and retrieval become weaker. Pick the term that matches the zone,
then reuse it.

Semantic names also help humans review agent changes. A pull request that creates
`docs/reference/<topic>/<topic>-diagnostics.md` communicates intent before the reviewer opens the
file.

Names should avoid local jokes, temporary project codenames, and issue-only identifiers. Those names
may be meaningful during implementation but weak months later. Put durable nouns in filenames and
temporary context in drafts or issues.

## Entry points

Use author-instructions files as the entry point for agents. The project can use `CLAUDE.md`,
`AGENTS.md`, or an equivalent file. That entry point should tell agents where documentation rules
live and which docs are canonical.

The pattern is:

- Author-instructions file: project rules and maintenance constraints.
- `docs/README.md`: human index into project docs.
- `docs/decisions/`: durable why.
- `docs/guides/`: procedures.
- `docs/reference/`: lookup.
- `docs/explanation/`: mental models.
- Local `AGENTS.md` digests: concise maps derived from source notes.

Do not let an agent digest become the source of truth. Digests summarize. Chapters and project docs
own the rules. See [04 — Single Source of Truth](04-single-source-of-truth.md).

When an agent asks where to edit, the entry point should answer with ownership, not prose volume.
The best answer is usually a path and a rule: "edit the ADR for why," "edit the reference page for
exact values," or "edit the guide for the task sequence."

Project entry points should also say what not to do. For documentation, the most useful negative
rules are: do not duplicate facts, do not add file trees, do not commit drafts into docs, and do not
invent a new document zone for one topic.

## Documentation maintenance instructions

Every project that expects agent help should add a `## Documentation Maintenance` section to its
author-instructions file. That section should say:

- Use the Diataxis zones from this pattern.
- Put decisions in lean ADRs and keep them at or below 350 words.
- Never delete accepted decisions; supersede or reject them.
- Keep drafts outside shipped docs.
- Write facts once at the owning home and cross-link elsewhere.
- Do not paste filesystem trees into markdown.
- Preserve placeholders in project-agnostic material.

These rules prevent well-meaning agents from creating sprawling summaries, duplicating facts, or
promoting drafts without review. The rules also give reviewers a compact checklist to enforce. See
[99 — Checklist](99-checklist.md) and [02 — Lean ADRs](02-lean-adrs.md).

The maintenance section should be project-specific, not a pasted copy of this shelf. Link to this
pattern or summarize its local adoption. Then state any local exceptions, such as a different
author-instructions filename or a specific ADR numbering convention.

Agents should be instructed to update docs only when the change affects durable behavior,
operations, or decisions. They should not create explanatory files for every implementation detail.
Small local rationale belongs in code comments when it passes the load-bearing test.

Finally, agents should report doc changes by ownership: which source of truth changed, which links
were added, and which hooks passed. That report is easier to review than a broad claim that "docs
were updated."

## Sources

- Context engineering survey: <https://arxiv.org/html/2510.21413v1>
- Agent context guide: <https://mem0.ai/blog/context-engineering-ai-agents-guide>
