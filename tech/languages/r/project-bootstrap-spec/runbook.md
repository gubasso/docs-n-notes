# Runbook — bootstrap a new R project

The ordered, **once-per-project** R-specific steps, overlaying the general spine. Each step links to
the chapter that explains the _why_; this page is only the _what_ and _in what order_.

Do the general steps first (repo, license, governance, dev env, CI, security) from the
[general runbook](../../../programming/project-bootstrap/runbook.md); the steps below are the R
overlay that slots into it.

## Prerequisites

- The [general bootstrap runbook](../../../programming/project-bootstrap/runbook.md) is understood —
  repo created, foundations and governance in place.
- A Nix devShell exists (or will) to host R and the toolchain — see
  [nix/02-per-project-devshell](../../../tools/nix/02-per-project-devshell.md).

## Steps

1. **Scaffold the project.** `usethis::create_package(".")` for a package or
   `usethis::create_project(".")` for an analysis/research project (both are idempotent in an
   existing dir). → [00 — Toolchain & layout](./00-toolchain-and-layout.md).

2. **Initialise the reproducible environment.** `renv::init()` to create `renv.lock` and pin the
   package library; commit `renv.lock` and `.Rprofile`. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md). _Automate:_ `bootstrap-nix` hosts the R
   version; `renv` pins the packages.

3. **Pin the R version and host it in Nix.** Record the R version (in `DESCRIPTION` `Depends:`
   and/or `renv.lock`) and wire R into the Nix devShell so local and CI share one interpreter. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md),
   [nix/02-per-project-devshell](../../../tools/nix/02-per-project-devshell.md).

4. **Configure quality gates.** styler/air (format), lintr (lint), testthat (tests), and — for
   packages — `R CMD check`, wired into pre-commit. → [01 — Quality gates](./01-quality-gates.md).
   _Automate:_ `bootstrap-precommit`, `bootstrap-taskrunner`.

5. **Pick the implementation kind.** For a package, follow
   [`package-project.md`](./package-project.md); for a reproducible analysis, follow
   [`analysis-project.md`](./analysis-project.md).

6. **Continue the general spine.** Return to the
   [general runbook](../../../programming/project-bootstrap/runbook.md) for CI, branch protection,
   and security if not already done. →
   [general 05 — CI & release-readiness](../../../programming/project-bootstrap/05-ci-and-release-readiness.md).

## Reference

- [00 — Toolchain & layout](./00-toolchain-and-layout.md) ·
  [01 — Quality gates](./01-quality-gates.md) ·
  [general runbook](../../../programming/project-bootstrap/runbook.md) · [`../R.md`](../R.md)
