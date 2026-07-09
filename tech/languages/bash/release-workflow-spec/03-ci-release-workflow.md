# Bash Release — CI Release Workflow

Part of the [bash release-workflow spec](./README.md). General principle: **release automation** —
see the [general principles](../../../programming/release-workflow/README.md).

`.github/workflows/release.yml` — trigger on `v*` tag push:

```yaml
on:
  push:
    tags: ['v*']

permissions:
  contents: write        # for gh release create
  id-token: write        # for SLSA provenance / Sigstore OIDC
  attestations: write    # for GitHub Artifact Attestations

jobs:
  test:
    uses: ./.github/workflows/ci.yml  # shellcheck, shfmt, bats

  release:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # git-cliff needs full history

      - run: make dist

      - uses: orhun/git-cliff-action@v4
        with:
          args: --latest --strip header
        # writes release_notes.md

      - uses: actions/attest-build-provenance@v2
        with:
          subject-path: '<tool>-*.tar.gz'

      - run: |
          gh release create "${GITHUB_REF_NAME}" \
            --title "${GITHUB_REF_NAME}" \
            --notes-file release_notes.md \
            <tool>-*.tar.gz <tool>-*.tar.gz.sha256
        env:
          GH_TOKEN: ${{ github.token }}

      - name: Trigger OBS service run
        env:
          OBS_TOKEN: ${{ secrets.OBS_TOKEN }}
        run: |
          curl --fail-with-body -X POST \
            -H "Authorization: Token ${OBS_TOKEN}" \
            "https://api.opensuse.org/trigger/runservice?project=home:<user>:<tool>&package=<tool>"

  # master is written only by CI: fast-forward it onto the release tag.
  promote:
    needs: release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Fast-forward master onto the release tag
        run: |
          git config user.name  "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          tag="${GITHUB_REF_NAME}"
          git fetch origin --tags
          git fetch origin develop
          tag_sha="$(git rev-parse "refs/tags/${tag}^{commit}")"
          # Guard: the tagged commit must be reachable from develop.
          if ! git merge-base --is-ancestor "$tag_sha" origin/develop; then
            echo "::error::tag $tag ($tag_sha) is not on develop; refusing to promote master." >&2
            exit 1
          fi
          if git rev-parse --verify --quiet origin/master >/dev/null; then
            git checkout -B master origin/master
            git merge --ff-only "$tag_sha"
          else
            git checkout -B master "$tag_sha"   # first release: create master at the tag
          fi
          git push origin master
```

The OBS trigger uses a per-package scoped token (see the OBS chapter) — endpoint on
`api.opensuse.org`, literal header `Authorization: Token`, never `Bearer`. `--fail-with-body`
surfaces OBS errors so the Action doesn't silently succeed when OBS rejects the request.

**`master` is written only by CI.** The maintainer cuts the signed tag on `develop` (the release
ritual, [06](./06-release-ritual-and-alternatives.md)); the human-pushed tag triggers this workflow,
and the `promote` job fast-forwards `master` onto that tag — ancestry-checked against `develop`,
`--ff-only`, no force. A human never writes to `master`; it always mirrors the latest released tag.
If `master` is a protected branch, keep `github-actions[bot]` in the ruleset bypass list (see
[branch-protection/](../../../tools/git/branch-protection/)).

**Use GitHub's built-in
[`actions/attest-build-provenance`](https://github.com/actions/attest-build-provenance) rather than
rolling your own cosign workflow** — free for public repos, generates SLSA L3 provenance, and signs
through the Sigstore public-good instance keylessly via GitHub's OIDC token. One step, no key
management. Users verify with `gh attestation verify`.
