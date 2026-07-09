# JavaScript — bootstrap a new project (spec/binding)

The JavaScript/TypeScript/Node binding of
[`tech/programming/project-bootstrap/`](../../../programming/project-bootstrap/README.md). It
applies the general once-per-project recipe with concrete Node tooling — `package.json` init and
project layout, module type and TypeScript setup, Node version pinning — and the JS quality gates
(prettier, eslint, a test runner, `tsc`, `npm audit`). It links to JavaScript implementation-kinds.

This binding **overlays** the general spine; it does not restate it. Read the general recipe first,
then the JavaScript specifics here.

## How to use this binding

1. Read the general [hub](../../../programming/project-bootstrap/README.md) and
   [general runbook](../../../programming/project-bootstrap/runbook.md) — the cross-language _what_.
2. Follow this [`runbook.md`](./runbook.md) for the JavaScript-specific overlay steps.
3. Jump to your implementation-kind file (e.g. [`cli-project.md`](./cli-project.md) or
   [`web-app.md`](./web-app.md)).
4. When ready to publish, hand off to
   [`../release-workflow-spec/`](../release-workflow-spec/README.md) — the later JavaScript/Node
   release phase.

## Index

| # | Chapter                                            | One-line hook                                                              |
| - | -------------------------------------------------- | -------------------------------------------------------------------------- |
| 0 | [Toolchain & layout](./00-toolchain-and-layout.md) | `npm init`/pnpm, `src/` layout, TypeScript + ESM, Node pinning (`.nvmrc`). |
| 1 | [Quality gates](./01-quality-gates.md)             | prettier, eslint, vitest, `tsc --noEmit`, `npm audit`, pre-commit wiring.  |

## Implementation kinds

- [`cli-project.md`](./cli-project.md) — Node CLI: the bootstrap-time ordering for the `bin` entry,
  argument parsing, and packaging.
- [`web-app.md`](./web-app.md) — front-end app: the bootstrap-time ordering for a Vite + framework
  single-page app.

`library-project.md` (an npm-published package) is a followup; add it when you bootstrap that kind.

## Related

- [General project-bootstrap](../../../programming/project-bootstrap/README.md) — the cross-language
  recipe this binding overlays.
- [`../release-workflow-spec/`](../release-workflow-spec/README.md) — the later JavaScript/Node
  release & publishing phase (Changesets, npm publish).
- [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md) — how a Nix
  devShell hosts the Node toolchain.
