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
- [libkrun-crun-newline-mangling-upstream-issue](libkrun-crun-newline-mangling-upstream-issue.md) —
  upstream bug writeup: `podman --runtime krun` mangles newlines in `sh -c` payloads
- [podman-first-dev-containers-workflow-terminal-neovim](podman-first-dev-containers-workflow-terminal-neovim.md)
  — terminal + Neovim dev-container workflow built on Podman
- [podman-libkrun](podman-libkrun.md) — rootless Podman + libkrun (`crun --krun`) on Arch: what
  works and known issues
