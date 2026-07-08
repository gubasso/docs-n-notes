---
digest-of: tech/languages/python/release-workflow-spec
last-synced: 2026-07-08
source-files:
  - README.md
  - runbook.md
token-estimate: 700
---

# AGENTS

## Scope

Python binding of the general `tech/programming/release-workflow/` shelf — currently a **skeleton**
to expand when a Python project adopts it. Follows the same per-language role skeleton as the rust
and bash shelves.

## Key Points

- **Version SoT:** committed `pyproject.toml` `[project] version` (or `__version__`), bumped in
  place by the release tool; the annotated tag mirrors it.
- **Tooling:** release-please (PR gate) or python-semantic-release (push model); publish via
  `pypa/gh-action-pypi-publish` or `uv publish`.
- **Auth:** PyPI Trusted Publishing (OIDC), `permissions: id-token: write`, no stored token; first
  publish is manual (TP attaches to an existing project). The trusted publisher matches the publish
  **workflow filename** — keep it stable.
- **Distribution:** the published wheels + sdist _are_ the distribution (no separate binary-dist
  tool).
- **Setup:** `runbook.md` is the per-new-project skeleton; `develop`/`master` model as elsewhere.

## Source Map

| Topic                          | File         |
| ------------------------------ | ------------ |
| Skeleton index + role map      | `README.md`  |
| Per-new-project setup skeleton | `runbook.md` |

## Maintenance Notes

- Expand into full chapters (metadata, trusted publishing, release automation) when a real Python
  project adopts this; regenerate then.
- General principles: `../../../programming/release-workflow/`. Related: `../python-poetry.md`.
