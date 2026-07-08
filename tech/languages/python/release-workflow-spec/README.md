# Python Release Workflow Spec

This is the **Python binding** of the
[general principles](../../../programming/release-workflow/README.md); it is a **stub to be
expanded** when a Python project actually adopts it.

> **New project?** Follow the [runbook](runbook.md) (skeleton) for the ordered setup steps.

## Standardized structure (roles to expand)

This shelf follows the same per-language skeleton as the [rust](../../rust/release-workflow-spec/)
and [bash](../../bash/release-workflow-spec/) shelves; each role becomes a chapter as it is filled
in:

| Role                         | Python specifics (to expand)                                              |
| ---------------------------- | ------------------------------------------------------------------------- |
| Branch model + release tool  | `develop`/`master`; release-please (PR gate) or python-semantic-release   |
| Package/artifact metadata    | `pyproject.toml` `[project]`, classifiers, version SoT                    |
| Registry auth                | PyPI Trusted Publishing (OIDC), `id-token: write`                         |
| Release automation config/CI | release-please config / `gh-action-pypi-publish` or `uv publish` workflow |
| Binary/artifact distribution | wheels + sdist (the published artifacts _are_ the dist)                   |
| SemVer / version discipline  | SemVer; version bumped in `pyproject.toml` by the release tool            |
| Per-new-project runbook      | [runbook.md](runbook.md)                                                  |

## Source of truth

The committed version — `pyproject.toml` `[project] version` (or `__version__`) — is the authoring
source of truth, bumped in place by the release tool; the annotated tag mirrors it. See
[Version source of truth](../../../programming/design-decisions/version-source-of-truth.md).

## Recommended tooling

- **Release-PR gate:** [release-please](https://github.com/googleapis/release-please) — Google's
  language-agnostic release-PR bot. It knows the `python` release type (bumps `pyproject.toml` /
  `__version__`) and is the best fit when you want the "merge the release PR" gate.
- **Full-lifecycle push model alternative:**
  [python-semantic-release](https://python-semantic-release.readthedocs.io/en/latest/) —
  conventional commits → bump + changelog + tag + GitHub Release; publishes on push to the default
  branch, not via a release PR.
- **Publish + auth:** [PyPI Trusted Publishing (OIDC)](https://docs.pypi.org/trusted-publishers/)
  via [`pypa/gh-action-pypi-publish`](https://github.com/pypa/gh-action-pypi-publish) — tokenless,
  needs `permissions: id-token: write`. Alternatively `uv build` + `uv publish`, which also supports
  Trusted Publishing.

This mirrors the general release-PR + trusted-publishing model. Related note:
[python-poetry.md](../python-poetry.md) (deps / build).

## To expand

- release-please configuration for the `python` release type.
- The publish workflow YAML (`gh-action-pypi-publish` or `uv publish`).
- Environment protection rules for the publish job.
- Monorepo considerations (multiple packages, per-package release PRs).
