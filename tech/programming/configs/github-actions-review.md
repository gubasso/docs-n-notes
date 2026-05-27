# GitHub Actions — Review Guide

## When to load

`.github/workflows/*.yml`, `action.yml` files.

## Top review heuristics

### Security

- `pull_request_target` trigger with checkout of untrusted code → `[blocking]` "Code execution from
  forks."
- `${{ github.event.pull_request.head.ref }}` interpolated into a `run` step → `[blocking]` "Script
  injection."
- Secrets passed to action steps that print them → `[blocking]`.
- `permissions:` missing or `write-all` → `[important]` "Principle of least privilege."
- Third-party actions referenced by tag instead of full SHA → `[important]` "Tags can be re-pointed;
  pin SHA."

### Versioning

- Action pinned to a branch (`uses: org/action@main`) → `[blocking]`.
- Tool version not pinned (e.g., `setup-node` with no `node-version`) → `[important]` "Builds drift
  when GH updates defaults."

### Triggers

- `push` and `pull_request` both triggering the same workflow without dedup → `[important]`.
- Schedule trigger with no `concurrency` → `[important]` "Long-running schedules can overlap."
- `workflow_dispatch` without explicit input declarations → `[suggestion]`.

### Job structure

- Steps duplicated across multiple jobs that should be a reusable workflow → `[suggestion]`.
- Long-running job with no timeout (`timeout-minutes`) → `[important]`.
- Matrix strategy without `fail-fast: false` when partial-failure is informative → `[suggestion]`.
- `continue-on-error: true` masking a real failure → `[blocking]`.

### Caching

- No cache for `npm`/`pip`/`cargo`/etc. on each job → `[important]` "Wastes CI minutes."
- Cache key not including the lockfile hash → `[blocking]` "Stale cache used."

### Common bugs

- `if: github.ref == 'main'` (incorrect; should be `'refs/heads/main'`) → `[blocking]`.
- `secrets.GITHUB_TOKEN` used where `secrets.MY_PAT` is needed (or vice versa) → `[important]`.
- Job depending on another job's outputs without declared `outputs:` → `[blocking]`.
- Conditional step relying on an env var set in a previous step (must use `$GITHUB_ENV`, not inline
  `export`) → `[blocking]`.

### Output / logging

- Secret values exposed via `echo` without `::add-mask::` → `[blocking]`.
- Step outputs containing newlines without proper escaping → `[important]`.

## See also

- actionlint: <https://github.com/rhysd/actionlint/blob/main/docs/checks.md>.
- GitHub Actions hardening:
  <https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions>.
