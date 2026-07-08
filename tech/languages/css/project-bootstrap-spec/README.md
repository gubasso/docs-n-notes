# CSS — bootstrap a new project (spec/binding)

The CSS binding of
[`tech/programming/project-bootstrap/`](../../../programming/project-bootstrap/README.md). It
applies the general once-per-project recipe with concrete front-end tooling — stylesheet
architecture and naming, a PostCSS/Sass pipeline, the npm/pnpm package manager hosted in a Nix
devShell, and the stylelint/prettier quality gates — and links to CSS implementation-kinds.

This binding **overlays** the general spine; it does not restate it. Read the general recipe first,
then the CSS specifics here.

## How to use this binding

1. Read the general [hub](../../../programming/project-bootstrap/README.md) and
   [general runbook](../../../programming/project-bootstrap/runbook.md) — the cross-language _what_.
1. Follow this [`runbook.md`](runbook.md) for the CSS-specific overlay steps.
1. Jump to your implementation-kind file (e.g. [`stylesheet-library.md`](stylesheet-library.md)).

## Index

| # | Chapter                                          | One-line hook                                                              |
| - | ------------------------------------------------ | -------------------------------------------------------------------------- |
| 0 | [Toolchain & layout](00-toolchain-and-layout.md) | ITCSS/BEM layout, tokens, PostCSS/Sass, npm/pnpm + Vite in a Nix devShell. |
| 1 | [Quality gates](01-quality-gates.md)             | `stylelint`, `prettier`, visual regression, pre-commit wiring.             |

## Implementation kinds

- [`stylesheet-library.md`](stylesheet-library.md) — a reusable stylesheet / design-system /
  component-library package: design tokens, theming, and npm distribution.

`app-embedded-stylesheet.md` (stylesheets bundled into an app rather than published) is a followup;
add it when you bootstrap that kind.

## Related

- [General project-bootstrap](../../../programming/project-bootstrap/README.md) — the cross-language
  recipe this binding overlays.
- [`../`](../) — the broader CSS/Less/Sass reference notes.
- [`../../../platforms/webdev/css/`](../../../platforms/webdev/css/) — browser/platform-specific CSS
  notes.
