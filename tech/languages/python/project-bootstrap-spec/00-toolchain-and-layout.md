# 00 — Toolchain & layout

The Python ecosystem choices for a fresh project: which project/dependency manager to use, what
baseline `pyproject.toml` metadata to set, the src layout, how to pin the interpreter, and where the
virtualenv and Nix devShell fit.

## Project & dependency manager

`uv` is the modern default — a single fast tool that manages the interpreter, the virtualenv, the
lockfile (`uv.lock`), and dependencies. Scaffold with:

- Application: `uv init <name>`.
- Distributable package: `uv init --package <name>` (adds a build backend and `src/` layout).
- In an existing directory: `uv init` (or `uv init --package`).

`uv add <dep>` / `uv add --dev <dep>` manage runtime and dev dependencies. Alternatives that solve
the same job — pick one and keep it as the single owner: **Poetry**, **PDM**, or **pip-tools**
(`pip-compile`) over a plain `pip` + `requirements.txt` flow.

## `pyproject.toml` baseline metadata (PEP 621)

`pyproject.toml` is the single project manifest. Set the minimum now under `[project]`: `name`,
`version`, `requires-python`, and a short `description`. Declare the build backend in
`[build-system]` (e.g. `hatchling`, or `uv_build` for uv-native builds). Leave publish-grade
metadata (`license`, `authors`, `readme`, `urls`, `classifiers`, `keywords`) to the release phase —
it is owned by [`../release-workflow-spec/`](../release-workflow-spec/README.md), so do not
duplicate that gate here. Bootstrap only needs enough to build, import, and test.

## src layout

Prefer the **src layout** — the importable package lives under `src/<name>/`, tests under `tests/`.
This forces you to test the installed package rather than the source tree and avoids accidental
implicit imports. `uv init --package` scaffolds this shape; for an application, move the package
under `src/` to match.

## Python version pinning + virtualenv + Nix

Pin one interpreter version with `.python-version` (a single line, e.g. `3.12`). `uv` reads it to
create and manage the project virtualenv (`.venv/`) automatically; you rarely activate it by hand
(`uv run <cmd>` uses it). The canonical per-project setup provisions the interpreter (and `uv`) from
a Nix devShell so local and CI share one toolchain — see
[nix/02-per-project-devshell](../../../tools/nix/02-per-project-devshell.md). This closes the "works
on my machine" gap before any code is written.

## Layout detail

For a single package, the default `uv init` layout is enough to start. For a CLI with subcommands or
a distributable library, follow the implementation-kind file: [`cli-project.md`](./cli-project.md)
or [`library-project.md`](./library-project.md). Bootstrap owns the _ordering_ (get an importable,
buildable project first); the kind files own the shape-specific additions.

## Automation

`bootstrap-nix` provisions the devShell that hosts the interpreter and `uv`; the general
[07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md)
explains the SoT-vs-cog contract.
