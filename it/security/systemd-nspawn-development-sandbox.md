# Isolated AI Dev Environment with `systemd-nspawn` (`dev-sandbox`)

> Note: all examples here assume the **host terminal is kitty** (so `TERM=xterm-kitty`).
> If you use a different terminal emulator, you may need to adjust `TERM`/terminfo and color-related steps.

---

## TL;DR (Very Short, Practical Steps)

- Create rootfs for `dev-sandbox` at `/var/lib/machines/dev-sandbox`:
  - Arch:
    - `sudo mkdir -p /var/lib/machines/dev-sandbox`
    - `sudo pacstrap -c /var/lib/machines/dev-sandbox base base-devel git neovim kitty-terminfo`
  - openSUSE Tumbleweed:
    - `ROOT=/var/lib/machines/dev-sandbox`
    - `sudo mkdir -p "$ROOT"`
    - Add repos into `$ROOT`:
      - `sudo zypper --root "$ROOT" addrepo -f https://download.opensuse.org/tumbleweed/repo/oss/      repo-oss`
      - `sudo zypper --root "$ROOT" addrepo -f https://download.opensuse.org/tumbleweed/repo/non-oss/  repo-non-oss`
      - `sudo zypper --root "$ROOT" addrepo -f https://download.opensuse.org/update/tumbleweed/        repo-update`
    - `sudo zypper --root "$ROOT" refresh`
    - Install base patterns:
      - `sudo zypper --root "$ROOT" --non-interactive install --type pattern base enhanced_base devel_basis`
    - Optionally:
      - `sudo zypper --root "$ROOT" install git neovim kitty-terminfo`
- Ensure `/var/lib/machines/dev-sandbox/usr/lib/os-release` exists (copy from host if needed).
- Enter container as root:
  `sudo systemd-nspawn -D /var/lib/machines/dev-sandbox /bin/bash`
- Inside container (as root):
  - `useradd -m -s /bin/bash dev && passwd dev`
  - `mkdir -p /workspace && chown dev:dev /workspace`
  - Install tooling:
    - Arch: `pacman -Syu --noconfirm && pacman -S --noconfirm nodejs npm git curl`
    - openSUSE: `zypper refresh && zypper install -y nodejs npm git curl`
  - Install and set **fish** as the interactive shell for `dev` (optional but recommended if you use fish on host):
    - Arch: `pacman -S --noconfirm fish`
    - openSUSE: `zypper install -y fish`
    - `chsh -s /usr/bin/fish dev`
- On host, put projects under `~/Projects/<project>`.
- Create wrapper script `~/bin/dev-sandbox` that:
  - Takes a project path (or uses `$PWD`)
  - Bind-mounts it to `/workspace/<project>`
  - Runs `systemd-nspawn -M dev-sandbox -D /var/lib/machines/dev-sandbox --user=dev ...`
- In a project:
  - Create `.env.ai` (add to `.gitignore`) with API keys.
  - Inside container:
    - `npm init -y`
    - `npm install --save-dev <ai-cli-packages>`
    - Define `ai-env` helper to load `.env.ai` and run commands: `ai-env npx <cli>`
- Daily:
  - Host: edit with Neovim in `~/Projects/<project>`.
  - Host: `dev-sandbox` in that directory.
  - Container: `cd /workspace/<project>` and run `ai-env npx ...` for AI CLIs.

---

## Table of Contents

- [Overview](#overview)
- [Preparing the Base Root Filesystem](#preparing-the-base-root-filesystem)
  - [Arch Linux: Rootfs via pacstrap](#arch-linux-rootfs-via-pacstrap)
  - [openSUSE Tumbleweed: Rootfs via zypper --root](#opensuse-tumbleweed-rootfs-via-zypper---root)
  - [Sanity Check with a Temporary Shell](#sanity-check-with-a-temporary-shell)
- [Creating and Configuring the Container](#creating-and-configuring-the-container)
  - [Creating the dev User and Workspace](#creating-the-dev-user-and-workspace)
  - [Basic systemd-nspawn Command with Bind Mounts](#basic-systemd-nspawn-command-with-bind-mounts)
  - [Optional .nspawn File for Defaults](#optional-nspawn-file-for-defaults)
- [Installing AI Tooling Inside the Container](#installing-ai-tooling-inside-the-container)
  - [Installing Base Tooling (Node, npm, etc.)](#installing-base-tooling-node-npm-etc)
  - [Installing AI CLIs (Shared vs Per-Project)](#installing-ai-clis-shared-vs-per-project)
- [Managing API Keys and Secrets](#managing-api-keys-and-secrets)
  - [Per-Project .env.ai Files](#per-project-envai-files)
  - [Helper Function to Load Env in the Container](#helper-function-to-load-env-in-the-container)
  - [Keeping Secrets out of Host-Global Configs](#keeping-secrets-out-of-host-global-configs)
- [Daily Workflow with dev-sandbox](#daily-workflow-with-dev-sandbox)
  - [Typical Workflow for a Single Project](#typical-workflow-for-a-single-project)
  - [Wrapper Script dev-sandbox](#wrapper-script-dev-sandbox)
- [Security Considerations and Best Practices](#security-considerations-and-best-practices)
  - [Why SSH Keys and Host Secrets Are Protected](#why-ssh-keys-and-host-secrets-are-protected)
  - [Things to Avoid](#things-to-avoid)
  - [Optional Hardening Ideas](#optional-hardening-ideas)
- [Recap](#recap)

---

## Overview

Goal: provide an isolated development environment for AI coding CLIs using `systemd-nspawn`, where:

- Projects live under `~/Projects/<project>`.
- The container root filesystem lives at `/var/lib/machines/dev-sandbox`.
- The container (machine name) is `dev-sandbox`.
- AI tools and dependencies are installed inside this container.
- AI CLIs only see:
  - Their minimal container filesystem.
  - The project directories you explicitly bind-mount under `/workspace/<project>`.
- They never see:
  - Your host `$HOME`.
  - `~/.ssh`.
  - Browser profiles.
  - Other host projects, unless explicitly mounted.

You will:

- Use Neovim and fish on the host.
- Enter `dev-sandbox` to run CLIs against `/workspace/<project>`.
- Manage secrets with per-project `.env.ai` files.
- Have examples tailored to **kitty** (`TERM=xterm-kitty`); other terminals may need analogous terminfo/TERM adjustments.

---

## Preparing the Base Root Filesystem

We set up a minimal system at `/var/lib/machines/dev-sandbox`. Commands differ slightly between Arch Linux and openSUSE Tumbleweed.

### Arch Linux: Rootfs via pacstrap

On the host (Arch):

```bash
sudo mkdir -p /var/lib/machines/dev-sandbox

sudo pacstrap -c /var/lib/machines/dev-sandbox base base-devel git neovim kitty-terminfo
````

Ensure `os-release` exists inside the container:

```bash
if [ ! -f /var/lib/machines/dev-sandbox/usr/lib/os-release ] && \
   [ ! -f /var/lib/machines/dev-sandbox/etc/os-release ]; then
  sudo cp /usr/lib/os-release /var/lib/machines/dev-sandbox/usr/lib/os-release
fi
```

### openSUSE Tumbleweed: Rootfs via zypper --root

On the host (openSUSE):

```fish
# Root directory for the dev-sandbox container rootfs
set ROOT /var/lib/machines/dev-sandbox

# Create the base directory for the rootfs (if it does not exist yet)
sudo mkdir -p "$ROOT"

# -------------------------------------------------------------------
# Configure openSUSE Tumbleweed repositories INSIDE the sandbox
# -------------------------------------------------------------------

# Add main OSS repository
sudo zypper --root "$ROOT" addrepo -f \
    https://download.opensuse.org/tumbleweed/repo/oss/ \
    repo-oss

# Add Non-OSS repository
sudo zypper --root "$ROOT" addrepo -f \
    https://download.opensuse.org/tumbleweed/repo/non-oss/ \
    repo-non-oss

# Add update repository
sudo zypper --root "$ROOT" addrepo -f \
    https://download.opensuse.org/update/tumbleweed/ \
    repo-update

# Refresh repo metadata inside the sandbox
sudo zypper --root "$ROOT" refresh

# -------------------------------------------------------------------
# Install base system + development tooling
# -------------------------------------------------------------------

# Install openSUSE patterns that approximate Arch's base + base-devel
sudo zypper --root "$ROOT" \
    --non-interactive \
    install --type pattern base enhanced_base devel_basis

# Extra tools commonly useful inside the dev environment
sudo zypper --root "$ROOT" install git neovim kitty-terminfo

# -------------------------------------------------------------------
# Ensure /etc/os-release exists INSIDE the sandbox
# -------------------------------------------------------------------

sudo mkdir -p "$ROOT/etc"

if not sudo chroot "$ROOT" test -f /etc/os-release
    echo "Installing os-release into dev-sandbox..."
    sudo cp /etc/os-release "$ROOT/etc/os-release"
else
    echo "os-release already present in dev-sandbox, nothing to do."
end
```

### Sanity Check with a Temporary Shell

On either distro:

```bash
sudo systemd-nspawn -D /var/lib/machines/dev-sandbox /bin/bash
```

If you get a shell prompt inside the container, the base system is functional. Exit:

```bash
exit
```

---

## Creating and Configuring the Container

### Creating the dev User and Workspace

Enter the container as root:

```bash
sudo systemd-nspawn -D /var/lib/machines/dev-sandbox /bin/bash
```

Inside the container:

```bash
useradd -m -s /bin/bash dev
passwd dev

mkdir -p /workspace
chown dev:dev /workspace

exit
```

The container now has:

* User `dev` with home `/home/dev`.
* A workspace directory `/workspace` owned by `dev`.

### Basic systemd-nspawn Command with Bind Mounts

On the host, assume you have a project:

```bash
mkdir -p ~/Projects/my-project
```

To work on it inside `dev-sandbox`:

```bash
sudo systemd-nspawn \
  -D /var/lib/machines/dev-sandbox \
  -M dev-sandbox \
  --user=dev \
  --chdir=/workspace/my-project \
  --bind="$HOME/Projects/my-project:/workspace/my-project" \
  /bin/bash
```

Result:

* Host `~/Projects/my-project` appears at `/workspace/my-project` inside the container.
* You run as `dev`, starting in `/workspace/my-project`.
* No other host directories are visible except those explicitly bound.

### Optional .nspawn File for Defaults

To avoid repeating some options, create `/etc/systemd/nspawn/dev-sandbox.nspawn` on the host:

```bash
sudo mkdir -p /etc/systemd/nspawn
sudo tee /etc/systemd/nspawn/dev-sandbox.nspawn >/dev/null <<'EOF'
[Exec]
User=dev
WorkingDirectory=/workspace

[Files]
# Binds are provided dynamically at runtime.

[Network]
Private=no
EOF
```

With this, you can omit `--user=dev` and `--chdir=/workspace` from your `systemd-nspawn` command if you prefer, since they are defaults. You still specify `--bind` when you start the container (or via a wrapper script).

---

## Installing AI Tooling Inside the Container

### Installing Base Tooling (Node, npm, etc.)

Enter the container as root:

```bash
sudo systemd-nspawn -D /var/lib/machines/dev-sandbox /bin/bash
```

Inside the container:

For Arch:

```bash
pacman -Syu --noconfirm
pacman -S --noconfirm nodejs npm git curl
```

For openSUSE Tumbleweed:

```bash
zypper refresh
zypper install -y nodejs npm git curl
```

Optional (inside container): install fish and Neovim if desired, and set fish as interactive shell for `dev`:

```bash
# Arch:
pacman -S --noconfirm fish neovim

# openSUSE:
zypper install -y fish neovim

# Set fish as dev's default shell (inside container as root)
chsh -s /usr/bin/fish dev
```

Exit the container:

```bash
exit
```

### Installing AI CLIs (Shared vs Per-Project)

Two practical patterns:

#### Shared CLIs under dev’s home

Install once, available for all projects.

Enter as `dev`:

```bash
sudo systemd-nspawn -D /var/lib/machines/dev-sandbox --user=dev /bin/bash
```

Inside the container as `dev`:

```bash
mkdir -p "$HOME/.local/npm"
npm config set prefix "$HOME/.local/npm"

echo 'export PATH="$HOME/.local/npm/bin:$PATH"' >> ~/.bashrc

# Restart the shell or source ~/.bashrc, then:
# npm install -g <openai-cli-package> <claude-cli-package> <gemini-cli-package>
npm install -g @openai/codex @google/gemini-cli
```

Now these CLIs are available anywhere inside the container.

#### Per-project local installs

After bind-mounting a project, inside container as `dev`:

```bash
cd /workspace/my-project

npm init -y
npm install --save-dev <openai-cli-package> <claude-cli-package> <gemini-cli-package>
```

You can then:

```bash
npx <cli-name> ...
# Or define scripts in package.json and run:
npm run ai:codex
```

For AI workflows tightly coupled to specific projects, per-project installs are often better: versions are tracked in `package.json` and `package-lock.json`, and you get reproducible environments per repo.

---

## Managing API Keys and Secrets

### Per-Project .env.ai Files

On the host:

```bash
mkdir -p ~/Projects/my-project
cd ~/Projects/my-project

touch .env.ai
echo ".env.ai" >> .gitignore
```

Edit `.env.ai`:

```ini
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=...
GOOGLE_API_KEY=...
```

This file:

* Lives in `~/Projects/my-project` on the host.
* Becomes `/workspace/my-project/.env.ai` inside the container.
* Is ignored by git.

You can keep one `.env.ai` per project, with only the keys that project needs.

### Helper Function to Load Env in the Container

Inside the container, as `dev`, add a helper to your shell config.

For bash:

```bash
# in ~/.bashrc (inside container)

ai-env() {
  # Usage: ai-env <command> [arguments...]
  if [ -f .env.ai ]; then
    set -a
    . ./.env.ai
    set +a
  fi
  "$@"
}
```

Then, from `/workspace/my-project`:

```bash
ai-env npx openai-codex --help
ai-env npx claude ...
ai-env npm run ai:codex
```

Only commands run via `ai-env` see the variables from `.env.ai`.

You can implement an equivalent function in fish inside the container if you prefer that shell there.

### Keeping Secrets out of Host-Global Configs

Avoid:

* Exporting API keys in host-level shell configs (`~/.config/fish/config.fish`, `~/.bashrc`, etc.).
* Using `systemd-nspawn --setenv=OPENAI_API_KEY=...` from the host.

Keep secrets exclusively in per-project `.env.ai` (or similar) files.

---

## Daily Workflow with dev-sandbox

### Typical Workflow for a Single Project

On the host:

```bash
mkdir -p ~/Projects/my-project
cd ~/Projects/my-project
git init         # or git clone <repo-url>

touch .env.ai
echo ".env.ai" >> .gitignore
# Fill .env.ai with project-specific API keys.
```

Open Neovim on the host:

```bash
nvim .
```

In another terminal on the host, start the sandbox for that project using the wrapper script:

```bash
dev-sandbox          # if run inside ~/Projects/my-project
# or
dev-sandbox ~/Projects/my-project
```

Inside the container:

```bash
cd /workspace/my-project

# First-time setup:
npm init -y
npm install --save-dev <ai-cli-packages>

# Daily usage:
ai-env npx openai-codex ...
ai-env npx claude ...
ai-env npx gemini ...
```

You keep your editing environment (fish + Neovim) on the host, and only the AI CLI execution happens in the container.

### Wrapper Script dev-sandbox

On the host, create the script:

```bash
mkdir -p ~/bin
cat > ~/bin/dev-sandbox <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

MACHINE="dev-sandbox"
ROOT="/var/lib/machines/${MACHINE}"

# Check rootfs existence using sudo so permissions do not cause a false negative
if ! sudo test -d "$ROOT"; then
  echo "Error: container rootfs not found at $ROOT" >&2
  exit 1
fi

if [ $# -ge 1 ]; then
  PROJECT_PATH="$1"
else
  PROJECT_PATH="$PWD"
fi

PROJECT_PATH="$(readlink -f "$PROJECT_PATH")"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

if [ ! -d "$PROJECT_PATH" ]; then
  echo "Error: project directory '$PROJECT_PATH' does not exist." >&2
  exit 1
fi

sudo systemd-nspawn \
  -M "$MACHINE" \
  -D "$ROOT" \
  --user=dev \
  --bind="${PROJECT_PATH}:/workspace/${PROJECT_NAME}" \
  /bin/bash -lc "mkdir -p /workspace/${PROJECT_NAME} && cd /workspace/${PROJECT_NAME} && exec bash"
EOF

chmod +x ~/bin/dev-sandbox
```

Ensure `~/bin` is in your host PATH (for example, in fish):

```fish
set -Ux PATH $HOME/bin $PATH
```

Now you can run:

```bash
cd ~/Projects/my-project
dev-sandbox
```

This opens a `dev-sandbox` shell automatically bound to `/workspace/my-project`.

---

## Security Considerations and Best Practices

### Why SSH Keys and Host Secrets Are Protected

Because:

* The container’s rootfs is separate: `/var/lib/machines/dev-sandbox`.
* Inside the container, you only see host paths explicitly bound via `--bind`.
* The workflow never binds:

  * `~` or `/home/<user>`.
  * `~/.ssh`.
  * Browser configs (`~/.mozilla`, `~/.config/chromium`, etc.).
  * Other secret-bearing directories (`~/.aws`, `~/.gnupg`, etc.).

AI CLIs see:

* `/workspace/<project>` (code + project-local `.env.ai`).
* The container’s own `/home/dev`, `/usr`, etc.

They do not see your host SSH keys or browser profiles at all.

### Things to Avoid

* Do not bind-mount your entire home directory:

  ```bash
  # Do NOT do this:
  --bind="$HOME:/home/dev"
  ```

* Do not copy host secret directories into the container.

* Do not store API keys in host-global configs.

* Avoid running CLIs as root inside the container unless absolutely necessary (stay as `dev`).

### Optional Hardening Ideas

If you want more isolation:

* Use `--bind-ro` for binds that do not need to be writable.
* Use `--private-dev` to hide unnecessary device nodes from the container.
* Drop capabilities with `--drop-capability=all` and re-add only what is required.
* Use `--private-network` if you want the container networking to be separate and explicitly controlled.

These are optional; the main isolation comes from:

* Separate rootfs.
* Limited bind mounts.
* Per-project secrets.

---

## Recap

* Projects live under `~/Projects/<project>`.
* A single shared container `dev-sandbox` lives at `/var/lib/machines/dev-sandbox`.
* On Arch:

  * Rootfs via `pacstrap` with `base base-devel git neovim kitty-terminfo`.
* On openSUSE Tumbleweed:

  * Rootfs via `zypper --root` with:

    * Repos `repo-oss`, `repo-non-oss`, `repo-update`.
    * Patterns `base`, `enhanced_base`, `devel_basis`.
    * Extra packages: `git`, `neovim`, `kitty-terminfo`.
* Inside the container:

  * Non-root user `dev`.
  * `/workspace` for mounted projects.
  * Node, npm, and AI CLIs are installed there.
  * fish can be installed and set as `dev`’s default shell to match host shell behavior if desired.
* Host wrapper script `dev-sandbox`:

  * Bind-mounts a project directory into `/workspace/<project>`.
  * Starts a shell as `dev` in that directory.
* API keys:

  * Stored per-project in `.env.ai` under `~/Projects/<project>`.
  * Loaded via `ai-env` helper inside the container when running AI CLIs.
* Result:

  * Neovim + fish stay on the host.
  * AI CLIs run in an isolated container that only sees the project you explicitly mount.
  * `~/.ssh`, browser profiles, and other host secrets remain invisible to the AI tools.
  * Colors and terminal behavior are consistent with kitty by installing `kitty-terminfo` and, if desired, aligning the interactive shell (fish or bash) between host and container.
