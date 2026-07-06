# 08 — Binary distribution (cargo-dist)

Publishing to crates.io ships **source** — users run `cargo install` or add a dependency and build
it themselves. If you also want to hand out **prebuilt binaries and installers**, that is a separate
concern handled by `dist` (cargo-dist). It is orthogonal to registry publishing: a crate can do
either, both, or neither.

## What it does

`dist` builds release artifacts for multiple targets and attaches them to a GitHub Release, along
with shell/PowerShell installer scripts. It generates its own CI workflow from a config file so a
tag push produces the binaries automatically.

## Configuration — `dist-workspace.toml`

```toml
[workspace]
members = ["cargo:."]

[dist]
ci = "github"
installers = ["shell", "powershell"]
targets = [
  "x86_64-unknown-linux-gnu",
  "x86_64-apple-darwin",
  "aarch64-apple-darwin",
  "x86_64-pc-windows-msvc",
]
```

## The generated workflow is an artifact — regenerate, don't hand-edit

`dist` produces its release workflow (e.g. `.github/workflows/release-dist.yml`) from the config.
Treat that file as generated: change `dist-workspace.toml`, then regenerate rather than editing the
YAML by hand:

```bash
dist init       # first-time setup / interactive config
dist generate   # regenerate CI workflow after config changes
```

## Relationship to crates.io publishing

- **crates.io / release-plz** — source distribution to the registry
  ([05](05-release-plz-automation.md)). Auth = [OIDC](04-trusted-publishing-oidc.md).
- **dist** — binary distribution to GitHub Releases. Auth = the workflow's `GITHUB_TOKEN`.

They run independently. Keep the crates.io release workflow and the dist workflow as separate files
so neither regeneration nor a registry change disturbs the other.

## Reference

- [cargo-dist / `dist`](https://github.com/axodotdev/cargo-dist)
