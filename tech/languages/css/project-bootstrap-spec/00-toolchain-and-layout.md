# 00 — Toolchain & layout

The CSS ecosystem choices for a fresh stylesheet project: how to initialize the package, how to lay
out and name the stylesheets, which processing pipeline to run, and how the Nix devShell hosts the
Node tooling.

## Package manager

Initialize with `npm init` or `pnpm init` to create `package.json`. Prefer **pnpm** for its
content-addressed store and strict, non-flat `node_modules`; **npm** is the zero-install default.
Pin the choice with the `packageManager` field (e.g. `"packageManager": "pnpm@9.x"`) so local and CI
agree.

## Node tooling in the Nix devShell

The general
[local dev environment](../../../programming/project-bootstrap/03-local-dev-environment.md) chapter
owns the Nix devShell; this binding only names what it must provide: a pinned `nodejs` and the
package manager (`pnpm` / `nodePackages.pnpm`). Add them to the flake's `buildInputs` so
`direnv`/`nix develop` yields the same Node and pnpm locally and in CI. `bootstrap-nix` scaffolds
the flake; add the Node inputs to it. Do not restate the general devShell setup here.

## Stylesheet architecture & naming

- **Layer model.** Order stylesheets by specificity/reach using **ITCSS** (Settings → Tools →
  Generic → Elements → Objects → Components → Utilities). This keeps the cascade predictable and
  specificity monotonic.
- **Naming convention.** Use **BEM** (`block__element--modifier`) for component classes so selectors
  stay flat and low-specificity.
- **Design tokens.** Reserve a tokens/variables layer at the top: native CSS custom properties
  (`--color-*`, `--space-*`) and/or Sass variables for build-time values. Tokens are the theming
  seam — see [`stylesheet-library.md`](./stylesheet-library.md).

## Processing pipeline

Pick one authoring/transform stack:

- **PostCSS** — plugin pipeline over standard CSS. Baseline plugins: `autoprefixer` (vendor
  prefixes) and `postcss-preset-env` (future CSS, polyfilled to a `browserslist` target). Prefer
  this when authoring near-standard CSS.
- **Sass (Dart Sass)** — `.scss` with nesting, mixins, `@use`/`@forward` modules. Prefer this when
  you need build-time logic and partials.

Both can coexist (Sass compiled, then PostCSS post-processes). Define a `browserslist` in
`package.json` — it is the single source of truth both `autoprefixer` and `postcss-preset-env` read.

## Bundler / build

Use **Vite** for a fast dev server, `@import`/`@use` resolution, and asset handling; its build step
emits the distributable CSS. For a pure library with no app shell, `postcss-cli` or the Sass CLI
(`sass src:dist`) is a lighter alternative. The bundler choice belongs to the implementation kind —
see [`stylesheet-library.md`](./stylesheet-library.md).

## Layout

A minimal starting tree:

```text
src/
  settings/    # tokens: custom properties, Sass vars
  tools/       # mixins, functions (Sass)
  generic/     # resets, normalize
  elements/    # bare element styles
  objects/     # layout primitives
  components/  # BEM components
  utilities/   # single-purpose helpers
  index.css    # or index.scss — the entry that imports the layers in ITCSS order
```

Bootstrap owns the _ordering_ (get a buildable entry stylesheet first); deeper authoring patterns
live in the broader [CSS reference notes](../).

## Automation

`bootstrap-nix` provides the Node-hosting devShell; `bootstrap-taskrunner` wires the build/lint
recipes. The steps above are the SoT — see
[general 07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md).
