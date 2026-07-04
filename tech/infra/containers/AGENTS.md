---
digest-of: tech/infra/containers
last-synced: 2026-07-04
source-files:
  - README.md
  - docker-devcontainer-cleanup.md
  - docker-dockerfile.md
  - docker-mongodb.md
  - docker-portainer.md
  - docker-secrets.md
  - docker.md
  - kubernetes.md
  - podman-first-dev-containers-workflow-terminal-neovim.md
token-estimate: 9500
---

# AGENTS

## Scope

Container and devcontainer notes covering Docker, Podman, Kubernetes, libkrun, and related cleanup
or troubleshooting material.

## Key Points

- **Docker**: Core Docker usage plus Dockerfile, secrets, MongoDB, and Portainer notes.
- **Podman**: Podman-first devcontainer workflow (Docker-compatible socket, `devcontainer` CLI).
- **Kubernetes**: Container-orchestration reference material.
- **Troubleshooting**: Docker/devcontainer cleanup guidance.
- **microVM isolation** (libkrun / `crun --krun`) now lives in the sibling
  `tech/infra/sandbox-isolation-backends/` shelf, not here.

## Source Map

| Topic                                 | File                                                      |
| ------------------------------------- | --------------------------------------------------------- |
| General container overview            | `README.md`                                               |
| Docker workflows and Dockerfile notes | `docker.md`, `docker-dockerfile.md`                       |
| Docker cleanup and secrets            | `docker-devcontainer-cleanup.md`, `docker-secrets.md`     |
| Docker service/app examples           | `docker-mongodb.md`, `docker-portainer.md`                |
| Kubernetes reference                  | `kubernetes.md`                                           |
| Podman devcontainer workflow          | `podman-first-dev-containers-workflow-terminal-neovim.md` |

## Maintenance Notes

- Keep the README index aligned with the current markdown notes.
- This digest covers only the Markdown guidance files in the directory.
- 2026-07-04: `podman-libkrun.md` and `libkrun-crun-newline-mangling-upstream-issue.md` were
  migrated into the vendor-neutral `tech/infra/sandbox-isolation-backends/` shelf and removed from
  this directory; recompute `token-estimate` on the next regeneration.
