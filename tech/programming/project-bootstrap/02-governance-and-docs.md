# 02 — Governance & docs

The documents that tell humans and agents how to work in the repo, and how decisions are recorded.
Seed these early so conventions are set before the code grows around them.

## `CLAUDE.md` (agent instructions)

`CLAUDE.md` carries repository-specific instructions for LLM agents: scope, conventions, what is
canonical, and any hard rules. Author it for **self-containment** — an agent should be able to work
correctly from the repo alone, without external context. This repo's own `CLAUDE.md` is a worked
reference.

## The `AGENTS.md` convention

`AGENTS.md` is a generated **digest** for agent runtime context — a summary of existing source
notes, never a place for novel guidance. It has become a cross-tool standard for agent-oriented repo
context (Linux-Foundation-stewarded; see the
[AGENTS.md guide](https://www.morphllm.com/agents-md-guide)).

When you adopt it, fix the schema up front: required frontmatter (`digest-of`, `last-synced`,
`source-files`, `token-estimate`) and stable body headings, regenerated from sources rather than
hand-edited. Because it is generated, it is the _only_ machine-authored artifact the repo trusts;
everything else is human-authored.

## ADR scaffold

Record consequential decisions as Architecture Decision Records so the _why_ survives. Use a
**MADR-minimal** template ([MADR](https://github.com/adr/madr)) under `docs/decisions/` (or the
repo's chosen location). A good seed is a self-containment ADR that states the docs-as-SoT principle
itself.

## README-as-index discipline

Every directory's `README.md` is its index — it routes to the files in and under it, and does not
duplicate their content. This keeps navigation deterministic and prevents the drift that
[single source of truth](../docs-design/04-single-source-of-truth.md) warns against. This shelf's
[hub README](README.md) is an example.

## Automation

`bootstrap-governance` seeds `CLAUDE.md`, an `AGENTS.md`, and an ADR scaffold (MADR-minimal plus a
self-containment ADR). The conventions above are the SoT; see
[07 — Automation with cog](07-automation-with-cog.md).
