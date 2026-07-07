# ADR-0001: Committed version is the source of truth; the tag mirrors it

## Context and Problem Statement

A project's version number can live in several places: a committed manifest/file (`Cargo.toml`,
`package.json`, `pyproject.toml`, `VERSION`), the release bot's own state, and the git tag. When
more than one is treated as authoritative they drift. A concrete failure: release-please with a bare
`VERSION` in `extra-files` silently no-ops (its generic updater only rewrites lines carrying an
`x-release-please-version` marker), so the tag advances while `VERSION` stays stale.

## Considered Options

- Committed version is the source of truth; the tag is derived to match it.
- Git tag is the source of truth; the committed version is generated at build time.
- Keep two committed copies and "keep them in sync".

## Decision Outcome

Chosen option: **committed version is the source of truth; the tag mirrors it** — one place authors
the number, everything else derives from it, and nothing is left uncommitted or generated. The
version has two roles: the committed version is the **authoring** source of truth (bumped in place
from Conventional Commits or changesets); the annotated `vX.Y.Z` tag is the **published record**,
cut to match. Corollary: pick a release tool that can deterministically bump _that_ committed file —
release-plz (Rust), Changesets (Node), git-cliff (Bash `VERSION`). A tool whose updater cannot bump
the file (release-please against a marker-less `VERSION`) is disqualified.

## Consequences

- Good: single authored source, no sync step, no silent drift; the tag is an immutable published
  marker distribution keys off.
- Good: tool choice per ecosystem is falsifiable — "can it bump the committed version file?".
- Bad: the "tag is the source of truth" phrasing is retired; docs must say "authoring vs published".

## Status

Accepted. Enacts the model in [release-workflow/01](../release-workflow/01-release-automation.md)
and the [bash release-workflow-spec](../../languages/bash/release-workflow-spec/README.md).
