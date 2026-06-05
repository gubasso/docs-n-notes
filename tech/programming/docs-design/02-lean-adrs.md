# 02 — Lean ADRs

Architecture decision records preserve why a project chose one path over serious alternatives. They
are not tutorials, meeting notes, or design novels. A useful ADR is short, statused, and durable
enough that future maintainers can trust it.

## Default template

Use the drop-in [ADR template](template-adr.md). A filled ADR has five sections:

- `Context and Problem Statement`: the problem and why it matters.
- `Considered Options`: the serious alternatives, not every idea mentioned in chat.
- `Decision Outcome`: the chosen option and the shortest honest reason.
- `Consequences`: positive and negative trade-offs.
- `Status`: one canonical lifecycle value.

This is a MADR-minimal shape: enough structure to compare decisions consistently, not enough
structure to invite filler. MADR itself is broader; use only the parts that force clarity. See
<https://adr.github.io/madr/> and <https://ozimmer.ch/practices/2022/11/22/MADRTemplatePrimer.html>.

The template is a format contract. Do not add project-specific sections unless the project has an
active, repeated need for them. If a field is consistently empty, remove the field from the local
template or stop creating ADRs for that class of choice.

Name ADR files so they sort and search well: `ADR-<number>-<decision>.md` or the local equivalent.
The number gives stable references in comments, reviews, and follow-up ADRs. The short decision slug
gives humans and agents enough context from filenames alone. Avoid status or date-only names; status
changes, and dates rarely describe the decision.

The title should name the choice, not the implementation task. Prefer "Use `<system>` for artifact
storage" over "Implement storage support." The first title records a decision. The second sounds
like a ticket.

## Word cap

Filled ADR bodies must be at or below 350 words. The cap is a forcing function:

- One page is reviewable in code review.
- Short records are easy for LLM agents to load and compare.
- A hard limit exposes decisions that should be split.
- The record stays focused on the durable choice, not the whole discovery trail.

If the ADR needs more room, first remove narrative detail. If it still needs more room, split the
decision. A project can link multiple ADRs in a small series: one for storage format, one for API
shape, one for migration behavior. That is better than one large record whose status and
consequences blur together.

The word cap applies to the filled decision body, not to surrounding index pages or templates.
Diagrams, large option matrices, or benchmark data belong in reference or explanation pages linked
from the ADR.

The cap also prevents ADRs from becoming hidden specifications. If a decision requires exact API
fields, command examples, or migration steps, put those in reference or guides and link them. The
ADR should say why those artifacts exist and which option they enact.

## Lifecycle

Use this lifecycle:

`Proposed -> Accepted -> Implemented -> Superseded | Rejected`

`Proposed` means the record is ready for review but not yet binding. `Accepted` means the project
has chosen the direction. `Implemented` means the code, docs, or operations now enact the choice.
`Superseded` means a later ADR replaced it. `Rejected` means the project explicitly decided not to
take that path.

Every implemented ADR should link to the code, configuration, or documentation that enacts it when
there is a stable target. Every superseded ADR should link to the successor. Every rejected ADR
should explain enough that the same option is not reopened without new evidence.

Status changes are edits to history, not rewrites of history. When moving from `Accepted` to
`Implemented`, keep the original context and outcome intact. Add the implementation link. When
moving to `Superseded`, add a short pointer to the successor and stop there. The successor ADR owns
the new reasoning.

## Never delete

Do not delete accepted, implemented, superseded, or rejected ADRs. They are part of project history.
Deleting them destroys context and makes old reviews, commits, and comments harder to understand.

Deletion is appropriate for drafts that never became project state. Once an ADR is accepted, change
its status instead of removing it. If the title was misleading, keep the file and clarify the
decision outcome. If the decision was wrong, supersede it. If the project backed away before
implementation, reject it.

Never-delete does not mean never-correct. Fix typos, broken links, and misleading wording. Correct
metadata that was wrong when written. Do not edit an old ADR to pretend a later design was the
original choice. If the meaning changed, write a new ADR or change the status.

This mirrors the precedent of durable proposal systems: Rust RFCs
<https://rust-lang.github.io/rfcs/0002-rfc-process.html>, Python PEPs
<https://peps.python.org/pep-0001/>, and Kubernetes KEPs
<https://github.com/kubernetes/enhancements/blob/master/keps/sig-architecture/0000-kep-process/README.md>.
Those systems preserve decision history because later readers need the trail, not just the latest
state.

## Comparisons

Nygard's original ADR format is intentionally small: title, status, context, decision, consequences.
It can often land around 200 words when the decision is narrow. Source:
<https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions>.

MADR-minimal is slightly more structured. It names considered options and keeps consequences
visible, often around 250 words for a well-scoped decision. That extra structure helps reviewers see
whether the project considered real alternatives.

Y-Statements compress the choice into one sentence with named parts: in the context of a problem,
facing forces, the project decided for one option and neglected others to achieve qualities while
accepting downsides. A Y-Statement can be around 40 words. Use that form for quick summaries, but
prefer the lean ADR template when the project needs durable review history.

The practical default is the lean ADR. It is short enough for review, structured enough for future
readers, and explicit enough for agents to classify.

Use Y-Statements inside summaries, release notes, or ADR indexes when a one-line decision reminder
is enough. Do not replace the ADR with a Y-Statement when the project needs status, consequences, or
links to implementation. Use Nygard's smallest shape when the project has no need to list options.
Use MADR-minimal when review should show what was seriously considered.

## Status values

Use exactly one status value per ADR:

- `Proposed`: open for review.
- `Accepted`: chosen, not necessarily implemented.
- `Implemented`: enacted by the project.
- `Superseded`: replaced by a later ADR.
- `Rejected`: explicitly not chosen.

Do not invent status synonyms such as `Done`, `Deprecated`, `Canceled`, or `Obsolete`. Synonyms make
filtering and agent reasoning harder. If the project needs more detail, add one sentence after the
status and link to the successor or implementation.

Use status as data. Reviewers, scripts, and agents should be able to grep for `Status` and classify
the decision without reading the whole file. If the status line needs explanation every time, the
status vocabulary is too large or the decision is doing too much.

## Sources

- Nygard ADR article: <https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions>
- MADR: <https://adr.github.io/madr/>
- MADR primer: <https://ozimmer.ch/practices/2022/11/22/MADRTemplatePrimer.html>
- Rust RFC process: <https://rust-lang.github.io/rfcs/0002-rfc-process.html>
- Python PEP process: <https://peps.python.org/pep-0001/>
- Kubernetes KEP process:
  <https://github.com/kubernetes/enhancements/blob/master/keps/sig-architecture/0000-kep-process/README.md>

See [04 — Single Source of Truth](04-single-source-of-truth.md) for where ADR facts should be linked
instead of repeated.
