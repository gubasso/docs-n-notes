# Runbook — set up releases for a new Python project (skeleton)

The ordered, **once-per-project** manual steps for a Python package — a **skeleton** mirroring the
[rust runbook](../../rust/release-workflow-spec/runbook.md), to flesh out when a Python project
adopts this. PyPI Trusted Publishing is the analogue of crates.io's, so the shape is nearly
identical.

## Steps (to expand)

1. **Metadata gate.** Fill `pyproject.toml` `[project]` (name, version, description, license,
   classifiers); build locally (`python -m build` or `uv build`) and inspect the wheel + sdist.
2. **Create the repo and set the default branch to `develop`.** →
   [first-run enablement](../../../tools/git/branch-protection/first-run-enablement.md).
3. **Enable Actions + workflow permissions** (release-please opens the release PR; the publish job
   needs `id-token: write`). →
   [first-run enablement](../../../tools/git/branch-protection/first-run-enablement.md).
4. **Apply branch protection** for `develop`/`master`/tags. →
   [branch-protection/](../../../tools/git/branch-protection/).
5. **First manual publish** to PyPI with a scoped, short-lived token (Trusted Publishing attaches to
   an existing project), then configure the PyPI **trusted publisher** (owner/repo + publish
   workflow filename + environment) and revoke the token. →
   [PyPI Trusted Publishers](https://docs.pypi.org/trusted-publishers/).
6. **Add the release automation** (release-please config + `pypa/gh-action-pypi-publish` or
   `uv publish` workflow). Keep the publish workflow filename stable — it is what the PyPI trusted
   publisher matches.
7. **Verify** end-to-end: merge a `feat:` → merge the release PR → tag → PyPI has the version →
   `master` promoted.

## To expand

- The concrete `pyproject.toml` + release-please config + publish workflow YAML.
- Environment protection rules for the publish job; monorepo (multi-package) considerations.
