# ADR-0003: README.md defines domain semantics, not disk structure

## Context and Problem Statement

`README.md` files serve as the human-facing index for a directory. A tempting way to write one is to
mirror the filesystem: an ASCII directory tree, or an exhaustive bullet list of every child file and
subdirectory. But the filesystem is **mutable and drifts fast** — files are added, renamed, and
deleted constantly, and a README that replicates the layout goes stale the moment the tree changes,
silently misdescribing what is actually on disk. The directory listing already _is_ the source of
truth for "what exists"; duplicating it into prose creates a second, lower-fidelity copy that must
be hand-maintained.

Separately, `AGENTS.md` digests deliberately _do_ map sources (their `Source Map` is a file-level
index) — that is their designed job, and it is regenerated from the sources, so it is not subject to
this problem.

## Considered Options

- README defines the area's organization, semantics, and domain; the filesystem stays the SoT for
  what exists. Links to specific files/dirs are allowed when justified by that semantic role.
- README mirrors the directory tree / enumerates every file (structural index).
- README contains no file or directory references at all (pure prose).

## Decision Outcome

Chosen option: **README.md must define its area's organization, semantics, and domain — not
replicate disk state.**

- **Required:** a README states _what kind of content the directory reserves_ ("at dir X we keep
  this kind of thing"), how the area is organized, and the meaning of its parts.
- **Prohibited:** ASCII directory trees and exhaustive `ls`-style enumerations of files/subdirs that
  merely mirror the filesystem and drift when it changes.
- **Allowed when justified:** links to specific files or directories that carry organizational or
  semantic meaning — a curated pointer to a landmark entry point, not a mechanical listing. The
  test: does the link exist because this README is responsible for defining that part of the tree's
  role, or is it just echoing what `ls` would show?
- **Exempt — auto-generated ToC:** a table-of-contents block delimited by generator markers
  (`<!--TOC-->` … `<!--TOC-->`, `<!-- toc -->` … `<!-- tocstop -->`) lists the page's own headings
  and is tool-produced, so it is allowed and left to the generator (not hand-trimmed). This covers
  in-page heading ToCs only, not hand-written sibling-file enumerations.
- **Exempt:** `AGENTS.md` digests, whose job is to summarize and map sources (including a file-level
  `Source Map`).

## Consequences

- Good: READMEs stop going stale on every add/rename/delete; the filesystem remains the single SoT
  for structure, and the README carries the durable semantic meaning the filesystem can't.
- Good: navigation by _meaning_ (domain reservations, curated landmarks) survives refactors that
  move files around.
- Bad: existing READMEs that carry trees or exhaustive listings must be rewritten; the "justified
  link vs mechanical listing" line requires per-README judgment rather than a mechanical rule.

## Status

Accepted. Operative rule lives in [CLAUDE.md](../../../CLAUDE.md) ("README Content Rule"), which
also reconciles the older "README = index file" wording to mean a _semantic_ index. Enforced across
the repository as part of the SoT sweep.
