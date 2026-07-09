---
digest-of: tech/languages/javascript/project-bootstrap-spec
last-synced: 2026-07-09
source-files:
  - README.md
  - runbook.md
  - 00-toolchain-and-layout.md
  - 01-quality-gates.md
  - cli-project.md
  - web-app.md
token-estimate: 850
---

# AGENTS

## Scope

JavaScript/TypeScript/Node binding of the general `tech/programming/project-bootstrap/` shelf: the
once-per-project Node setup that takes an empty repo to a scaffolded, gated project ready for
feature work. It **overlays** the general spine (repo, license, governance, dev env, CI, security)
and never restates it; it owns only the Node ecosystem choices and the two implementation-kind
orderings (CLI, web-app). Publishing/deploy is out of scope — it hands off to
`../release-workflow-spec/`.

## Key Points

- **Package manager:** `npm` is the mainstream default (ships with Node, no extra install). Prefer
  `pnpm` for disk efficiency, strict resolution, or monorepos. Commit the lockfile
  (`package-lock.json` or `pnpm-lock.yaml`); do not mix the two in one repo.
- **Init:** `npm init -y` (or `pnpm init`). Set only `name`, `version`, `description`, and
  `"type": "module"` (ESM); add `"private": true` unless publishing. Publish-grade metadata
  (`files`, `exports`, `publishConfig`, `repository`, `keywords`) is deferred to the release phase —
  do not duplicate that gate here.
- **Module type:** ESM via `"type": "module"` (`import`/`export`); `.cjs` for the rare CommonJS
  file. Aligns with TypeScript and Vite.
- **Layout:** code under `src/`, emitted output under `dist/` (git-ignored).
- **TypeScript:** install `typescript` as a dev dep, `tsc --init` a `tsconfig.json` pointed at
  `src/` → `dist/` with modern targets (`ES2022`, `NodeNext` module/resolution) and `strict: true`
  as the baseline.
- **Node pin:** `.nvmrc` (e.g. `20`) for nvm/fnm (or a Volta block), plus an `engines.node` range so
  a wrong Node is caught on install. A Nix devShell provisions that same Node so local and CI share
  one toolchain (`nix/02-per-project-devshell`). No JS-specific scaffold skill — `npm init` /
  `tsc --init` are the SoT; general foundations use the `bootstrap-*` skills.
- **Quality gates:** `prettier` (format, `--check .`), `eslint` (lint, flat `eslint.config.js`,
  `typescript-eslint`, `--max-warnings=0`, `eslint-config-prettier` to avoid overlap), a test runner
  (`vitest` modern default, `jest` alternative) wired to `npm test`, `tsc --noEmit` (typecheck), and
  `npm audit`/`pnpm audit` (`--audit-level=high`, the security baseline). Wire prettier/eslint/tsc
  into pre-commit; `lint-staged` can scope to changed files.
- **CLI kind:** `bin` field mapping command → script (e.g. `./dist/cli.js`) with a
  `#!/usr/bin/env node` shebang; arg parsing via `util.parseArgs` (simple), `commander`/`yargs`, or
  `oclif`; non-zero exit + readable errors, no silent unhandled rejections; stdout vs stderr split
  with `--verbose`/`--quiet`; optional config precedence file + env + flags. Keep the `tsc` build
  and `bin` path in sync. Binary distribution (`pkg`, Node SEA) is release-phase.
- **Web-app kind:** scaffold with `Vite` (`npm create vite@latest -- --template react-ts`, also
  `vue-ts`/`svelte-ts`/`vanilla-ts`); fold generated scripts and framework eslint plugins into the
  existing gates (vitest is Vite-native and reuses the config) rather than duplicating; ensure
  `dev`/`build`/`preview` scripts and git-ignored `dist/`; follow sibling framework review guides.
  Deployment is release-phase.

## Source Map

| Topic                                                           | File                         |
| --------------------------------------------------------------- | ---------------------------- |
| Binding index, how-to-use, implementation-kinds list, related   | `README.md`                  |
| Ordered JS overlay steps (the _what_/_in what order_)           | `runbook.md`                 |
| npm/pnpm, `package.json` init, ESM, `src/` layout, TS, Node pin | `00-toolchain-and-layout.md` |
| prettier / eslint / vitest·jest / `tsc --noEmit` / `npm audit`  | `01-quality-gates.md`        |
| Node CLI ordering (`bin` + shebang, arg parsing, exit, logging) | `cli-project.md`             |
| Web-app ordering (Vite scaffold, gate reconciliation, scripts)  | `web-app.md`                 |

## Maintenance Notes

- General spine: `../../../programming/project-bootstrap/`. Release handoff (Changesets, npm
  publish): `../release-workflow-spec/`. Nix devShell host:
  `../../../tools/nix/02-per-project-devshell.md`.
- `library-project.md` (an npm-published package) is a declared followup kind; add it (and refresh
  `source-files`) when it lands.
- The Node tooling landscape (`vite`, `vitest`, flat eslint) moves fast — re-verify the default-tool
  choices against upstream on a cadence when regenerating.
- No conflicts among the current source files.
  </content>
  </invoke>
