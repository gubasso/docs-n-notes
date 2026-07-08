# 00 — Branch model & release-plz

General counterparts: [branch model](../../../programming/release-workflow/00-branch-model.md) ·
[release automation](../../../programming/release-workflow/01-release-automation.md).

[release-plz](https://release-plz.dev/) is the Rust implementation of the release-PR invariant: it
watches `develop`, opens a release PR (version bump from Conventional Commits, changelog via
git-cliff, `cargo-semver-checks` for libraries), and on merge tags every package and runs
`cargo publish`. This chapter wires it onto the `develop`/`master` model, with `master` promoted
onto the **release tag**.

## release-plz on `develop`

release-plz auto-detects the default branch, so point CI at `develop` and set the GitHub repo's
default branch to `develop`. No branch key is needed in `release-plz.toml`:

```toml
# release-plz.toml — runs on the default branch (develop); no branch key needed.
[workspace]
changelog_update = true   # maintain CHANGELOG.md from Conventional Commits
release_always   = false  # release only when there is something to release
publish          = true   # publish to crates.io on release-PR merge
semver_check     = true   # gate public-API compatibility (libraries)
```

The CI workflow triggers on `develop`, grants `id-token: write`, and runs the release-plz action —
which mints and exchanges the crates.io OIDC token itself, so there is **no `CARGO_REGISTRY_TOKEN`**
and no separate auth action:

```yaml
name: release-plz
on:
  push:
    branches: [develop]

permissions:
  contents: write
  pull-requests: write
  id-token: write

jobs:
  release-plz:
    if: github.repository_owner == '<owner>'
    runs-on: ubuntu-latest
    # Expose whether a release was cut, and its JSON, so `promote` can
    # fast-forward master onto the exact release tag.
    outputs:
      releases_created: ${{ steps.release-plz.outputs.releases_created }}
      releases: ${{ steps.release-plz.outputs.releases }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - id: release-plz
        uses: release-plz/action@v0.5
        with:
          command: release-plz
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Promoting `master` onto the release tag (the official way)

release-plz creates the tag `vX.Y.Z` (default `git_tag_name = "v{{ version }}"` for a single crate).
Promote `master` onto **that tag** — the canonical marker of what was published — not onto the
workflow's trigger SHA.

Because a tag pushed by release-plz with the default `GITHUB_TOKEN` does **not** retrigger other
workflows, a standalone `on: push: tags` promote job would never fire. So run promotion as a
**`needs:` job in the same run**, read the tag from release-plz's `releases` output, ancestry-check
it, and fast-forward:

```yaml
  promote:
    needs: release-plz
    if: github.repository_owner == '<owner>' && needs.release-plz.outputs.releases_created == 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Fast-forward master to the release tag
        env:
          RELEASES: ${{ needs.release-plz.outputs.releases }}
        run: |
          git config user.name  "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

          # The tag release-plz just created is the canonical release marker.
          tag="$(printf '%s' "$RELEASES" | jq -r '.[0].tag')"
          if [ -z "$tag" ] || [ "$tag" = "null" ]; then
            echo "::error::could not determine the release tag from release-plz output." >&2
            exit 1
          fi

          git fetch origin --tags
          git fetch origin develop
          tag_sha="$(git rev-parse "refs/tags/${tag}^{commit}")"

          # Guard: the tagged commit must be on develop.
          if ! git merge-base --is-ancestor "$tag_sha" origin/develop; then
            echo "::error::tag $tag ($tag_sha) is not on develop; refusing to promote master." >&2
            exit 1
          fi

          if git rev-parse --verify --quiet origin/master >/dev/null; then
            git checkout -B master origin/master
            git merge --ff-only "$tag_sha"
          else
            # First release: master does not exist yet — create it at the tag.
            git checkout -B master "$tag_sha"
          fi
          git push origin master
```

### If `master` is a protected branch

Once `master` sits behind a ruleset (no human writes, linear history), the promotion push needs a
bypass actor. Either keep `github-actions[bot]` in the ruleset's bypass list, or — if `master` needs
its own CI on promotion — mint a GitHub App token (`actions/create-github-app-token`) for
release-plz so its tag push _does_ retrigger a standalone `release-promote.yml`. See
[branch-protection/](../../../tools/git/branch-protection/) for the ruleset setup.

## The full release flow

> **You never hand-create the tag.** release-plz creates `vX.Y.Z` when its release PR merges. The
> only manual actions are two merges — feature work into `develop`, then the release PR. Everything
> after the second merge (tag, `cargo publish`, `master` promotion) is automated.

```text
merge feature branch ─▶ develop        (you)
                          │
                          ▼
        release-plz opens the "release PR"     (auto: version bump + changelog)
                          │
                          ▼
              merge the release PR      (you ← the only release decision)
                          │
                          ▼
   tag vX.Y.Z + cargo publish over OIDC        (auto: release-plz)
                          │
                          ▼
     promote job fast-forwards master ─▶ vX.Y.Z    (auto: needs release-plz)
```

1. Merge feature work to `develop`. Commits must be
   [Conventional Commits](https://www.conventionalcommits.org/) — release-plz reads them to choose
   the bump and write the changelog.
1. release-plz opens/updates the release PR on `develop` (version bump in
   `Cargo.toml`/`Cargo.lock` + `CHANGELOG.md`).
1. Review and merge the release PR — the release gate, the one human decision.
1. release-plz tags `vX.Y.Z` and publishes to crates.io over OIDC (no stored token).
1. The `promote` job (`needs: release-plz`) fast-forwards `master` onto the tag.

### Worked example

A crate at `0.1.0` (`develop` and `master` both on the `0.1.0` commit). Two feature branches merge
into `develop`:

```text
feat: add --json output flag
fix: skip empty archives
```

The `feat:` outranks the `fix:`, so release-plz proposes a **minor** bump `0.1.0 → 0.2.0` and opens
a PR `chore: release <crate> 0.2.0` (version bump + `CHANGELOG.md`). Merging it triggers the rest:

```text
before                         after merging the release PR

develop  ● 0.1.0               develop  ●── 0.1.0
master   ● 0.1.0                          ╲
                                           ●── feat/fix commits
                                            ╲
                                             ● 0.2.0  ◀─ tag v0.2.0  (release-plz)
                                                      └▶ cargo publish 0.2.0 (OIDC)
                               master   ●───────────▶ ● 0.2.0  (promote: --ff-only)
```

`master` now points at exactly the commit tagged `v0.2.0` and published — linear, no drift. The next
release repeats from `develop`.

## Local alternative

`cargo-release` is the imperative, no-bot local alternative (`cargo release patch --execute`); it
still needs [configured auth](02-api-tokens-and-scopes.md). Prefer release-plz for CI-first
releases. See [`04 — release-plz config`](04-release-plz-config.md).

## Reference

- [release-plz — docs](https://release-plz.dev/) ·
  [config reference](https://release-plz.dev/docs/config)
- [release-plz/action outputs](https://github.com/release-plz/action)
