# Python — bootstrap a new project (spec/binding)

The Python binding of
[`tech/programming/project-bootstrap/`](../../../programming/project-bootstrap/README.md). It
applies the general once-per-project recipe with concrete Python tooling — `uv`-managed
`pyproject.toml`/src-layout projects, Python-version pinning, and the ruff/mypy/pytest/pip-audit
quality gates — and links to Python implementation-kinds.

This binding **overlays** the general spine; it does not restate it. Read the general recipe first,
then the Python specifics here.

## How to use this binding

1. Read the general [hub](../../../programming/project-bootstrap/README.md) and
   [general runbook](../../../programming/project-bootstrap/runbook.md) — the cross-language _what_.
1. Follow this [`runbook.md`](runbook.md) for the Python-specific overlay steps.
1. Jump to your implementation-kind file (e.g. [`cli-project.md`](cli-project.md) or
   [`library-project.md`](library-project.md)).
1. When ready to publish, hand off to
   [`../release-workflow-spec/`](../release-workflow-spec/README.md) — the later Python release
   phase.

## Index

| # | Chapter                                          | One-line hook                                                               |
| - | ------------------------------------------------ | --------------------------------------------------------------------------- |
| 0 | [Toolchain & layout](00-toolchain-and-layout.md) | `uv init`, `pyproject.toml` (PEP 621), src layout, `.python-version` + Nix. |
| 1 | [Quality gates](01-quality-gates.md)             | `ruff` (format + lint), `mypy`/`pyright`, `pytest`, `pip-audit`.            |

## Implementation kinds

- [`cli-project.md`](cli-project.md) — Python CLI: the bootstrap-time ordering for arg-parsing,
  logging, and config with `argparse`/`click`/`typer`.
- [`library-project.md`](library-project.md) — Python library: the bootstrap-time ordering for a
  distributable PyPI package (public API, packaging metadata, docs).

`web-service.md` is a followup; add it when you bootstrap that kind.

## Related

- [General project-bootstrap](../../../programming/project-bootstrap/README.md) — the cross-language
  recipe this binding overlays.
- [`../release-workflow-spec/`](../release-workflow-spec/README.md) — the later Python release &
  publishing phase.
