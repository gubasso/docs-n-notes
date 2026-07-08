# 00 — Toolchain & layout

The JavaScript/Node ecosystem choices for a fresh project: which package manager, how to initialize
`package.json`, the source layout, TypeScript and module-type setup, how to pin Node, and how the
Nix devShell hosts it all.

## Package manager

Use **npm** as the mainstream default — it ships with Node and needs no extra install. Prefer
**pnpm** when disk-efficient, strict dependency resolution or a monorepo matters. Whichever you
pick, commit its lockfile (`package-lock.json` or `pnpm-lock.yaml`) so installs are reproducible,
and do not mix the two in one repo.

## Initialize `package.json`

```bash
npm init -y      # or: pnpm init
```

Set the minimum now: `name`, `version`, `description`, and `"type": "module"` for ESM. Add
`"private": true` unless this is a package you intend to publish. Leave publish-grade metadata
(`files`, `exports`, `publishConfig`, `repository`, `keywords`) to the release phase — it is owned
by [`../release-workflow-spec/`](../release-workflow-spec/README.md), so do not duplicate that gate
here. Bootstrap only needs enough to install, build, and test.

## Module type — ESM

Set `"type": "module"` so `.js` files are ES modules (`import`/`export`) rather than CommonJS. This
is the modern default and aligns with TypeScript and Vite. Use the `.cjs` extension for the rare
file that must stay CommonJS.

## Source layout

Keep application/library code under `src/` and emitted output under `dist/` (git-ignored). A minimal
tree:

```text
.
├── package.json
├── tsconfig.json        # if using TypeScript
├── src/
│   └── index.ts
└── dist/                # build output, git-ignored
```

## TypeScript setup

Install TypeScript as a dev dependency and add a `tsconfig.json`:

```bash
npm install -D typescript
npx tsc --init
```

Point the compiler at `src/`, emit to `dist/`, and choose modern targets:

```jsonc
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src"]
}
```

`strict: true` is the baseline. Typechecking as a gate lives in
[01 — Quality gates](01-quality-gates.md).

## Node version pinning + Nix

Pin one Node version so local, CI, and the devShell agree:

- Add a `.nvmrc` (e.g. `20`) for `nvm`/`fnm` users, or a `volta` block in `package.json` if the team
  uses Volta.
- Add an `engines.node` range in `package.json` so a wrong Node is caught on install.
- The canonical per-project setup provisions that same Node from a Nix devShell so local and CI
  share one toolchain — see
  [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md). This closes the
  "works on my machine" gap before any code is written.

## Automation

The general foundations (repo files, Nix devShell, editorconfig, pre-commit, task runner, CI) are
automated by the general `bootstrap-*` skills; see
[general 07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md).
There is no JS-specific scaffold skill — the `npm init` / `tsc --init` steps above are the SoT.
