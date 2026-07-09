# 00 — Toolchain & layout

The R ecosystem choices for a fresh project: how to scaffold it, what baseline metadata to set, how
to make the environment reproducible, and how to pin the R version.

## Scaffold the project

Use [`usethis`](https://usethis.r-lib.org/) to lay down a conventional skeleton:

- Package: `usethis::create_package(".")` (creates `DESCRIPTION`, `R/`, `NAMESPACE`, `.Rproj`).
- Analysis / research project: `usethis::create_project(".")` (a plain project without package
  machinery).

Both are idempotent enough to run in an existing directory. Pick the kind here; the shape-specific
additions live in [`package-project.md`](./package-project.md) and
[`analysis-project.md`](./analysis-project.md).

## `DESCRIPTION` baseline metadata

For a package, set the minimum now: `Package`, `Title`, `Version`, `Depends: R (>= x.y)`, and the
imports you already know (`usethis::use_package("<pkg>")` maintains the `Imports:` field). Leave
publish-grade metadata (full `Authors@R`, `License` finalisation, `URL`/`BugReports`, CRAN
`cran-comments.md`) to the release phase — bootstrap only needs enough to build, load, and test.

An analysis project has no `DESCRIPTION`; its dependency contract is `renv.lock` (see below).

## Dependency management — `renv`

[`renv`](https://rstudio.github.io/renv/) is the non-negotiable for reproducible environments:

- `renv::init()` creates a project-local library, `renv.lock`, and the activation hook in
  `.Rprofile`.
- `renv::snapshot()` records the exact package versions into `renv.lock` after you add or upgrade a
  dependency.
- `renv::restore()` rebuilds the library from `renv.lock` on another machine or in CI.

Commit `renv.lock`, `.Rprofile`, and `renv/activate.R`; ignore the project library
(`renv/library/`). This is what closes the "works on my machine" gap for packages.

## R version pinning + Nix

Pin the R version explicitly:

- In a package, express the minimum in `DESCRIPTION` (`Depends: R (>= 4.4)`).
- `renv.lock` records the R version used to build the lockfile.

The canonical per-project setup provides that exact R from a Nix devShell so local and CI share one
interpreter — see [nix/02-per-project-devshell](../../../tools/nix/02-per-project-devshell.md). Nix
owns the R _interpreter_ and system libraries; `renv` owns the R _packages_ layered on top.

## Layout

The `usethis` scaffold is enough to start. Package layout (`R/`, `man/`, `tests/`, `vignettes/`) is
detailed in [`package-project.md`](./package-project.md); analysis layout (`renv`, `targets`,
Quarto) in [`analysis-project.md`](./analysis-project.md). Bootstrap owns the _ordering_ (get a
loadable project first); the kind files own the shape-specific _how_.

## Automation

`bootstrap-nix` provides the R interpreter via the devShell; `renv` pins the packages on top. The
steps above are the SoT; see
[general 07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md).
