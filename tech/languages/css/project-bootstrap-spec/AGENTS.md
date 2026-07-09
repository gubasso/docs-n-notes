---
digest-of: tech/languages/css/project-bootstrap-spec
last-synced: 2026-07-09
source-files:
  - README.md
  - runbook.md
  - 00-toolchain-and-layout.md
  - 01-quality-gates.md
  - stylesheet-library.md
token-estimate: 780
---

# AGENTS

## Scope

CSS binding of the general `tech/programming/project-bootstrap/` shelf: the once-per-project
front-end setup that takes an empty repo to a scaffolded, gated stylesheet project ready for
authoring. It **overlays** the general spine (repo, license, governance, dev env, CI, security) and
never restates it; it owns only the CSS ecosystem choices — stylesheet architecture/naming, the
processing pipeline, the npm/pnpm package manager in a Nix devShell, the stylelint/prettier gates —
plus the one implementation-kind ordering (stylesheet-library). Publishing to npm is out of scope —
it hands off to the release phase.

## Key Points

- **Package manager:** `npm init` or `pnpm init` creates `package.json`. Prefer **pnpm**
  (content-addressed store, strict non-flat `node_modules`); **npm** is the zero-install default.
  Pin with the `packageManager` field (e.g. `"pnpm@9.x"`) so local and CI agree.
- **Node in the devShell:** the general `03-local-dev-environment.md` owns the Nix devShell; this
  binding only names what it must provide — a pinned `nodejs` and the package manager
  (`pnpm`/`nodePackages.pnpm`) in the flake's `buildInputs` so `direnv`/`nix develop` yields one
  toolchain locally and in CI. `bootstrap-nix` scaffolds the flake; add the Node inputs to it.
- **Architecture & naming:** **ITCSS** layer model (Settings → Tools → Generic → Elements → Objects
  → Components → Utilities) for predictable, monotonic specificity; **BEM**
  (`block__element--modifier`) for flat, low-specificity component classes; a tokens/variables layer
  reserved at the top (CSS custom properties `--color-*`/`--space-*` and/or Sass variables) as the
  theming seam.
- **Processing pipeline:** pick **PostCSS** (baseline `autoprefixer` + `postcss-preset-env`) for
  near-standard CSS, or **Sass (Dart Sass)** (`.scss`, nesting, mixins, `@use`/`@forward`) for
  build-time logic. Both can coexist. A `browserslist` in `package.json` is the single source of
  truth both plugins read.
- **Bundler:** **Vite** for dev server, `@import`/`@use` resolution, and the build that emits
  distributable CSS; `postcss-cli` or the Sass CLI (`sass src:dist`) is a lighter alternative for a
  pure library. Bootstrap owns the _ordering_ (get a buildable entry stylesheet first).
- **Quality gates:** `stylelint` (extend `stylelint-config-standard` / `-standard-scss`, add
  `stylelint-order`, config in `.stylelintrc.json`) for semantics; `prettier` (non-negotiable
  formatter, disable overlap with `stylelint-config-prettier`) for whitespace/wrapping. Optional
  visual regression (Playwright `toHaveScreenshot`, or Storybook+Chromatic/BackstopJS) only once a
  component library exists. Wire `stylelint` + `prettier --check` into pre-commit; expose `lint`/
  `fmt` recipes via `bootstrap-taskrunner`. Bootstrap only requires lint + format to pass.
- **stylesheet-library kind:** a reusable design-system / component-library package adds, in order —
  design tokens (custom properties and/or Sass vars in the settings layer; **Style Dictionary** for
  multi-target emit); a theming seam via custom-property overrides (base `:root` plus
  `[data-theme="dark"]`/`.theme-*` reassigning the same token names, so consumers retheme at runtime
  without a rebuild); BEM components dereferencing tokens (never literals); a `dist/` build (Vite
  library mode or `sass`/`postcss-cli`, shipping compiled `.css` plus Sass partials); npm packaging
  (`main`/`style`, `exports`, `sideEffects: ["*.css"]`, `files`/`.npmignore`), validated with
  `npm publish --dry-run`. Actual npm publishing is release-phase, not owned here.
- **Automation:** `bootstrap-nix` (Node devShell), `bootstrap-precommit` (hooks),
  `bootstrap-taskrunner` (build/lint recipes), `bootstrap-ci`. The runbook steps are the SoT — see
  general `07-automation-with-cog.md`.

## Source Map

| Topic                                                                     | File                         |
| ------------------------------------------------------------------------- | ---------------------------- |
| Binding index, how-to-use, implementation-kinds list, related             | `README.md`                  |
| Ordered CSS overlay steps (the _what_/_in what order_)                    | `runbook.md`                 |
| pnpm/npm, Node-in-devShell, ITCSS/BEM/tokens, PostCSS/Sass, Vite, layout  | `00-toolchain-and-layout.md` |
| `stylelint` / `prettier` / visual regression + pre-commit wiring          | `01-quality-gates.md`        |
| Design-system/library ordering (tokens, theming, dist build, npm package) | `stylesheet-library.md`      |

## Maintenance Notes

- General spine: `../../../programming/project-bootstrap/`. Broader CSS/Less/Sass reference notes:
  `../`. Browser/platform CSS notes: `../../../platforms/webdev/css/`.
- `app-embedded-stylesheet.md` (stylesheets bundled into an app rather than published) is a declared
  followup kind; add it (and refresh `source-files`) when it lands.
- Front-end tooling defaults (`pnpm`, `postcss-preset-env`, Vite, stylelint configs) move fast —
  re-verify the default-tool choices against upstream when regenerating.
- No conflicts among the current source files.
  </content>
  </invoke>
