# Runbook — bootstrap a new JavaScript project

The ordered, **once-per-project** JavaScript/Node-specific steps, overlaying the general spine. Each
step links to the chapter that explains the _why_; this page is only the _what_ and _in what order_.

Do the general steps first (repo, license, governance, dev env, CI, security) from the
[general runbook](../../../programming/project-bootstrap/runbook.md); the steps below are the
JavaScript overlay that slots into it.

## Prerequisites

- The [general bootstrap runbook](../../../programming/project-bootstrap/runbook.md) is understood —
  repo created, foundations and governance in place.
- A Nix devShell exists (or will) to host the Node toolchain — see
  [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md).

## Steps

1. **Initialize the package.** `npm init -y` (or `pnpm init`) to create `package.json`; set
   `"type": "module"` for ESM and lay out a `src/` tree. →
   [00 — Toolchain & layout](00-toolchain-and-layout.md).

2. **Pin the Node version.** Add a `.nvmrc` and an `engines.node` range so local, CI, and the Nix
   devShell agree on one Node. → [00 — Toolchain & layout](00-toolchain-and-layout.md),
   [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md).

3. **Add TypeScript (if used).** Install `typescript`, add a `tsconfig.json`, and point `tsc` at
   `src/`. → [00 — Toolchain & layout](00-toolchain-and-layout.md).

4. **Configure quality gates.** prettier (format), eslint (lint), a test runner (vitest or jest),
   `tsc --noEmit` (typecheck), and `npm audit` for the security baseline; wire them into pre-commit.
   → [01 — Quality gates](01-quality-gates.md).

5. **Pick the implementation kind.** For a Node CLI, follow [`cli-project.md`](cli-project.md); for
   a front-end app, follow [`web-app.md`](web-app.md); a published library is a followup.

6. **Continue the general spine.** Return to the
   [general runbook](../../../programming/project-bootstrap/runbook.md) for governance, CI, and
   security if not already done.

7. **When ready to release,** hand off to
   [`../release-workflow-spec/README.md`](../release-workflow-spec/README.md) — the later
   JavaScript/Node release phase (Changesets, npm publish).

## Reference

- [00 — Toolchain & layout](00-toolchain-and-layout.md) · [01 — Quality gates](01-quality-gates.md)
  · [general runbook](../../../programming/project-bootstrap/runbook.md) ·
  [`../release-workflow-spec/`](../release-workflow-spec/README.md)
