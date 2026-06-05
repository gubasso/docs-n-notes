# 06 — Operational Docs

Operational documentation often grows outside the normal docs model because it starts under
pressure. A fix becomes a runbook. A failure analysis becomes a case study. A diagnostic command
becomes a reference page. The Diataxis zones still apply.

## Runbooks

Runbooks are how-to guides. Put them under `<project>/docs/guides/<topic>/runbooks/` when there are
several for one topic, or under `<project>/docs/guides/<topic>/` when there is only one.

A runbook should include:

- Preconditions.
- Ordered actions.
- Verification.
- Rollback or stop conditions.
- Links to diagnostics and reference facts.

Do not embed a full diagnostic catalog in a runbook. Link to reference. The runbook owns the task
sequence; reference owns exact lookup data.

Write runbooks for execution under pressure. Use imperative steps, short verification checks, and
clear stop conditions. A runbook that requires the reader to understand the whole architecture
before acting is not a runbook; move that background to explanation and link to it.

Every destructive or irreversible action should name the confirmation point before the action. If a
step depends on environment, credentials, or maintenance windows, make the prerequisite explicit.

Prefer commands and checks that can be copied safely. If a command contains placeholders, make them
obvious with `<angle>` names. If a command is destructive, require the guide to show the dry-run or
inspection command first when the underlying tool supports one.

## Case studies

Case studies are reference. Put them under `<project>/docs/reference/<topic>/case-studies/`.

A case study records what happened, what signals were present, what fixed it, and what durable
lesson remains. It should be easy to compare with a future incident or failure mode. It should not
be the only home for a new rule. If the case study changes policy, write an ADR or update the
author-instructions file and link to it.

Use placeholders in reusable pattern material. Concrete timestamps, people, hosts, private package
names, and project-specific identifiers belong only in the project that experienced the event.

Keep case studies factual and bounded. They are useful because they preserve a concrete example of a
failure mode, not because they become policy by themselves. When a case study motivates a permanent
rule, create or update the owning rule and link back.

Case studies should age gracefully. If a later runbook or ADR supersedes the lesson, update the case
study with a link instead of rewriting the event as if the newer rule existed at the time.

## Diagnostics

Diagnostic recipes are reference. Put them under `<project>/docs/reference/<topic>/`.

A diagnostic page should optimize for lookup:

- Symptom.
- Signal or command.
- Expected result.
- Interpretation.
- Link to the guide or runbook that uses it.

Avoid narrative troubleshooting pages that mix every symptom, command, and remediation path in one
long flow. Split repeated procedures into guides. Keep exact signal interpretation in reference.

Diagnostic pages should be easy to scan. Prefer small tables, stable headings, and exact terms from
the system under test. If a diagnostic command changes behavior across versions, record the version
constraint or link to the authoritative reference.

A good diagnostic page helps a reader decide what bucket a failure is in. It does not need to solve
every bucket inline. Link from the signal to the runbook, guide, or case study that owns the next
step.

## Workflows and setup

Workflows and setup walkthroughs are guides. Put them under `<project>/docs/guides/<topic>/`.

Examples:

- Creating a local development environment.
- Rotating a credential.
- Publishing a release.
- Running a migration.
- Recovering a failed job.

Each guide should have a clear start state, end state, and verification step. If the guide needs
long background, link to explanation. If it needs long tables, link to reference.

Setup docs are still guides. They should not become a mirror of every configuration option. Link to
configuration reference for accepted values and defaults. The guide owns the path through the work.

## Avoid topic-sibling trees

Do not create top-level topic directories as siblings of decisions, guides, reference, and
explanation. A directory named only after `<topic>` hides reader intent. It usually accumulates a
mix of task steps, exact lookup data, design rationale, and background prose.

Prefer zone-first placement:

- Runbooks -> `<project>/docs/guides/<topic>/runbooks/`.
- Case studies -> `<project>/docs/reference/<topic>/case-studies/`.
- Diagnostic recipes -> `<project>/docs/reference/<topic>/`.
- Workflows and setup walkthroughs -> `<project>/docs/guides/<topic>/`.

This keeps operational docs findable under pressure. A reader who needs to act starts in guides. A
reader who needs to compare signals starts in reference.

The rule scales with volume. A tiny project may have one operational guide and one diagnostics page.
A large project may have many topic directories inside guides and reference. In both cases, reader
need comes first and topic comes second.

If the operational docs become hard to scan, improve indexes inside each zone. Do not fix scale by
adding a new top-level operational bucket that duplicates the Diataxis model.

## See also

- [01 — Diataxis Zones](01-diataxis-zones.md) for reader-needs placement.
- [04 — Single Source of Truth](04-single-source-of-truth.md) for conflict resolution and linking.
