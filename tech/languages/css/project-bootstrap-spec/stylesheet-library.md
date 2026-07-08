# CSS stylesheet library — implementation-kind additions

What a **reusable stylesheet / design-system / component-library** package adds on top of the
general recipe and the CSS binding: a tokens/theming seam, a consumable build, and npm distribution.
This file owns only the **bootstrap-time ordering**; deeper authoring patterns live in the broader
[CSS reference notes](../).

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the CSS
  [binding runbook](runbook.md) are done — a buildable, gated package exists.

## Add these, in this order

1. **Design tokens.** Define tokens once as CSS custom properties (`--color-*`, `--space-*`,
   `--font-*`) and/or Sass variables, in the settings layer. →
   [00 — Toolchain & layout](00-toolchain-and-layout.md). Consider **Style Dictionary** if tokens
   must be emitted to multiple targets (CSS, JS, JSON).

2. **Theming seam.** Expose theming via custom-property overrides — a base `:root` theme plus
   `[data-theme="dark"]` (or a `.theme-*` class) that reassigns the same token names. Custom
   properties (not Sass vars) so consumers can retheme at runtime without a rebuild.

3. **Component layer.** Author BEM components on top of the tokens so every color/space value
   dereferences a token, never a literal.

4. **Build the distributable.** Emit compiled, prefixed CSS to `dist/` (Vite library mode, or
   `sass`/`postcss-cli`). Ship both the compiled `.css` and, if consumers use Sass, the source
   partials for `@use`.

5. **Configure the npm package.** In `package.json` set `main`/`style` to the compiled CSS,
   `exports` for the entry points, `sideEffects: ["*.css"]`, and `files`/`.npmignore` so only
   `dist/` (plus source partials) ship. Validate with `npm publish --dry-run`.

## Distribution (later phase)

Actually publishing to the npm registry (versioning, provenance, release automation) is
release-phase work and is not owned here. Bootstrap stops at a buildable, gated, `--dry-run`-clean
package.

## Other kinds

`app-embedded-stylesheet.md` — stylesheets bundled into an application build rather than published —
is a followup; add it when you bootstrap that kind.
