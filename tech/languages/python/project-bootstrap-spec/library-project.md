# Python library project — implementation-kind additions

What a **library** (distributable PyPI package) project adds on top of the general recipe and the
Python binding: a public API surface, packaging metadata, and docs. This file owns only the
**bootstrap-time ordering**.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the Python
  [binding runbook](./runbook.md) are done — an importable, gated project exists.
- The project uses the **src layout** and declares a build backend in `[build-system]` — see
  [00 — Toolchain & layout](./00-toolchain-and-layout.md).

## Add these, in this order

1. **Public API surface.** Decide what the package exports. Define `__all__` in the package
   `__init__.py` and keep internal modules private (leading-underscore or an `_internal` package).

2. **Type-checking support.** Add a `py.typed` marker file to the package so downstream users get
   your type hints (PEP 561). This pairs with the `mypy`/`pyright` gate from
   [01 — Quality gates](./01-quality-gates.md).

3. **Test the installed package.** The src layout already forces tests to run against the built
   package; keep `tests/` outside `src/`. → [01 — Quality gates](./01-quality-gates.md).

4. **Docs skeleton.** Seed a `README.md` (the packaging `readme`) and, if the API is non-trivial, a
   docs tree (e.g. `mkdocs` or `sphinx`). Bootstrap only stubs it; content grows with the code.

## Publishing (later phase)

Publish-grade metadata (`license`, `authors`, `classifiers`, `urls`), building the sdist/wheel
(`uv build`), and uploading to PyPI via Trusted Publishing are release-phase work — see
[`../release-workflow-spec/`](../release-workflow-spec/README.md). Bootstrap stops at a buildable,
importable, gated package.
