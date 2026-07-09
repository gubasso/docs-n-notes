# ADR-0002: Cookbooks may duplicate spec content; they are exempt from DRY

## Context and Problem Statement

The repository is a single source of truth (SoT): every technical fact should live in exactly one
canonical place, and other pages should link to it rather than restate it. That discipline keeps the
deep-dive specs from drifting apart.

But a **cookbook** — a lean, TLDR, top-to-bottom runbook for a concrete task (e.g. "ship a Rust
project") — is only useful if it is _self-contained_: a reader executing it wants every command and
config in one file, in order, not a scavenger hunt across thirty linked pages. Making a cookbook
strictly DRY (link-only, no inlined snippets) destroys the exact property that makes it worth
having. Without an explicit rule, a later SoT/de-duplication pass (human or agent) will "fix" the
cookbook by stripping its inlined snippets and gut its purpose.

## Considered Options

- Cookbooks are exempt from DRY: they may inline snippets from canonical specs, provided they
  footnote the source and never become the SoT themselves.
- No cookbooks: force everything through the linked deep-dive specs only.
- Cookbooks allowed but still DRY: link-only, no inlined snippets.

## Decision Outcome

Chosen option: **cookbooks are the one sanctioned exception to DRY.** A cookbook MAY
inline-duplicate content from the canonical specs to stay self-contained, subject to three
guardrails:

1. **Footnote the canon.** Every inlined snippet links to the spec that owns it, so a reader can
   reach the _why_ and the authoritative version.
2. **Never the SoT.** A cookbook is never the source of truth for any decision or value; if a
   cookbook snippet disagrees with its footnoted spec, the spec wins.
3. **Marked and recognizable.** A cookbook lives in a `cookbook/` directory and/or opens with a
   TLDR/cookbook header, so tooling and reviewers can identify an exempt file at a glance.

Consequently the DRY / de-duplication discipline **does not apply** to cookbook files, and no sweep
should collapse their inlined snippets to links.

## Consequences

- Good: hands-on runbooks stay self-contained and fast to execute, without eroding the SoT of the
  specs they distill.
- Good: the exemption is explicit, so automated or manual SoT passes skip cookbooks by rule rather
  than by accident.
- Bad: a cookbook can fall out of sync with its specs. Mitigation: footnotes make the canonical
  source one click away, and the cookbook's `AGENTS.md` maintenance note flags re-checking sections
  when the footnoted specs change materially.

## Status

Accepted. Operative rule lives in [CLAUDE.md](../../../CLAUDE.md) ("Cookbook Exception to SoT").
First instance: the [Rust ship-it cookbook](../../languages/rust/cookbook/README.md).
