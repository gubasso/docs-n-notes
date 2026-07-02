# Development Tools / Workflows

Default project-tooling convention, language-agnostic. Three roles, kept separate — do not collapse
them into one tool.

## The three roles

| Role                    | Canonical choice                                           | Owns                                                      |
| ----------------------- | ---------------------------------------------------------- | --------------------------------------------------------- |
| Environment / toolchain | **Nix flake devShell**                                     | language runtime(s) + system tools, pinned + reproducible |
| Dependency resolver     | the language's native package manager                      | the dependency graph + lockfile                           |
| Task runner             | project-local (`just`, `make`, npm scripts, cargo aliases) | repeatable dev commands                                   |

## Environment manager: Nix flake devShell (canonical)

Per-project environments default to a **Nix flake devShell** for any language. The flake pins the
runtime(s) and system tooling; `flake.lock` makes it reproducible; `.envrc` (`use flake`)
auto-enters it via direnv/nix-direnv. See [nix](../tools/nix/README.md). It is the default for any
language, ahead of ad-hoc version managers ([mise](./mise.md), asdf, pyenv, nvm,
rustup-as-installer).

## Dependency manager: language-native, inside the devShell

The devShell provides the package-manager binary; the package manager still owns dependency
resolution and the lockfile. Nix does **not** replace it by default.

| Language | Dependency manager (runs inside the devShell)                      |
| -------- | ------------------------------------------------------------------ |
| Python   | Poetry — see [python-poetry](../languages/python/python-poetry.md) |
| JS / TS  | npm / pnpm / yarn                                                  |
| Rust     | Cargo                                                              |
| Go       | Go modules                                                         |

Typical Python flow (first-time setup):

```bash
direnv allow           # once per project; hooks the devShell + venv on every cd
poetry install         # create the venv
direnv reload          # pick up the freshly-created venv
```

With direnv hooked (see
[nix — Automatic activation](../tools/nix/02-per-project-devshell.md#automatic-activation-direnv)),
`cd` into the project auto-enters the devShell and activates the Poetry venv — no manual
`eval "$(poetry env activate)"`. That manual step is only for plain `nix develop` without direnv.

Reach for `poetry2nix` / `cargo2nix` only when you want **Nix itself** to build the app from the
lockfile — a bigger change than managing the environment, and it creates a second source of truth
beside the native lockfile.
