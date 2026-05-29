---
digest-of: tech/infra/containers
last-synced: 2026-05-28
source-files:
  - README.md
  - docker-devcontainer-cleanup.md
  - docker-dockerfile.md
  - docker-mongodb.md
  - docker-portainer.md
  - docker-secrets.md
  - docker.md
  - kubernetes.md
  - libkrun-crun-newline-mangling-upstream-issue.md
  - podman-first-dev-containers-workflow-terminal-neovim.md
  - podman-libkrun.md
token-estimate: 12700
---

# AGENTS

## Scope

Container and devcontainer notes covering Docker, Podman, Kubernetes, libkrun, and related cleanup
or troubleshooting material.

## Key Points

- **Docker**: Core Docker usage plus Dockerfile, secrets, MongoDB, and Portainer notes.
- **Podman**: Podman-first devcontainer workflows and libkrun integration notes.
- **Kubernetes**: Container-orchestration reference material.
- **Troubleshooting**: libkrun newline-mangling issue and devcontainer cleanup guidance.

## Source Map

| Topic                                 | File                                                                   |
| ------------------------------------- | ---------------------------------------------------------------------- |
| General container overview            | `README.md`                                                            |
| Docker workflows and Dockerfile notes | `docker.md`, `docker-dockerfile.md`                                    |
| Docker cleanup and secrets            | `docker-devcontainer-cleanup.md`, `docker-secrets.md`                  |
| Docker service/app examples           | `docker-mongodb.md`, `docker-portainer.md`                             |
| Kubernetes reference                  | `kubernetes.md`                                                        |
| libkrun issue and integration notes   | `libkrun-crun-newline-mangling-upstream-issue.md`, `podman-libkrun.md` |
| Podman devcontainer workflow          | `podman-first-dev-containers-workflow-terminal-neovim.md`              |

## Maintenance Notes

- Keep the README index aligned with the current markdown notes.
- This digest covers only the Markdown guidance files in the directory.
