# Containers

Container and devcontainer notes.

- [docker](docker.md) — general Docker reference: env vars, commands, Compose, networking, storage
- [docker-devcontainer-cleanup](docker-devcontainer-cleanup.md) — operator guide for reclaiming disk
  and removing legacy Docker/BuildKit/devcontainer state
- [docker-dockerfile](docker-dockerfile.md) — Dockerfile naming conventions and multi-Dockerfile
  directory layout
- [docker-mongodb](docker-mongodb.md) — running a MongoDB database in Docker
- [docker-portainer](docker-portainer.md) — Portainer container-management UI notes
- [docker-secrets](docker-secrets.md) — using Docker secrets in Compose services
- [kubernetes](kubernetes.md) — Kubernetes general notes
- [podman-first-dev-containers-workflow-terminal-neovim](podman-first-dev-containers-workflow-terminal-neovim.md)
  — terminal + Neovim dev-container workflow built on Podman

See also: [../sandbox-isolation-backends/](../sandbox-isolation-backends/README.md) — the canonical
reference for KVM-class microVM isolation (libkrun / `crun --krun`), including the rootless
podman+krun operational notes and the `\n`-mangling bug that previously lived here.
