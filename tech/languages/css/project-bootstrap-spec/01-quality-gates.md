# 01 — Quality gates

The CSS concretion of the general
[quality gates](../../../programming/project-bootstrap/04-quality-gates.md) chapter.

## Linter — `stylelint`

`stylelint` is the standard CSS/SCSS linter. Extend `stylelint-config-standard` (or
`stylelint-config-standard-scss` for Sass) as the baseline, and add `stylelint-order` if you enforce
declaration ordering. Enforce in CI with:

```bash
npx stylelint "src/**/*.{css,scss}"
```

Keep the config in `.stylelintrc.json`; add project rules (e.g. a BEM-aware
`selector-class-pattern`) on top of the shared config rather than restating it.

## Formatter — `prettier`

`prettier` is the non-negotiable formatter for CSS/SCSS; let it own whitespace and wrapping so
`stylelint` only enforces semantics. Disable stylistic overlap with `stylelint-config-prettier`, and
check formatting in CI:

```bash
npx prettier --check "src/**/*.{css,scss}"
```

## Visual regression (optional)

Stylesheet correctness is visual, so a snapshot layer catches what linters cannot. Options:

- **Playwright** (`toHaveScreenshot`) for rendered-component snapshots.
- **Storybook + Chromatic** or **BackstopJS** for design-system component galleries.

Adopt one only when a component library exists — see
[`stylesheet-library.md`](stylesheet-library.md). Bootstrap only requires lint + format to pass.

## Pre-commit wiring

Wire `stylelint` and `prettier --check` into the pre-commit hooks from the general
[04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md) so failures surface
locally in seconds. Expose them as task-runner recipes (`lint`, `fmt`) via `bootstrap-taskrunner`.

## Publish-readiness (later phase)

Publish-grade checks (package contents, `npm publish --dry-run`) belong to the distribution step of
[`stylesheet-library.md`](stylesheet-library.md), not the general gates. Bootstrap only guarantees
the stylesheets build, format, and lint clean.
