# Runbook — bootstrap a new CSS project

The ordered, **once-per-project** CSS-specific steps, overlaying the general spine. Each step links
to the chapter that explains the _why_; this page is only the _what_ and _in what order_.

Do the general steps first (repo, license, governance, dev env, CI, security) from the
[general runbook](../../../programming/project-bootstrap/runbook.md); the steps below are the CSS
overlay that slots into it.

## Prerequisites

- The [general bootstrap runbook](../../../programming/project-bootstrap/runbook.md) is understood —
  repo created, foundations and governance in place.
- A Nix devShell exists (or will) to host Node.js and the package manager — see
  [00 — Toolchain & layout](00-toolchain-and-layout.md). _Automate:_ `bootstrap-nix`.

## Steps

1. **Initialize the package.** `npm init` (or `pnpm init`) to create `package.json`; pin the package
   manager with the `packageManager` field. → [00 — Toolchain & layout](00-toolchain-and-layout.md).

2. **Choose the stylesheet architecture and naming.** Decide on a layer model (e.g. ITCSS) and a
   naming convention (e.g. BEM), and reserve a tokens/variables layer. →
   [00 — Toolchain & layout](00-toolchain-and-layout.md).

3. **Pick the CSS processing pipeline.** PostCSS (with `autoprefixer` + `postcss-preset-env`) or
   Sass/Dart Sass, and a bundler such as Vite. Wire it into the Nix devShell so local and CI share
   one toolchain. → [00 — Toolchain & layout](00-toolchain-and-layout.md).

4. **Configure quality gates.** `stylelint` (with `stylelint-config-standard`), `prettier`, and an
   optional visual-regression approach. → [01 — Quality gates](01-quality-gates.md). _Automate:_
   `bootstrap-precommit`, `bootstrap-taskrunner`.

5. **Pick the implementation kind.** For a reusable design system, follow
   [`stylesheet-library.md`](stylesheet-library.md); other kinds are followups.

6. **Continue the general spine.** Return to the
   [general runbook](../../../programming/project-bootstrap/runbook.md) for governance, CI, and
   security if not already done. _Automate:_ `bootstrap-ci`.

## Reference

- [00 — Toolchain & layout](00-toolchain-and-layout.md) · [01 — Quality gates](01-quality-gates.md)
  · [general runbook](../../../programming/project-bootstrap/runbook.md)
