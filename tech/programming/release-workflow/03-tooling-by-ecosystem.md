# 03 — Tooling by ecosystem

The [release-PR invariant](01-release-automation.md) is implemented by a different tool in each
ecosystem. Pick the idiomatic one; they all reduce to "merge the release PR to publish."

## Recommendation matrix

| Ecosystem          | Recommended release-PR tool                                                                                                                                   | Change intent        | Publish / OIDC                                                                  | Binary / artifact distribution                                                         |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **Rust**           | [release-plz](https://release-plz.dev/) (cargo-release = local alt)                                                                                           | Conventional Commits | `cargo publish` + [crates.io Trusted Publishing](02-trusted-publishing-oidc.md) | [cargo-dist](https://github.com/axodotdev/cargo-dist) (prebuilt binaries + installers) |
| **Python**         | [release-please](https://github.com/googleapis/release-please) (PR gate) or [python-semantic-release](https://python-semantic-release.readthedocs.io/) (push) | Conventional Commits | `build` / `uv build` + PyPI Trusted Publishing                                  | wheels + sdist (the published artifacts _are_ the dist)                                |
| **JS / Node**      | [Changesets](https://github.com/changesets/changesets) (+ [changesets/action](https://github.com/changesets/action))                                          | Changeset files      | `npm publish` + npm Trusted Publishing (OIDC)                                   | npm tarball (the registry _is_ the dist)                                               |
| **Cross-language** | [release-please](https://github.com/googleapis/release-please)                                                                                                | Conventional Commits | tags + GitHub Release only — **bring your own publish step**                    | attach artifacts to the GitHub Release                                                 |
| **Go**             | [GoReleaser](https://goreleaser.com/)                                                                                                                         | git tag              | No registry — tag + module proxy + SCM release artifacts                        | GoReleaser (same tool builds + attaches)                                               |
| **Bash**           | git-cliff + manual signed tag                                                                                                                                 | Conventional Commits | No registry — tag + GitHub Release (tarball)                                    | `install.sh` / AUR / OBS(zypper) / Homebrew (downstream)                               |

Each language binding under `tech/languages/*/release-workflow-spec/` documents the concrete tool +
workflow YAML.

Binary/artifact distribution — shipping **prebuilt binaries and installers** — is a concern separate
from registry publishing (which ships source). A crate can do either, both, or neither. When you run
both, keep them in **separate workflow files** and register only the _publish_ file with the
registry's trusted publisher — see
[04 — Workflow file conventions](04-workflow-file-conventions.md).

## How each tool implements the model

- **release-plz** — watches `develop`, opens a release PR (version bump via Conventional Commits +
  changelog via git-cliff, `cargo-semver-checks` for libraries); on merge it tags every package and
  runs `cargo publish`. The most complete Rust option. See the
  [rust binding](../../languages/rust/release-workflow-spec/).
- **release-please** — Google's **language-agnostic** release-PR bot (23+ release types: Node,
  Python, Rust, Go, Java…). Maintains a release PR, tags on merge, creates a GitHub Release. **Key
  divergence:** it stops at the tag/Release and does **not** publish to a registry — you bolt on an
  ecosystem publish step (gated on its `autorelease: tagged`/`published` label). Attractive as a
  single uniform PR/tag layer across a polyglot repo.
- **Changesets** — the JS/monorepo standard. Developers add **changeset files** per PR stating the
  bump + summary; `changesets/action` opens a **"Version Packages"** PR; on merge it versions and
  publishes. Uses explicit intent files instead of Conventional Commits.
- **python-semantic-release** — full-lifecycle but **push-model** (publishes on push to the default
  branch, no release-PR gate). Use release-please instead when you want the merge gate.
- **GoReleaser** — Go has no central registry; the "release" is a git **tag** plus cross-compiled
  artifacts on the GitHub/GitLab Release and the module proxy. Tagging is publishing. This is the
  intentional exception to the registry-publish leg of the model.

## The promotion step (official pattern)

Whichever tool cuts the release, **promote `master` onto the release tag**, not onto a branch tip or
a workflow trigger SHA — the tag is the canonical marker of what was published
([00 — Branch model](00-branch-model.md)).

Two wirings, depending on who creates the tag:

- **Bot creates the tag (release-plz, release-please).** On GitHub, a tag pushed with the default
  `GITHUB_TOKEN` does **not** retrigger workflows, so a standalone `on: push: tags` promote job
  never fires. Run promotion as a **`needs:` job in the same release run**, reading the release
  tool's output to learn the tag, then fast-forward `master` to it. The
  [rust binding](../../languages/rust/release-workflow-spec/) shows this end to end.
- **A human pushes the tag (manual-tag model).** A human's tag push _does_ retrigger, so a separate
  `on: push: tags: ['v*']` **release-promote** workflow is the clean split. See the templates in
  [branch-protection/](../../tools/git/branch-protection/).

Either way the promote job: resolve the tag → verify its commit is an ancestor of `develop` →
`git merge --ff-only` `master` onto the tag → push.

## Reference

- [release-plz](https://release-plz.dev/) ·
  [release-please](https://github.com/googleapis/release-please) ·
  [Changesets](https://github.com/changesets/changesets) · [GoReleaser](https://goreleaser.com/)
