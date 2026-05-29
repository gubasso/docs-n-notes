# cargo-release Setup

Set up `cargo-release`, crate metadata, and first-publish prerequisites for crates.io.

Related docs:

- [workflow](../../tools/git/branch-protection/workflow.md)
- [github-actions-ci-cd](../../infra/devops/github-actions-ci-cd.md)

---

## Cargo.toml Metadata

Set required crates.io fields in `Cargo.toml`:

```toml
[package]
name = "my-crate"
version = "0.1.0"
edition = "2021"
description = "Short crate description"
license = "MIT"
repository = "https://github.com/<owner>/<repo>"
```

Use `license-file` instead of `license` if needed:

```toml
[package]
license-file = "LICENSE"
```

## LICENSE File

Add an MIT license file, or set `license-file` in `Cargo.toml`.

## release.toml

Set `release.toml`:

```toml
pre-release-commit-message = "chore(release): bump version to {{version}}"
tag-name = "v{{version}}"
publish = true
push = true
```

## First Publish (Manual)

1. Create a crates.io account.
2. Generate an API token named `github-actions-<project>` with scope `publish-update`.
3. Log in locally.

```bash
cargo login
```

1. Dry run the publish.

```bash
cargo publish --dry-run
```

1. Publish the crate.

```bash
cargo publish
```

First publish cannot be automated.

## Automated Releases

Follow [github-actions-ci-cd](../../infra/devops/github-actions-ci-cd.md).

Set `CARGO_REGISTRY_TOKEN` in GitHub:

`Settings -> Secrets -> Actions -> New repository secret`
