# 01 — Quality gates

The JavaScript/Node concretion of the general
[quality gates](../../../programming/project-bootstrap/04-quality-gates.md) and
[security baseline](../../../programming/project-bootstrap/06-security-baseline.md) chapters.

## Formatter — prettier

[prettier](https://prettier.io/) is the non-negotiable formatter. Add it as a dev dependency, keep a
minimal `.prettierrc` only if you deviate from defaults, and enforce in CI:

```bash
npx prettier --check .
```

## Linter — eslint

[eslint](https://eslint.org/) is the linter. Modern setups use a flat `eslint.config.js`; for
TypeScript pull in `typescript-eslint`. Run with warnings failing the build:

```bash
npx eslint . --max-warnings=0
```

Let prettier own formatting and eslint own correctness/style lints to avoid overlap (e.g. via
`eslint-config-prettier`).

## Tests — vitest / jest

Pick one test runner and wire an `npm test` script. [vitest](https://vitest.dev/) is the modern
default (fast, ESM- and TypeScript-native, Vite-aligned); [jest](https://jestjs.io/) remains a
solid, widely-used choice.

```bash
npm test          # runs the configured runner
```

## Typecheck — `tsc --noEmit`

For TypeScript projects, run the compiler in check-only mode as its own gate so type errors block
the build without emitting output:

```bash
npx tsc --noEmit
```

## Security — `npm audit`

`npm audit` is the Node tool behind the general security baseline: it fails on dependencies with
known advisories. Run it in CI so a vulnerable dependency cannot merge:

```bash
npm audit --audit-level=high
```

(Use `pnpm audit` on pnpm projects.)

## Pre-commit wiring

Wire `prettier --check`, `eslint`, and `tsc --noEmit` into the pre-commit hooks from the general
[04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md) so failures surface
locally in seconds. A `lint-staged` setup can scope prettier/eslint to changed files for speed.

## Publish-readiness (later phase)

Publish-grade checks (`npm publish --dry-run`, `exports`/`files` correctness, changelog) belong to
the release phase, not bootstrap — see
[`../release-workflow-spec/`](../release-workflow-spec/README.md). Bootstrap only guarantees the
project formats, lints, typechecks, tests, and audits clean.
