# R — bootstrap a new project (spec/binding)

The R binding of
[`tech/programming/project-bootstrap/`](../../../programming/project-bootstrap/README.md). It
applies the general once-per-project recipe with concrete R tooling — `usethis` project scaffolding,
`renv` for reproducible environments, and the styler/air + lintr + testthat quality gates — and
links to R implementation-kinds.

This binding **overlays** the general spine; it does not restate it. Read the general recipe first,
then the R specifics here.

## How to use this binding

1. Read the general [hub](../../../programming/project-bootstrap/README.md) and
   [general runbook](../../../programming/project-bootstrap/runbook.md) — the cross-language _what_.
1. Follow this [`runbook.md`](runbook.md) for the R-specific overlay steps.
1. Jump to your implementation-kind file (e.g. [`package-project.md`](package-project.md) or
   [`analysis-project.md`](analysis-project.md)).

## Index

| # | Chapter                                          | One-line hook                                                      |
| - | ------------------------------------------------ | ------------------------------------------------------------------ |
| 0 | [Toolchain & layout](00-toolchain-and-layout.md) | `usethis::create_package`/`create_project`, `DESCRIPTION`, `renv`. |
| 1 | [Quality gates](01-quality-gates.md)             | `styler`/`air`, `lintr`, `testthat`, `R CMD check`, pre-commit.    |

## Implementation kinds

- [`package-project.md`](package-project.md) — an R **package**: `DESCRIPTION`, `R/`, `man/`,
  `roxygen2`, and the `devtools` inner loop.
- [`analysis-project.md`](analysis-project.md) — a reproducible **analysis/research** project:
  `renv`, `targets`, and Quarto/R Markdown reporting.

Other kinds (e.g. a Shiny app, an `{golem}`/`{plumber}` service) are followups; add a file when you
bootstrap that kind.

## Related

- [General project-bootstrap](../../../programming/project-bootstrap/README.md) — the cross-language
  recipe this binding overlays.
- [`../R.md`](../R.md) — the existing R notes (Rscript, R Markdown, CRAN, citations).
- [Nix per-project devShell](../../../tools/nix/02-per-project-devshell.md) — how the local dev
  environment hosts the R toolchain.
