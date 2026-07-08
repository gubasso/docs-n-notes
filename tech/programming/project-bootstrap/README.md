# Project Bootstrap — General Recipe

Language-agnostic principles and the ordered, once-per-project setup that every new repository needs
_before_ feature work begins: create the repo, lay the foundations (ignore/license/readme), seed
governance docs, wire the local dev environment and quality gates, stand up CI and branch
protection, and set a security baseline. Use this tree as the source of truth for _what_ a new
project must have, and the language-specific `project-bootstrap-spec/` bindings for the concrete
tooling.

Bootstrap is deliberately the **earliest** phase — repo → foundations → gates — and is distinct from
and precedes the later [release workflow](../release-workflow/README.md) phase. As with releases,
the durable value here is the ordered checklist and the one-owner-per-fact discipline, not any
single command; automation ([cog](https://github.com/gubasso/cog)) accelerates the _how_ but this
tree owns the _what_.

## The three-layer model

A new project is set up by descending three layers, each owning a disjoint set of facts:

```text
General            tech/programming/project-bootstrap/          # any project, any language
   │                 repo, license, gitignore, governance,
   │                 dev env, quality gates, CI, security
   ▼
Language           tech/languages/<lang>/project-bootstrap-spec/ # ecosystem choices
   │                 e.g. Rust: cargo layout, toolchain, clippy/deny
   ▼
Implementation     …/project-bootstrap-spec/<kind>.md            # shape-specific additions
                     e.g. rust CLI: arg-parsing, logging, config
```

Ownership:

- **General** owns universal, cross-language steps. This is the spine.
- **Language** owns ecosystem choices; it _overlays_ the general spine and never restates it.
- **Implementation-kind** owns shape-specific additions (CLI, library, service); it delegates the
  detailed _how_ to any existing spec and owns only the bootstrap-time ordering.

Routing flow the user follows:

```text
root README  →  this hub  →  runbook.md  →  language project-bootstrap-spec/README.md
                                          →  language runbook.md  →  <kind>.md
```

## How to use this tree

1. Read [`runbook.md`](runbook.md) first — the ordered, once-per-project spine of _what_ to do and
   _in what order_. Every other page explains the _why_ behind one of its steps.
1. Read the chapter behind any step you need to understand (the [Index](#index) below).
1. Jump to your language binding (e.g.
   [Rust](../../languages/rust/project-bootstrap-spec/README.md)) for the ecosystem specifics, then
   to your implementation-kind file.
1. When the project is scaffolded and gated, move on to the
   [release workflow](../release-workflow/README.md) — the phase that follows bootstrap.

## Index

| # | Chapter                                                  | One-line hook                                                                        |
| - | -------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| 0 | [Bootstrap model](00-bootstrap-model.md)                 | What "bootstrap" is: the once-per-project phase, the three-layer ownership model.    |
| 1 | [Repository foundation](01-repository-foundation.md)     | `.gitignore`, `LICENSE` (SPDX), `README` skeleton — the root files every repo needs. |
| 2 | [Governance & docs](02-governance-and-docs.md)           | `CLAUDE.md`, the `AGENTS.md` convention, ADR scaffold, README-as-index.              |
| 3 | [Local dev environment](03-local-dev-environment.md)     | Nix devShell + `.envrc`, `.editorconfig` — reproducible, cross-editor baseline.      |
| 4 | [Quality gates](04-quality-gates.md)                     | Formatter, linter, pre-commit, task runner — fail fast, one command.                 |
| 5 | [CI & release-readiness](05-ci-and-release-readiness.md) | First CI workflow, branch protection, hand-off to the release phase.                 |
| 6 | [Security baseline](06-security-baseline.md)             | Secrets hygiene, dependency audit, OpenSSF Scorecard.                                |
| 7 | [Automation with cog](07-automation-with-cog.md)         | The SoT-vs-cog contract and the domain→helper map.                                   |

## Language-specific bindings

These bindings apply the general recipe with a concrete toolchain. They assume you've read the
general runbook, and each links back to it.

- [`tech/languages/rust/project-bootstrap-spec/`](../../languages/rust/project-bootstrap-spec/) —
  the **reference binding**: cargo layout + toolchain pinning, rustfmt/clippy/deny quality gates,
  and a Rust CLI implementation-kind. Other languages follow this shape.

Other-language bindings (python, bash, go, …) are followups; add a `project-bootstrap-spec/` under
the language directory when you bootstrap a project in it.

## Related (later phases & platform setup)

- [Release workflow](../release-workflow/README.md) — the **next** phase, once the project is
  scaffolded and gated.
- [Branch protection & CI-driven release](../../tools/git/branch-protection/) — the platform
  runbooks and rulesets the bootstrap runbook invokes (linked, never copied here).
- [Single source of truth](../docs-design/04-single-source-of-truth.md) and
  [Diátaxis zones](../docs-design/01-diataxis-zones.md) — the docs-design standards this shelf
  obeys: one owner per fact, runbooks are how-to guides.

## TL;DR (the irreducible defaults)

- **One owner per fact.** Each step lives in exactly one place; other layers link, never restate.
- **The runbook is the spine.** [`runbook.md`](runbook.md) is the ordered _what_; chapters are the
  _why_; language and kind bindings are _overlays_.
- **Tool docs are linked, not copied.** Branch protection and release setup keep their own homes.
- **cog automates _how_; this tree owns _what_.** If they disagree, fix the runbook first, then cog.
- **Bootstrap precedes release.** Get the project scaffolded and gated here; publish over in
  [release-workflow](../release-workflow/README.md).
