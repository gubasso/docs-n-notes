# 08 — Tracking and Revalidation

Documentation often holds perishable facts: benchmarks, prices, model and tool rosters, external API
shapes, security advisories, and similar claims that drift silently. A _tracking file_ is the
discipline that keeps those facts honest by recording what must be re-checked, how often, and how.

## Tracking files

A tracking file is a machine-readable registry with one entry per perishable artifact. It does not
replace the artifact. It records enough metadata for a human or agent to know when the artifact
needs attention and how to revalidate it without rediscovering the process from scratch.

Each entry should record:

- `path`: the artifact being tracked.
- `last_checked`: the date the artifact was last revalidated.
- `cadence`: how often the artifact should be re-verified.
- `why`: why the fact perishes.
- `revalidate`: the procedure or authoritative source to use.
- `dependents`: downstream files or workflows that rely on the artifact.

Keep the registry descriptive. It should answer "what is stale?" and "how do I check it?" It should
not become a second copy of the fact it tracks.

## When to track

Track facts that drift from external reality. Good candidates include benchmark results, vendor
pricing, model and tool availability, external API shapes, security advisories, dependency lifecycle
dates, and platform support matrices. These facts may be correct when written and wrong a month
later without any local code change.

Do not track stable conceptual docs just because they are old. Durable rationale belongs in ADRs.
Conceptual background belongs in explanation. A decision is superseded or rejected; it does not
expire on a timer. Tracking is for facts whose truth depends on a source outside the document.

## Source-of-truth relationship

The tracked artifact remains the source of truth for its fact. The tracking file is not the fact's
owner; it is the mechanism that keeps the owner from going stale. If the registry and the artifact
disagree, update the artifact or the registry so there is still one owner. See
[04 — Single Source of Truth](04-single-source-of-truth.md).

## Revalidation workflow

Revalidation should be boring and explicit. The tracking file tells the maintainer which artifacts
are due. The maintainer or agent then verifies the current external reality and updates the owning
artifact if the fact changed.

Use this loop:

1. Scan the tracking file.
1. Pick overdue entries.
1. Re-research from authoritative sources.
1. Update the artifact and its own "data collected" or verified date.
1. Bump the entry's `last_checked`.

If the drift is uncertain, surface it. Do not silently overwrite a claim you could not re-verify.
Open a follow-up, leave a clear note, or ask for review when the source is ambiguous, unavailable,
or contradicted by another authoritative source.

## Agent workflow

The primary audience is coding agents sweeping a repo during normal work. Agents are good at running
deterministic scans, finding overdue entries, and reporting the files that need attention. They are
also vulnerable to stale authoritative-looking docs. A registry gives them a specific path to
inspect instead of asking them to infer freshness from filenames or timestamps.

The scan and overdue computation belong in deterministic tooling. Revalidation is judgment: fetch
the current source, compare it with the artifact, decide whether the claim changed, and report
uncertainty. This split keeps repeated mechanics out of prose while still requiring the agent or
human to own the interpretation. See [07 — AI Agent Considerations](07-ai-agent-considerations.md)
for the broader retrieval and stale-docs risks.

## Worked example

For example, cog's `repo-update-tracking` plan will build a
`docs/reference/maintenance-tracking.yaml` registry consumed by a deterministic `cog tracking-scan`
command. The command reports overdue entries; it does not decide what the new truth is. The
revalidation step still belongs to the agent or human doing the maintenance pass.

That boundary is the pattern. Overdue computation is tooling. Revalidation is judgment. The tool can
say "this model roster is due"; the maintainer must check the authoritative sources and update the
owning reference if the roster changed.

## Minimal schema

An adopting project owns the exact field names. Start with the smallest schema that supports a scan,
a revalidation pass, and downstream impact review.

```yaml
# docs/reference/<your>-tracking.yaml
tracked:
  - path: docs/reference/model-pricing.md
    last_checked: 2026-06-20
    cadence: 30d            # re-verify at least this often
    why: provider prices change without notice
    revalidate: re-fetch from the provider's official pricing page
    dependents:
      - docs/guides/cost-estimation.md
```

## See also

A **temporary-workaround revert ledger** is a tracking artifact of the same shape: it records the
exact condition (an upstream fix confirmed deployed) under which the workaround must be removed.
That ledger lives with its case in the known-issues library, not here — see
[09 — Known Issues](09-known-issues.md).
