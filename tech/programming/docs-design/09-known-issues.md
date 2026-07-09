# 09 — Known Issues

Projects that test or integrate **external systems they do not own** accumulate a special kind of
finding: a bug that lives in the system under test (a server, a client, a vendor API), not in this
codebase. These findings are not decisions, runbooks, or background — they are diagnostics and case
studies. They need a durable home, a status, and a lifecycle that lets a directory of evidence
**expand while the issue is hot** and **collapse to one lean summary when it is resolved**.

Without that home, the knowledge lives in memory and chat logs. The next time the symptom recurs,
someone re-derives the whole investigation instead of grepping one id.

## Where it lives

A known-issue case library is **reference** material (diagnostics, known symptoms, case studies —
see [01 — Diataxis Zones](./01-diataxis-zones.md) and
[06 — Operational Docs](./06-operational-docs.md)). Put it at:

```text
<project>/docs/reference/known-issues/
```

Do **not** create a top-level `<project>/docs/known-issues/` — that is the topic-sibling
anti-pattern from chapter 01. Reader need (lookup) comes first; the topic (`known-issues`) comes
after the zone.

## One case = one directory

Each tracked issue is its own directory, keyed on an **internal** id — not the upstream bug number,
because the finding usually predates any filed bug and one finding can map to several upstream bugs.

```text
docs/reference/known-issues/
  README.md          # the registry/index (status table; see below)
  registry.yaml      # optional machine-readable index for a lint/CI check
  TEMPLATE/          # copy-to-start skeleton
  KI-<NNNN>-<slug>/
    README.md        # index card: frontmatter + status banner + TL;DR + map
    issue.yaml       # machine-readable metadata
    investigation.md # chronological lab-notebook log
    escalation.md    # self-contained upstream report (copy-pasteable to the vendor)
    mask.md          # temporary-workaround revert ledger (only when a mask exists)
    evidence/        # raw artifacts: logs, captured payloads, probe output
    notes/           # supporting source-grounded reference
  resolved/
    KI-<NNNN>-<slug>.md  # the collapsed one-file summary
```

Use a sequential, zero-padded id (`KI-0001`, `KI-0002`, …) so it mirrors the ADR `NNNN-slug` scheme
and reads cleanly in code and commit messages. Date-keyed ids (`KI-<YYYY>-<NNN>`) are a fine
alternative when chronological sorting matters more than ADR symmetry — pick one and keep it.

## Lifecycle

```text
open → investigating → mitigated | masked → monitoring → resolved → collapsed
```

- **open / investigating** — reproduced and being root-caused; the test fails honestly.
- **mitigated** — a _permanent, legitimate_ guard exists (a readiness gate, a precondition check).
  Not a workaround; it stays after the bug is fixed.
- **masked** — a _temporary_ workaround (retry, wait-loop, skip) is in the tree. It must be
  revert-tracked (see below). `mitigated` and `masked` can co-exist on one case.
- **monitoring** — the upstream fix is believed deployed; watching for recurrence.
- **resolved** — fix **confirmed deployed** and any mask reverted. Triggers the collapse.

## Expand while hot, collapse when cold

While the issue is live, the directory grows: investigation log, escalation report, raw evidence, a
mask ledger. That sprawl is correct — it is a working lab notebook.

When the issue is resolved, **collapse** the directory into a single `resolved/KI-<NNNN>-<slug>.md`
summary and delete the hot directory. The summary keeps only four things:

1. **Issue** — the externally-observable symptom (which tests, which signature, which environment).
2. **Root cause** — the one-paragraph mechanism.
3. **Resolution** — what fixed it, with proof it is deployed (commit/date).
4. **How to recognize recurrence** — the exact signal + a one-line repro, so a future reader
   self-serves.

The raw trail is not duplicated; it stays in version-control history (record the path in a field
like `expanded_history`). This is the deliberate difference from ADRs, which are never deleted: a
known-issue dossier is a working set whose durable value is the distilled lesson. The freeze mirrors
RFC `Status: Final` and ADR `Superseded`.

## Linking code to a case

Three mechanisms, kept separate so they never blur:

- **Honest-fail** — a test that must not hide the bug stays failing, with a `# KI-<NNNN>` comment
  pointing at the case.
- **Expected failure** — when an expected-failure marker is wanted, use the test runner's native
  mechanism with the id in the reason string, and prefer the strict form so the suite goes red the
  moment the external system is fixed (e.g. `xfail(reason="KI-<NNNN>: …", strict=True)`). That
  forces the case closed.
- **Temporary mask** — carry the id at the code site
  (`# MASK KI-<NNNN>: … — revert at
  <condition>`) and route to the ledger.

Whatever the language, every suppression carries a tracker id and a revert condition — the
`// nolint // <reason+ticket>`, `// TODO(#<id>)`, known-bug-directive convention. A single grep of
`KI-<NNNN>` then ties together the directory, the registry row, the marker, the mask comment, and
the commit.

## Temporary masks must be revert-tracked

A mask never hides a defect silently. Its `mask.md` records **What is masked / Why / Where / Revert
Trigger / Revert Checklist**. The Revert Trigger is the exact condition — upstream fix _confirmed
deployed_ and stability proven — that ends the mask; a green run that still carries the mask does
not prove the underlying fix. This is the same discipline as a tracking file for perishable facts
(see [08 — Tracking and Revalidation](./08-tracking-and-revalidation.md)).

## The registry index

`docs/reference/known-issues/README.md` is the one file a future debugger greps: a status-only table
(`id | status | severity | affected tests | external system | upstream |
mask?`) plus a Resolved
table. Every other fact lives in the case directory (single source of truth). A machine-readable
`registry.yaml` alongside it lets a CI/pre-commit check assert that every `KI-<NNNN>` referenced in
the codebase resolves to a non-resolved row and that the registry agrees with the on-disk
directories — the same gate Chromium and large test suites apply to their expectation files.

## Sources

- Diataxis (reference = lookup, diagnostics, case studies): <https://diataxis.fr/>
- Test runner expected-failure / strict: <https://docs.pytest.org/en/stable/how-to/skipping.html>
- Known-failure expectation files with required bug ids:
  <https://chromium.googlesource.com/chromium/src/+/main/docs/testing/web_test_expectations.md>
- Postmortems as compact searchable learning artifacts:
  <https://sre.google/sre-book/postmortem-culture/> and <https://github.com/danluu/post-mortems>

## See also

- [01 — Diataxis Zones](./01-diataxis-zones.md) for reader-needs placement.
- [06 — Operational Docs](./06-operational-docs.md) for case studies and diagnostics in the
  reference zone.
- [08 — Tracking and Revalidation](./08-tracking-and-revalidation.md) for the mask ledger as a
  tracking artifact.
