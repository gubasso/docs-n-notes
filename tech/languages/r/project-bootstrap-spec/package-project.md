# R package project — implementation-kind additions

What an R **package** adds on top of the general recipe and the R binding: the `DESCRIPTION`
contract, the `R/` + `man/` layout, `roxygen2` documentation, and the `devtools` inner loop. This
file owns only the **bootstrap-time ordering**; everyday authoring detail lives in the tool docs it
links.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the R
  [binding runbook](./runbook.md) are done — a loadable project with `renv` initialised exists.
- The project was scaffolded with `usethis::create_package(".")`.

## Add these, in this order

1. **Fill the `DESCRIPTION` contract.** `Package`, `Title`, `Version`, `Depends: R (>= x.y)`, and
   declare dependencies with `usethis::use_package("<pkg>")` (adds to `Imports:`). →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md).

2. **Establish the `R/` source layout.** Put exported and internal functions under `R/`; one
   coherent topic per file. `usethis::use_r("<name>")` creates a source file plus its test stub.

3. **Document with `roxygen2` → `man/`.** Write `#'` roxygen blocks above each exported function;
   run `devtools::document()` (or `roxygen2::roxygenise()`) to generate `man/*.Rd` and the
   `NAMESPACE`. Never hand-edit `man/` or `NAMESPACE` — they are generated.

4. **Wire the test suite.** `usethis::use_testthat()` scaffolds `tests/testthat/`; add tests
   alongside each `R/` file. → [01 — Quality gates](./01-quality-gates.md).

5. **Adopt the `devtools` inner loop.** `devtools::load_all()` (load), `devtools::document()`
   (regenerate docs), `devtools::test()` (run tests), `devtools::check()` (full `R CMD check`) — the
   day-to-day cycle the quality gates enforce.

6. **(Optional) Add a vignette.** `usethis::use_vignette("<name>")` for long-form usage docs under
   `vignettes/`.

## Quality gate for packages

The umbrella gate is `R CMD check` (via `rcmdcheck`), on top of styler/air + lintr + testthat — see
[01 — Quality gates](./01-quality-gates.md). Bootstrap stops at a package that loads, documents,
tests, lints, and `R CMD check`s clean.

## Publishing (later phase)

CRAN submission, `R CMD check --as-cran`, `cran-comments.md`, and reverse-dependency checks are
release-phase work, not bootstrap. Bootstrap stops at a green, installable package.
