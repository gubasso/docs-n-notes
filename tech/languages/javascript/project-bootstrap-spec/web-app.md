# Web app project — implementation-kind additions

What a **front-end web app** adds on top of the general recipe and the JavaScript binding: a build
tool, a UI framework, and the dev/build/preview scripts. This file owns only the **bootstrap-time
ordering**; it stops at a working, gated app skeleton.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the JavaScript
  [binding runbook](./runbook.md) are done — an installable, gated package exists.

## Add these, in this order

Layer these on the initialized package in order:

1. **Scaffold with Vite.** [Vite](https://vitejs.dev/) is the mainstream dev/build tool. Scaffold a
   typed app and pick a framework template:

   ```bash
   npm create vite@latest my-app -- --template react-ts
   ```

   Common templates: `react-ts`, `vue-ts`, `svelte-ts`, `vanilla-ts`. This lays down `index.html`,
   `src/`, and the dev/build/preview scripts. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md).

2. **Reconcile with the existing gates.** Fold Vite's generated `package.json` scripts and any
   framework eslint plugin into the prettier/eslint/vitest gates from
   [01 — Quality gates](./01-quality-gates.md) rather than duplicating configs — vitest is
   Vite-native and reuses the same config.

3. **Wire the scripts.** Ensure `dev` (local server), `build` (production bundle to `dist/`), and
   `preview` (serve the build) exist and that `dist/` is git-ignored.

4. **Framework code-review conventions.** Follow the sibling review guides for your framework:
   [react-code-review-guide](../react-code-review-guide.md),
   [svelte-code-review-guide](../svelte-code-review-guide.md), or
   [typescript-code-review-guide](../typescript-code-review-guide.md).

## Deployment (later phase)

Building for production and deploying the bundle (static host, CDN, container) is
release/deploy-phase work — see [`../release-workflow-spec/`](../release-workflow-spec/README.md).
Bootstrap stops at an app that runs via `npm run dev` and builds clean via `npm run build`.
