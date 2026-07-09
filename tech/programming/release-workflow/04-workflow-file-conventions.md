# 04 — Workflow file conventions

Two independent CI concerns often coexist on one repo, and confusing them silently breaks releases:

1. **The release / publish workflow** — opens the release PR, tags the version, publishes source to
   the registry over OIDC, and promotes `master` ([01](./01-release-automation.md),
   [02](./02-trusted-publishing-oidc.md)).
2. **The binary-distribution workflow** — builds prebuilt binaries + installers on the release tag
   and attaches them to the GitHub Release ([03](./03-tooling-by-ecosystem.md)).

Keep them in **separate workflow files**. They run on different triggers, own different artifacts,
and — for tools that generate their own YAML — regenerate independently.

## Why the filename matters

Trusted Publishing matches on repository **owner + repo + workflow _filename_** (+ optional
environment), and is branch-agnostic ([02](./02-trusted-publishing-oidc.md)). The registry
authorizes the _exact file_ that performs the OIDC publish. So the trusted-publisher config must
name the **publish** workflow's filename — never the binary-distribution one, which does not publish
to the registry at all (it authenticates to the Release with the platform's own `GITHUB_TOKEN`).

## The collision to avoid

Binary-distribution generators pick a generic default name. **cargo-dist generates
`.github/workflows/release.yml`.** If the _publish_ workflow is also called `release.yml`, the two
collide on one filename — and, worse, you may register `release.yml` with the registry and end up
pointing the trusted publisher at the binary-build workflow, so every OIDC publish is rejected.

## The convention

- Name the **publish** workflow for the tool that performs it, e.g. `release-plz.yml` (Rust),
  `release.yml` only when nothing else claims it.
- Let the **binary-distribution** tool keep its own default filename (cargo-dist → `release.yml`).
- Register the **publish** workflow's filename with the registry's trusted publisher.

| Concern                        | Rust file         | Registered with registry?   | Auth                              |
| ------------------------------ | ----------------- | --------------------------- | --------------------------------- |
| Release PR + publish + promote | `release-plz.yml` | **Yes** (trusted publisher) | crates.io OIDC (id-token)         |
| Prebuilt binaries + installers | `release.yml`     | No                          | Release upload via `GITHUB_TOKEN` |

## The manual-tag case (no registry)

When there is no registry — a human pushes a signed `v*` tag and CI cuts a GitHub Release (the Bash
model, [03](./03-tooling-by-ecosystem.md)) — a single `release.yml` does the whole job and there is
no trusted publisher to point anywhere, so no collision arises. The convention only bites once a
registry publish and a separate binary-dist generator share a repo.

## Reference

- [crates.io — Trusted Publishing](https://crates.io/docs/trusted-publishing)
- [cargo-dist / `dist`](https://github.com/axodotdev/cargo-dist)
