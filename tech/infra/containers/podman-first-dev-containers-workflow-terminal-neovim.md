# Podman-First Dev Containers Workflow (Terminal + Neovim)

## What a “dev container” is

A **development container (dev container)** is a containerized, full-featured dev environment for a
project: it can run the app, hold the toolchain (compilers, linters, CLIs), and support CI/test
automation. ([Containers Dev][1]) The project defines this environment in **`devcontainer.json`**
metadata, which supporting tools use to create/configure the dev environment consistently.
([Containers Dev][2])

## The problems it solves

- **Eliminates “works on my machine”** by pinning OS + system deps + tooling in version control.
  ([Containers Dev][1])
- **Faster onboarding**: clone repo → start container → run the same commands everyone runs.
- **Cleaner host machine**: fewer global runtimes/SDKs installed locally.
- **Closer dev/CI parity**: the same container definition can be used for local dev and automation.
  ([Containers Dev][1])

---

## Mental model: Spec vs implementation

- **Spec truth (portable):** what `devcontainer.json` _means_ (properties, lifecycle, allowed
  locations). ([Containers Dev][3])
- **CLI behavior (reference implementation):** the Dev Container CLI reads `devcontainer.json` and
  creates/configures containers; it supports **single-container** and **Docker Compose**
  multi-container scenarios. ([Containers Dev][4])

---

## One-time setup (Podman-first)

### 1) Install and run Podman

Podman **v5+** is “mostly compatible” with Docker CLI commands (helpful because many tools assume
`docker`). ([Visual Studio Code][5])

### 2) Expose Podman’s Docker-compatible API socket (recommended)

Dev container tooling often relies on Docker-compatible APIs/CLIs. Podman can provide that via a
socket.

**Rootless (typical on Linux):**

```bash
systemctl --user start podman.socket
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
```

Podman’s docs explicitly describe using `DOCKER_HOST` to point Docker-API tools at the Podman
socket. ([Podman Documentation][6])

**Security note:** Podman strongly warns against exposing the API over the network without mutual
TLS; prefer local socket or SSH forwarding. ([Podman Documentation][6])

### 3) Install the Dev Container CLI

The Dev Container CLI is the reference implementation for the spec and provides commands like `up`,
`exec`, `read-configuration`, and `run-user-commands`. ([Containers Dev][4])

---

## Repo setup (once per project)

### 1) Create `.devcontainer/devcontainer.json`

Tools should look for `devcontainer.json` in standard locations—most commonly
`.devcontainer/devcontainer.json`. ([Containers Dev][3])

**Minimal example (single-container):**

```jsonc
// .devcontainer/devcontainer.json
{
  "name": "my-project",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "remoteUser": "vscode",
  "postCreateCommand": "echo 'dev container ready'"
}
```

- `remoteUser` is a standard metadata property used by tooling when connecting/operating in the
  container. ([Containers Dev][2])
- Lifecycle commands (like `postCreateCommand`) are part of the dev container lifecycle model.
  ([Containers Dev][3])

---

## Daily workflow (terminal-first, Neovim on host)

### Step 1) Start/update the dev container

```bash
devcontainer up --workspace-folder .
```

This is the standard “bring the dev environment up” command. ([Visual Studio Code][7])

### Step 2) Edit in Neovim (host), run toolchain inside the container

```bash
devcontainer exec --workspace-folder . bash -lc 'make test'
devcontainer exec --workspace-folder . bash -lc 'pytest -q'
devcontainer exec --workspace-folder . bash -lc 'npm test'
```

The CLI supports executing commands in the running dev container via `devcontainer exec`.
([Visual Studio Code][7])

### Step 3) Debug “what config is actually being applied”

```bash
devcontainer read-configuration --workspace-folder .
```

`read-configuration` is a first-line debugging tool when behavior differs from what you expect.
([Visual Studio Code][7])

### Step 4) Re-run lifecycle user commands when needed

```bash
devcontainer run-user-commands --workspace-folder .
```

This exists specifically to run lifecycle/user commands on demand. ([Visual Studio Code][7])

### Step 5) Stop or tear down

```bash
devcontainer stop --workspace-folder .
# optionally: devcontainer down --workspace-folder .
```

(Exact subcommands vary by install/version, but the CLI is designed to manage the dev container
lifecycle end-to-end.) ([Containers Dev][4])

---

## Multi-container (app + db) with Podman

The reference implementation supports Docker Compose-style multi-container scenarios.
([Containers Dev][4]) If you’re using Podman, note that Podman provides `podman compose`, but it
depends on a compose provider (Docker Compose or Podman Compose). ([Visual Studio Code][5])

---

## Gotchas (Podman-specific)

- **Make Podman look like “Docker enough”**: many dev container workflows assume Docker CLI/API;
  using the Podman socket + `DOCKER_HOST` is the most portable approach. ([Podman Documentation][6])
- **Avoid exposing the Podman API over TCP** unless you understand and configure mutual TLS; prefer
  the local Unix socket or SSH forwarding. ([Podman Documentation][6])
- **Compose workflows** may be the trickiest area: ensure your compose tooling is aligned with what
  your dev container tooling expects. ([Visual Studio Code][5])

[1]: https://containers.dev/?utm_source=chatgpt.com "Development Containers"
[2]: https://containers.dev/implementors/json_reference/ "Dev Container metadata reference"
[3]: https://containers.dev/implementors/spec/ "Development Container Specification"
[4]: https://containers.dev/implementors/reference/ "Reference Implementation"
[5]: https://code.visualstudio.com/remote/advancedcontainers/docker-options "Alternate ways to install Docker"
[6]: https://docs.podman.io/en/latest/markdown/podman-system-service.1.html "podman-system-service — Podman  documentation"
[7]: https://code.visualstudio.com/docs/devcontainers/devcontainer-cli "Dev Container CLI"
