# 01 — Repository foundation

The three root files every repository needs before anything else: an ignore file, a license, and a
readme. These are language-agnostic; the language binding adds ecosystem-specific ignore patterns
and metadata.

## `.gitignore`

Ignore everything that is generated, secret, or environment-specific so it never enters history:

- **OS / editor cruft** — `.DS_Store`, `Thumbs.db`, swap files, editor-local directories.
- **Secrets / environment** — `.env`, credential files, anything holding a token or key.
- **Build artifacts** — compiled output, caches, dependency directories.
- **Nix artifacts** — `result`, `result-*` symlinks from `nix build`.

Start from the language template at [github/gitignore](https://github.com/github/gitignore) and
prune to what the project actually produces. Syntax reference:
[gitignore](https://git-scm.com/docs/gitignore).

## `LICENSE`

Pick an [SPDX](https://spdx.org/licenses/) identifier and commit the matching license text at the
repo root. A public repo without a license grants no reuse rights, so this is not optional for
anything you intend others to use.

For a repo that mixes prose and code, dual-licensing is a clean pattern — this very repository, for
example, licenses documentation under CC-BY-4.0 and scripts/config under MIT, with each file class
pointing at its license. Choose the model deliberately and state it in the `README`.

## `README` skeleton

The `README.md` is the project index. At a minimum it states: what the project is (one line), how to
build/run it, how to set up the dev environment, and where the deeper docs live. Keep it an index
that routes to detail, not a place that duplicates it — the same
[single-source-of-truth](../docs-design/04-single-source-of-truth.md) rule that governs this shelf.

## Automation

`bootstrap-repo` lays down a language-aware `.gitignore`, an SPDX `LICENSE`, and a `README`
skeleton. The manual steps above are the SoT; the skill accelerates them. See
[07 — Automation with cog](./07-automation-with-cog.md).
