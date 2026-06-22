# 04 — Single Source of Truth

Documentation stays trustworthy when every durable fact has one owner. Other files may link to that
owner, summarize it briefly, or explain how to use it, but they must not become parallel sources of
truth.

## ARID

Use ARID: Avoid Repetition In Documentation. The principle is practical, not aesthetic. Repeated
facts drift. Drift makes readers choose between conflicting pages. Once readers stop trusting the
docs, they return to chat logs, old issues, or guesswork.

Write the fact once where it belongs. Link from every other context. The Write the Docs principles
frame this as documentation that is purposeful, maintained, and useful to readers:
<https://www.writethedocs.org/guide/writing/docs-principles/>.

ARID does not forbid short summaries. A README can say "Decisions live in `docs/decisions/`." A
guide can say "This workflow assumes ADR-<number>." The line is crossed when the summary becomes a
second place to update the same rule.

A good summary is disposable. If deleting it leaves the canonical fact intact and discoverable, it
is a summary. If deleting it removes the only current statement of the rule, it has become a source
of truth and belongs at the owning home.

## Placement table

| Content                                | Home                                                         |
| -------------------------------------- | ------------------------------------------------------------ |
| Project-wide rules                     | `<project>/CLAUDE.md` or equivalent author-instructions file |
| Architecture decisions                 | `<project>/docs/decisions/`                                  |
| Step-by-step workflows and runbooks    | `<project>/docs/guides/`                                     |
| Lookup, diagnostics, and case studies  | `<project>/docs/reference/`                                  |
| Cross-cutting overview or architecture | `<project>/docs/explanation/`                                |
| Non-obvious code rationale             | Code comments                                                |
| Behavior contracts                     | Type signatures and names                                    |

Use this table when adding or reviewing docs. If the content has no obvious home, ask which reader
need it serves. If it serves several needs, split it.

Project-wide rules belong in the author-instructions file because humans and agents load it before
editing. ADRs belong in decisions because they record why. Runbooks belong in guides because they
are task sequences. Diagnostic signatures belong in reference because readers look them up under
pressure. Architecture overviews belong in explanation because they teach the mental model.

Behavior contracts should live as close to execution as possible. A function name, type signature,
schema, validation model, or test is stronger than prose because it participates in change. Use
documentation to point readers at the contract and explain surrounding context. Do not make a prose
page the only place a required argument, status value, or invariant exists.

The same rule applies to generated material. Generated API docs, schemas, or digests can be useful
entry points, but generation does not make them canonical unless the generator's source is the
owner. Know whether readers should edit the generated output, the source file, or neither.

Code comments are a narrow home. They own local rationale that would be invisible from names and
types. They do not own project policy, status matrices, or workflows. See
[03 — Comments and Code as SoT](03-comments-and-code-as-sot.md).

## Structure is owned by the filesystem

Directory structure is a durable fact, and the filesystem already owns it. A README or index file
must not maintain a parallel copy of the file tree. The directory listing is the source of truth for
what exists; readers and agents can list the directory to see it.

Index files — `README.md`, `CLAUDE.md`, `AGENTS.md`, and equivalents — explain what a directory is
for: its purpose, domains, concepts, and rules. They do not reproduce a tree of every file and
subdirectory. A pasted tree drifts the moment a file is added, renamed, or removed, and the stale
copy then competes with the real structure.

When a listing genuinely aids discovery, give each entry a purpose, not a bare path. A line like
`- [docker](docker.md) — daemon setup and daily commands` tells the reader why to open the file; a
line like `- [docker](docker.md)` only restates the filename the filesystem already shows. The test
is the same as for any summary: if deleting the listing loses no information the filesystem does not
already carry, it was a duplicated tree, not an index.

This is the structural case of the rule above: write each durable fact once at its owner. The owner
of "what files exist here" is the directory itself.

## Cross-link discipline

Write once. Link everywhere else. A cross-link should name the reason to follow it:

- "For the decision, see ADR-<number>."
- "For accepted status values, see `<project>/docs/reference/<topic>/`."
- "For the operational procedure, see the runbook in `<project>/docs/guides/<topic>/`."

Do not paste the same table into a guide, reference page, and ADR. Do not copy a rule from
`CLAUDE.md` into every chapter. Do not turn an agent digest into the canonical source. A digest is a
map; the chapters remain the territory.

When a link points outside the project, make the link stable and checkable. Prefer canonical
documentation URLs. Use archive links only when the canonical source is gone or unreliable.

Cross-links should be specific. Link to the chapter, section, ADR, or reference page that owns the
fact. Avoid vague links such as "see docs" or "see the README." A specific link tells future editors
where to update the fact and tells agents which context to load.

Use short local context before the link. A reader should know why the link matters: "cleanup order
is defined by ADR-<number>" is better than "see ADR-<number>." The first form names the claim
without restating the reasoning.

Prefer relative links inside the project so files keep working across branches, forks, and local
checkouts. Use absolute external URLs only for outside sources. Keep external citations bare enough
for the link checker to verify.

## Conflict resolution

When two files disagree, use the placement table:

- Project-wide editing rules beat chapter summaries.
- ADRs beat explanation pages for why a decision was made.
- Reference pages beat guides for exact values.
- Guides beat reference pages for task sequence.
- Code beats prose for current behavior.
- Load-bearing comments beat distant explanation for local invariants.

After choosing the owner, edit the non-owner file to link to it. Do not leave both claims in place.
If the conflict reveals a changed decision, write or update an ADR and mark the older decision
superseded. See [02 — Lean ADRs](02-lean-adrs.md).

Operational docs use the same conflict rule. If a runbook embeds a diagnostic table, move the table
to reference and link to it. See [06 — Operational Docs](06-operational-docs.md).

Do not resolve conflicts by adding a third summary page. That hides the drift while preserving the
two stale claims. Resolve ownership first, then update or delete duplicated prose. The end state
should have one owner and as many links as useful.

When ownership is ambiguous, choose the page whose readers suffer most if the fact is stale. Status
values stale in reference break debugging. Decision rationale stale in an ADR breaks future design
review. Task sequence stale in a guide breaks execution.

## Sources

- Write the Docs, documentation principles:
  <https://www.writethedocs.org/guide/writing/docs-principles/>
