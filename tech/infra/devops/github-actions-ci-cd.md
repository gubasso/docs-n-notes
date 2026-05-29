# GitHub Actions CI/CD

GitHub Actions workflows for CI and automated Rust releases.

Related docs:

- [cargo-release-setup](../../languages/rust/cargo-release-setup.md)
- [workflow](../../tools/git/branch-protection/workflow.md)

---

## Workflow Overview

| Workflow       | Trigger                           | Purpose                                                            |
| -------------- | --------------------------------- | ------------------------------------------------------------------ |
| CI             | Push/PR to `develop` and `master` | Run local `pre-commit` hooks in CI                                 |
| Release PR     | `workflow_dispatch`               | Bump version and open a PR to `master`                             |
| Publish & Sync | Push to `master`                  | Publish to crates.io, tag, create release, merge back to `develop` |

## CI

`.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: [develop, master]
  pull_request:
    branches: [develop, master]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: dtolnay/rust-toolchain@stable

      - uses: taiki-e/install-action@nextest

      - uses: taiki-e/install-action@cargo-audit

      - uses: taiki-e/install-action@cargo-deny

      - name: Install taplo
        run: cargo install taplo-cli --locked

      - uses: actions/setup-python@v5
        with:
          python-version: "3.x"

      - uses: pre-commit/action@v3.0.1
        with:
          extra_args: --all-files --hook-stage pre-push
```

## Release PR

`.github/workflows/release-pr.yml`

```yaml
name: Create Release PR

on:
  workflow_dispatch:
    inputs:
      bump:
        description: patch/minor/major/exact
        default: patch
        required: true

permissions:
  contents: write
  pull-requests: write

jobs:
  release-pr:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: develop
          fetch-depth: 0

      - uses: dtolnay/rust-toolchain@stable

      - name: Install cargo-release
        run: cargo install cargo-release --locked

      - name: Get next version
        id: version
        run: |
          VERSION=$(cargo release version "${{ inputs.bump }}" --no-confirm 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1)
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

      - name: Create release branch and bump version
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git checkout -b "release/v${{ steps.version.outputs.version }}"
          cargo release version "${{ inputs.bump }}" --no-confirm --execute
          git add Cargo.toml Cargo.lock
          git commit -m "chore(release): bump version to ${{ steps.version.outputs.version }}"
          git push -u origin "release/v${{ steps.version.outputs.version }}"

      - name: Create PR to master
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh pr create \
            --base master \
            --head "release/v${{ steps.version.outputs.version }}" \
            --title "Release v${{ steps.version.outputs.version }}" \
            --body "Automated release PR."
```

## Publish & Sync

`.github/workflows/publish.yml`

```yaml
name: Publish & Sync

on:
  push:
    branches: [master]

permissions:
  contents: write

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: dtolnay/rust-toolchain@stable

      - name: Install cargo-nextest
        run: cargo install cargo-nextest --locked

      - name: Run checks
        run: make check

      - name: Extract version
        id: version
        run: |
          VERSION=$(grep '^version = ' Cargo.toml | head -1 | cut -d'"' -f2)
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

      - name: Publish crate
        env:
          CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN }}
        run: cargo publish

      - name: Tag and create GitHub release
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          git tag "v${{ steps.version.outputs.version }}"
          git push origin "v${{ steps.version.outputs.version }}"
          gh release create "v${{ steps.version.outputs.version }}" --generate-notes

      - name: Merge master back into develop
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git fetch origin develop
          git checkout develop
          git merge master --no-edit
          git push origin develop
```

## Secrets

| Secret                 | Source                      | Notes                   |
| ---------------------- | --------------------------- | ----------------------- |
| `CARGO_REGISTRY_TOKEN` | `crates.io/settings/tokens` | Scope: `publish-update` |
| `GITHUB_TOKEN`         | Built-in                    | No setup needed         |

## Setup Order

1. Add the three workflow files under `.github/workflows/`.
2. Push to `develop` to trigger CI at least once.
3. Set up `master` branch protection. See [workflow](../../tools/git/branch-protection/workflow.md).
4. Add `CARGO_REGISTRY_TOKEN` to GitHub repository secrets.
