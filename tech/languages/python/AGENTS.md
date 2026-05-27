---
digest-of: tech/languages/python
last-synced: 2026-05-27
source-files:
  - code-review-guide.md
  - django-code-review-guide.md
  - python.md
  - pydantic-mixins-with-enums.md
  - pydantic-validators.md
  - pytest-conftest-fixture.md
  - install-local-python-module-with-cli-access-in-a-virtual-environment.md
  - python-eve.md
  - python-flask.md
  - python-mongo.md
  - python-poetry.md
token-estimate: 500
---

# AGENTS

## Scope

Python language notes at the top level (outside `cli-spec/`). Includes code-review guides (Python,
Django), general notes, Pydantic patterns, pytest fixtures, and framework references.

## Key Points

- **Code review guide**: Python-specific review heuristics loaded by `review-code-deep` when `.py`
  files are in the diff.
- **Django review guide**: Django-specific review heuristics (N+1 queries, migrations, security,
  template injection).
- **General notes** (`python.md`): Shell commands via subprocess, type hints (mypy cheat sheet), CLI
  libraries (docopt), rich/pprint, general patterns.
- **Pydantic**: Mixin patterns with enums, validator patterns (field validators, model validators).
- **Testing**: pytest conftest fixture patterns and organization.
- **Packaging**: Installing local Python module with CLI access in a virtualenv.
- **Frameworks**: Eve, Flask, MongoDB integration notes.
- **Poetry**: Package management patterns.

## Source Map

| Topic                       | File                                                                      |
| --------------------------- | ------------------------------------------------------------------------- |
| Python review heuristics    | `code-review-guide.md`                                                    |
| Django review heuristics    | `django-code-review-guide.md`                                             |
| General Python notes        | `python.md`                                                               |
| Pydantic enum mixins        | `pydantic-mixins-with-enums.md`                                           |
| Pydantic validators         | `pydantic-validators.md`                                                  |
| pytest conftest/fixture     | `pytest-conftest-fixture.md`                                              |
| Local module + CLI in venv  | `install-local-python-module-with-cli-access-in-a-virtual-environment.md` |
| Flask, Eve, MongoDB, Poetry | `python-flask.md`, `python-eve.md`, `python-mongo.md`, `python-poetry.md` |
| CLI project spec            | `cli-spec/` (separate AGENTS.md)                                          |

## Maintenance Notes

- CLI-spec has its own AGENTS.md; this digest covers only the top-level Python files.
- Framework notes (Eve, Flask, MongoDB) are reference-link collections; load directly when relevant.
