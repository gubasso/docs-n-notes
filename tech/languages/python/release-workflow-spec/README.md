# Python Release Workflow Spec

This is the **Python binding** of the
[general principles](../../../programming/release-workflow/README.md); it is a **stub to be
expanded** when a Python project actually adopts it.

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
