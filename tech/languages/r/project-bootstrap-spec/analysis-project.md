# R analysis project — implementation-kind additions

What a reproducible **analysis / research** project adds on top of the general recipe and the R
binding: a pinned environment, a declarative pipeline, and a reproducible report. This file owns
only the **bootstrap-time ordering**; everyday authoring detail lives in the tool docs it links.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the R
  [binding runbook](./runbook.md) are done.
- The project was scaffolded with `usethis::create_project(".")` (a project, not a package).

## Add these, in this order

1. **Lock the environment first.** `renv::init()` then `renv::snapshot()` — an analysis is only
   reproducible if `renv.lock` pins every dependency. Commit `renv.lock` and `.Rprofile`. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md).

2. **Lay out data / code directories.** A conventional shape: `data-raw/` (immutable inputs), `R/`
   or `scripts/` (transformation code), `output/` (generated, git-ignored). Keep raw data read-only.

3. **Declare the pipeline with `targets`.** [`targets`](https://docs.ropensci.org/targets/) turns
   the analysis into a dependency graph in `_targets.R` — it re-runs only stale steps and gives you
   a reproducible `tar_make()`. This is the analysis analogue of a build system.

4. **Author the report with Quarto or R Markdown.** A `.qmd` (Quarto) or `.Rmd` document renders
   code
   - prose to HTML/PDF; render it as the pipeline's terminal target. See the existing
     [R Markdown notes](../R.md) for the R Markdown/pandoc setup.

5. **Wire the reproducibility gate.** CI runs `renv::restore()` then `tar_make()` (or renders the
   report) so a broken pipeline fails the build. → [01 — Quality gates](./01-quality-gates.md).

## Quality gate for analyses

styler/air + lintr + testthat (for any reusable functions in `R/`), plus a **successful end-to-end
`tar_make()` / report render** from a clean `renv::restore()`. There is no `R CMD check` for a
non-package project. Bootstrap stops at a pipeline that restores and runs green from the lockfile.

## Related

- [`../R.md`](../R.md) — existing R Markdown / pandoc / citation notes.
- [00 — Toolchain & layout](./00-toolchain-and-layout.md) — `renv` and R version pinning.
