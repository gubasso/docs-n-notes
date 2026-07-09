# 01 — Quality gates

The R concretion of the general
[quality gates](../../../programming/project-bootstrap/04-quality-gates.md) and
[security baseline](../../../programming/project-bootstrap/06-security-baseline.md) chapters.

## Formatter — `styler` / `air`

Pick one formatter and enforce it:

- [`styler`](https://styler.r-lib.org/) — the established, tidyverse-style reformatter. Check with
  `styler::style_pkg(dry = "on")` (packages) or `styler::style_dir(dry = "on")` (projects).
- [`air`](https://posit-dev.github.io/air/) — Posit's fast, opinionated R formatter (a CLI, no R
  session needed). Check with `air format --check .`.

Use `air` where you want a language-server/CLI formatter like `rustfmt`; use `styler` where you want
the in-session tidyverse tool. Enforce the chosen one in CI in `--check` mode.

## Linter — `lintr`

[`lintr`](https://lintr.r-lib.org/) is the static linter. Configure it with a `.lintr` file and fail
CI on any lint:

```r
lintr::lint_package()   # packages
lintr::lint_dir()       # projects
```

Treat lints as errors in CI so they block the build.

## Tests — `testthat`

[`testthat`](https://testthat.r-lib.org/) is the standard test framework; `usethis::use_testthat()`
scaffolds `tests/testthat/`. Run:

```r
testthat::test_dir("tests/testthat")   # or devtools::test() for a package
```

## `R CMD check` (packages)

For a **package**, `R CMD check` is the umbrella gate — it runs tests, checks documentation and
`NAMESPACE` consistency, and flags portability issues. Run it via
[`rcmdcheck`](https://rcmdcheck.r-lib.org/):

```r
rcmdcheck::rcmdcheck(args = "--no-manual", error_on = "warning")
```

Analysis projects have no `R CMD check`; their gate is styler/air + lintr + testthat plus a
successful pipeline render (see [`analysis-project.md`](./analysis-project.md)).

## Pre-commit wiring

Wire the formatter (`--check` mode) and `lintr` into the pre-commit hooks from the general
[04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md). The
[`precommit`](https://lorenzwalthert.github.io/precommit/) R package ships ready-made hooks
(`style-files`, `lintr`, `roxygenize`, `readme-rmd-rendered`) if you prefer R-native hooks over
generic ones.

## Dependency review (security baseline)

The R analogue of the general security baseline is keeping `renv.lock` reviewed and current; check
for known-vulnerable dependencies with
[`oysteR`](https://sonatype-nexus-community.github.io/oysteR/) (OSS Index audit). Run it in CI
alongside the other gates. Publish-readiness checks (CRAN policy, `R CMD check --as-cran`) belong to
a later release phase, not bootstrap.
