# 04 — Quality gates

The checks that keep the codebase consistent and catch defects before they land. Each is
language-agnostic as a _contract_; the concrete tool is named in the language binding.

## Formatter

A single, non-negotiable code formatter removes style debates and keeps diffs minimal. Run it in
`--check` mode in CI so unformatted code cannot merge. The formatter is authoritative for code
style; `.editorconfig` (chapter [03](./03-local-dev-environment.md)) covers non-code files.

## Linter

A linter catches likely bugs and anti-patterns the formatter does not. Configure it to **deny**, not
just warn, on the lints you care about, and run it in CI. The language binding picks the tool (e.g.
`clippy` for Rust) and the deny set.

## Pre-commit hooks

Pre-commit hooks run the formatter, linter, and cheap checks locally before a commit is created, so
failures are caught in seconds rather than in CI minutes later. Keep the hook set fast — expensive
checks belong in CI. Use a framework (e.g. [pre-commit](https://pre-commit.com/)) so hooks are
declarative and shared.

## Task runner

A task runner gives one entry point for common recipes — `fmt`, `lint`, `test`, `build` — so
contributors and CI invoke the same commands. A `justfile` is a good default; an existing `Makefile`
can be augmented in place. This is the single command surface the other gates hang off.

## Automation

`bootstrap-precommit` installs the hook framework and a starter hook set; `bootstrap-taskrunner`
scaffolds a `justfile` (or augments a `Makefile`). The gates above are the SoT; see
[07 — Automation with cog](./07-automation-with-cog.md).
