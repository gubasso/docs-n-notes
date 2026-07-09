---
digest-of: tech/languages/r/project-bootstrap-spec
last-synced: 2026-07-09
source-files:
  - README.md
  - runbook.md
  - 00-toolchain-and-layout.md
  - 01-quality-gates.md
  - package-project.md
  - analysis-project.md
token-estimate: 780
---

# AGENTS

## Scope

R binding of the general `tech/programming/project-bootstrap/` shelf: the once-per-project R setup
that takes an empty repo to a scaffolded, gated, reproducible project ready for feature work. It
**overlays** the general spine (repo, license, governance, dev env, CI, security) and never restates
it; it owns only the R ecosystem choices and the two implementation-kind orderings (package,
analysis). Publishing (CRAN) is out of scope — it hands off to a later release phase.

## Key Points

- **Scaffold:** `usethis` lays down the skeleton — `usethis::create_package(".")` (adds
  `DESCRIPTION`, `R/`, `NAMESPACE`, `.Rproj`) for a package, `usethis::create_project(".")` for an
  analysis/research project (plain, no package machinery). Both are idempotent in an existing dir.
- **Reproducible env:** `renv` is non-negotiable. `renv::init()` creates a project-local library,
  `renv.lock`, and the `.Rprofile` hook; `renv::snapshot()` records exact versions;
  `renv::restore()` rebuilds in CI/on another machine. Commit `renv.lock`, `.Rprofile`,
  `renv/activate.R`; ignore `renv/library/`.
- **Metadata:** package `DESCRIPTION` bootstrap-minimum is `Package`, `Title`, `Version`,
  `Depends: R (>= x.y)`, and known imports via `usethis::use_package("<pkg>")` (`Imports:`).
  Publish-grade metadata (full `Authors@R`, `License`, `URL`/`BugReports`, `cran-comments.md`) is
  deferred to release. Analysis projects have no `DESCRIPTION` — their dependency contract is
  `renv.lock`.
- **R version pin + Nix:** pin the minimum in `DESCRIPTION` `Depends:` and/or `renv.lock`; a Nix
  devShell provides that exact R + system libs so local and CI share one interpreter. Nix owns the
  _interpreter_; `renv` owns the _packages_ layered on top (`nix/02-per-project-devshell`).
- **Quality gates:** one formatter — `styler` (in-session tidyverse, `style_pkg`/`style_dir(dry)`)
  or `air` (Posit CLI, `air format --check .`) — enforced in `--check` mode; `lintr` (static lint
  via `.lintr`, treated as errors in CI); `testthat` (`use_testthat()` scaffolds `tests/testthat/`).
  For packages, `R CMD check` (via `rcmdcheck`, `error_on = "warning"`) is the umbrella gate.
  Security analogue: keep `renv.lock` reviewed and audit deps with `oysteR` (OSS Index) in CI.
- **Pre-commit:** wire formatter (`--check`) and `lintr` into the general hooks; the `precommit` R
  package ships R-native hooks (`style-files`, `lintr`, `roxygenize`, `readme-rmd-rendered`).
- **Package kind:** fill `DESCRIPTION`; source under `R/` (one topic per file, `use_r()` makes file
  - test stub); document with `roxygen2` `#'` blocks → `devtools::document()` generates `man/*.Rd`
    and `NAMESPACE` (never hand-edit those); `devtools` inner loop
    `load_all`/`document`/`test`/`check`; optional `use_vignette()`. Stops at a package that loads,
    docs, tests, lints, and `R CMD check`s clean.
- **Analysis kind:** lock env first (`renv::init` + `snapshot`); conventional dirs `data-raw/`
  (immutable inputs, read-only), `R/`/`scripts/`, `output/` (git-ignored); declare the pipeline with
  `targets` in `_targets.R` (`tar_make()` re-runs only stale steps); author a Quarto `.qmd` / R
  Markdown `.Rmd` report as the terminal target; CI runs `renv::restore()` then `tar_make()`/render.
  No `R CMD check`. Stops at a pipeline that restores and runs green from the lockfile.
- **Automation:** `bootstrap-nix` provisions the R interpreter; `bootstrap-precommit` /
  `bootstrap-taskrunner` wire the gates. The steps here are the SoT; cog owns the _how_ (general
  `07-automation-with-cog.md`).

## Source Map

| Topic                                                                    | File                         |
| ------------------------------------------------------------------------ | ---------------------------- |
| Binding index, how-to-use, implementation-kinds list, related            | `README.md`                  |
| Ordered R overlay steps (the _what_/_in what order_)                     | `runbook.md`                 |
| `usethis` scaffold, `DESCRIPTION`, `renv`, R version pin + Nix           | `00-toolchain-and-layout.md` |
| `styler`/`air`, `lintr`, `testthat`, `R CMD check`, pre-commit, `oysteR` | `01-quality-gates.md`        |
| Package bootstrap ordering (`DESCRIPTION`, `R/`, roxygen2, devtools)     | `package-project.md`         |
| Analysis bootstrap ordering (`renv`, `targets`, Quarto/R Markdown)       | `analysis-project.md`        |

## Maintenance Notes

- General spine: `../../../programming/project-bootstrap/`. Existing R notes (Rscript, R Markdown,
  CRAN, citations): `../R.md`. Dev environment host:
  `../../../tools/nix/02-per-project-devshell.md`.
- Other kinds (Shiny app, `{golem}`/`{plumber}` service) are declared followups; add the file (and
  refresh `source-files`) when that kind is bootstrapped.
- Formatter is a pick-one choice (`styler` vs `air`); note it rather than defaulting when
  regenerating. The R tooling (`air`, `renv`, `targets`) moves — re-verify choices on a cadence.
- No conflicts among the current source files.
  </content>
  </invoke>
