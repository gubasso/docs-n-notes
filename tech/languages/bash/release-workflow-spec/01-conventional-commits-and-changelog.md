# Bash Release — Conventional Commits & Changelog

Part of the [bash release-workflow spec](README.md). General principle: **changelog** — see the
[general principles](../../../programming/release-workflow/README.md).

Use [Conventional Commits](https://www.conventionalcommits.org/) and enforce them with a
`commitlint` pre-commit hook.

Generate `CHANGELOG.md` with [git-cliff](https://git-cliff.org/) — a single static Rust binary, no
Node/Python deps, fast on large histories. Config lives in `cliff.toml`; use the Keep-a-Changelog
preset.

**Why git-cliff over release-please:**

- release-please is GitHub/Node-centric and creates "release PRs" that don't fit a Bash project
  well.
- git-cliff runs anywhere, is configured by a single file, and you tag manually when you actually
  want a release.
