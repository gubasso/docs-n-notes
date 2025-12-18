# Isolated AI Dev Environment with `systemd-nspawn` (`dev-sandbox`)

> Assumptions:
> - Host OS: **openSUSE Tumbleweed**
> - Host terminal: **kitty**
> - Host interactive shell: **fish**
> - AI CLIs are installed **globally inside the container**
> - API keys are **per-project** in `.env.ai` files

---

## Update: Automated wrappers available (recommended)

- Check in: [Isolated AI Dev Environment Automated Wrappers](./isolated-ai-dev-environment-automated-wrappers.md)

---

## TL;DR

- Create a `systemd-nspawn` container rootfs at `/var/lib/machines/dev-sandbox` using openSUSE Tumbleweed repositories.
- Inside the container, create user `dev`, `/workspace`, and install:
  - `nodejs`, `npm`, `git`, `curl`, `neovim`, `python3-poetry`, `fish`, `rsync`, and tools needed by your AI workflows.
- Set `fish` as the default shell for `dev` user in the container.
- On the host, expose `~/.config` into the container **read-only** at `/opt/host-config`, then symlink only the config paths you want into `/home/dev/.config`.
- Install **mise** (tool version manager) and your Node-based AI CLIs **globally** as `dev`.
- Keep all projects under `~/Projects/<project>` on the host; each project has a `.env.ai` file (ignored by git) with API keys.
- Use a **host-side `dev-sandbox` wrapper (bash script)** to:
  - Bind-mount a single project into `/workspace/<project>` inside the container.
  - Bind-mount host `~/.config` into `/opt/host-config` as **read-only**.
  - Start an interactive shell as `dev` in that directory (you will typically run `fish` interactively from there).
- Inside the container, run AI commands via a fish helper function `ai-env` (stored in `~/.config/fish/functions/ai-env.fish`) that loads `.env.ai` into the environment, then executes the CLI.

---

## Table of Contents

- [Overview](#overview)
- [Preparing the Base Root Filesystem (openSUSE Tumbleweed)](#preparing-the-base-root-filesystem-opensuse-tumbleweed)
  - [Configuring Repositories and Installing the Base System](#configuring-repositories-and-installing-the-base-system)
  - [Ensuring os-release and Running a Sanity Check](#ensuring-os-release-and-running-a-sanity-check)
- [Creating the Container User and Workspace](#creating-the-container-user-and-workspace)
- [Linking Host Config into the Container](#linking-host-config-into-the-container)
- [Container-Specific Fish Configuration for AI Tooling](#container-specific-fish-configuration-for-ai-tooling)
  - [PATH and Tooling Integration](#path-and-tooling-integration)
  - [`ai-env` Helper Function (fish)](#ai-env-helper-function-fish)
- [Installing Global AI CLIs and mise](#installing-global-ai-clis-and-mise)
- [Managing API Keys per Project with `.env.ai`](#managing-api-keys-per-project-with-envai)
- [Wrapper Script `dev-sandbox` (Host)](#wrapper-script-dev-sandbox-host)
- [Daily Workflow](#daily-workflow)
- [Security Considerations and Best Practices](#security-considerations-and-best-practices)
  - [Isolation Model](#isolation-model)
  - [Practices to Avoid](#practices-to-avoid)
  - [Optional Extra Hardening](#optional-extra-hardening)
- [Recap](#recap)

---

## Overview

Objective: have a **single, isolated container** (`dev-sandbox`) dedicated to running AI coding CLIs, while you continue to develop on the host using **Neovim + fish + kitty**.

Key properties:

- Host projects live under: `~/Projects/<project>`.
- Container rootfs: `/var/lib/machines/dev-sandbox`.
- Container machine name: `dev-sandbox`.
- Inside container:
  - Non-root user: `dev`
  - Workspace root: `/workspace`
  - Shell for `dev`: `fish` (default login shell)
  - Global tooling: Node/`npm`, Poetry, mise, AI CLIs
- AI CLIs see only:
  - Their container filesystem.
  - The specific project you bind-mount as `/workspace/<project>`.
- Secrets:
  - Stored **per project** in `.env.ai` (ignored by git).
  - Loaded only when running AI commands via `ai-env`.
- The host’s `$HOME`, SSH keys, browser profiles, and other secrets are **never mounted** into the container.

---

## Preparing the Base Root Filesystem (openSUSE Tumbleweed)

### Configuring Repositories and Installing the Base System

On the **host** (fish shell):

```fish
# Root directory for the dev-sandbox container rootfs
set ROOT /var/lib/machines/dev-sandbox

# Create the base directory for the rootfs
sudo mkdir -p $ROOT

# Add openSUSE Tumbleweed repositories inside the sandbox root
sudo zypper --root $ROOT addrepo -f \
    https://download.opensuse.org/tumbleweed/repo/oss/ \
    repo-oss

sudo zypper --root $ROOT addrepo -f \
    https://download.opensuse.org/tumbleweed/repo/non-oss/ \
    repo-non-oss

sudo zypper --root $ROOT addrepo -f \
    https://download.opensuse.org/update/tumbleweed/ \
    repo-update

# For julia support
sudo zypper --root $ROOT addrepo -f \
    https://download.opensuse.org/repositories/science/openSUSE_Tumbleweed/science.repo

# Refresh repo metadata inside the sandbox
sudo zypper --root $ROOT refresh

# Install base patterns approximating a minimal dev-capable system
sudo zypper --root $ROOT --non-interactive \
    install --type pattern base enhanced_base devel_basis

# Extra tools needed inside the dev environment (for all projects)
sudo zypper --root $ROOT install -y \
    git neovim nodejs npm curl \
    python3-poetry fish rsync

# Optional (specific dependencies)
sudo zypper --root $ROOT install -y \
    fzf starship zoxide eza bat stow trash-cli mercurial python3-neovim \
    go go-doc rust php php-composer java-25-openjdk-devel julia ruby-devel \
    lua51 ruby3.4-rubygem-neovim perl-base perl-App-cpanminus devel_perl make gcc
```

At this point, the container rootfs has:

* A basic openSUSE Tumbleweed system.
* Development tooling (`devel_basis`).
* `git`, `neovim`, `nodejs`, `npm`, `curl`, `python3-poetry`, `fish`, and `rsync`.

### Ensuring os-release and Running a Sanity Check

On the **host** (fish shell):

```fish
set ROOT /var/lib/machines/dev-sandbox

# Ensure /etc/os-release exists inside the sandbox
sudo mkdir -p $ROOT/etc

if not sudo chroot $ROOT test -f /etc/os-release
    echo "Installing os-release into dev-sandbox..."
    sudo cp /etc/os-release $ROOT/etc/os-release
end
```

Sanity check that the container boots:

```fish
set ROOT /var/lib/machines/dev-sandbox

sudo systemd-nspawn -D $ROOT /bin/bash
```

Inside the container (root, bash prompt):

```bash
exit
```

If you reach a shell and can exit cleanly, the base system is working.

---

## Creating the Container User and Workspace

On the **host** (fish shell):

```fish
set ROOT /var/lib/machines/dev-sandbox

sudo systemd-nspawn -D $ROOT /bin/bash
```

Inside the container (root, bash):

```bash
# Create a non-root user for development (default shell: fish)
useradd -m -s /usr/bin/fish dev
passwd dev

# Create a workspace directory where projects will be mounted
mkdir -p /workspace
chown dev:dev /workspace

exit
```

At this point:

* User `dev` exists with home directory `/home/dev`.
* `dev`’s login shell is `fish`.
* `/workspace` is owned by `dev` and will host bind-mounted projects.

---

## Linking Host Config into the Container

### Bind-mount host config (read-only)

Host config is mounted into the container at `/opt/host-config` and is not modified by the container.

### Symlink selected configs (one-time)

After entering the container as `dev`, link the config directories/files you want:

```fish
# inside container as dev
mkdir -p ~/.config

# Link what you need (examples)
ln -snf /opt/host-config/fish ~/.config/fish
ln -snf /opt/host-config/nvim ~/.config/nvim
ln -snf /opt/host-config/starship.toml ~/.config/starship.toml
```

You can add more symlinks using the same pattern.

---

## Container-Specific Fish Configuration for AI Tooling

Add **container-local** fish configuration that layers on top of the host fish config, without modifying the host files.

On the **host** (fish shell):

```fish
set ROOT /var/lib/machines/dev-sandbox

# Enter container as dev, with fish as the shell
sudo systemd-nspawn -D $ROOT --user=dev /usr/bin/fish
```

You should now be inside the container as `dev`, with a `fish` prompt.

### PATH and Tooling Integration

Inside the container as `dev` (bash script):

```bash
mkdir -p ~/.config/fish/conf.d

# Add dev-sandbox-specific PATH and tooling configuration
cat > ~/.config/fish/conf.d/dev-sandbox-ai.fish << 'EOF'
# dev-sandbox AI tooling configuration
# This file exists only inside the container and does not affect your host.

# Ensure local bin directories are on PATH (for mise, Poetry, and npm globals)
if not contains $HOME/.local/bin $PATH
    set -gx PATH $HOME/.local/bin $PATH
end

if not contains $HOME/.local/npm/bin $PATH
    set -gx PATH $HOME/.local/npm/bin $PATH
end

# npm global prefix (mirrors `npm config set prefix $HOME/.local/npm`)
set -gx npm_config_prefix $HOME/.local/npm
EOF
```

This file:

* Runs in addition to the host fish config.
* Extends `PATH` to include the directories where mise and npm global binaries will live.

### `ai-env` Helper Function (fish)

The `ai-env` helper is a dedicated fish function stored in `~/.config/fish/functions/ai-env.fish`. Fish will auto-load it when you call `ai-env`.

Inside the container as `dev` (bash script):

```bash
mkdir -p ~/.config/fish/functions

cat > ~/.config/fish/functions/ai-env.fish << 'EOF'
function ai-env --description "Load API keys from .env.ai in the current directory and run a command"

    # ai-env: project-scoped AI environment loader
    #
    # Usage:
    #   ai-env <command> [arguments...]
    #
    # Behavior:
    #   - If a .env.ai file exists in the current working directory, ai-env:
    #       * Reads lines in KEY=VALUE format
    #       * Ignores blank lines and lines starting with '#'
    #       * Exports each KEY=VALUE pair into the current fish environment
    #   - After loading variables, ai-env executes the provided command with its arguments.
    #   - The exported variables remain available for subsequent commands in this shell.

    if test -f .env.ai
        for line in (string split "\n" (cat .env.ai))
            set line (string trim $line)
            if test -z "$line"
                continue
            end
            if string match -q '#*' -- $line
                continue
            end
            set kv (string split -m 1 '=' $line)
            if test (count $kv) -eq 2
                # Export KEY=VALUE into the environment
                set -gx $kv[1] $kv[2]
            end
        end
    end

    if test (count $argv) -eq 0
        echo "ai-env: missing command"
        echo "Usage: ai-env <command> [arguments...]"
        return 1
    end

    $argv
end
EOF
```

Function summary:

* `ai-env` is a project-scoped environment loader for AI tools.
* It reads `.env.ai` in the **current directory**, exporting `KEY=VALUE` pairs.
* It then executes the command you pass (e.g. an AI CLI).
* Exported variables stay in your fish session.

You can now `exit` the container or keep it open for the next steps.

---

## Installing Global AI CLIs and mise

Install **mise** and AI CLIs globally in the container as `dev`.

On the **host** (fish shell):

```fish
set ROOT /var/lib/machines/dev-sandbox

sudo systemd-nspawn -D $ROOT --user=dev /usr/bin/fish
```

Inside the container as `dev` (fish):

1. **Install mise** (tool version manager):

```fish
curl https://mise.jdx.dev/install.sh | sh
```

This installs `mise` into a directory under `$HOME` (typically `~/.local/bin`), already on `PATH` via the `dev-sandbox-ai.fish` config.

2. **Configure npm global prefix and install AI CLIs globally**:

```fish
# Ensure npm globals go under ~/.local/npm
npm config set prefix $HOME/.local/npm

# Install the AI CLI packages you use globally inside the container.
# Replace the placeholders below with the actual packages you rely on.
npm install -g \
    <ai-cli-package-1> \
    <ai-cli-package-2> \
    <ai-cli-package-3>
```

3. **Verify tools**:

```fish
which mise
which node
which npm
which poetry
# And for each AI CLI, e.g.:
which <ai-cli-command>
```

Once this is done:

* `mise`, `node`, `npm`, `poetry`, `neovim`, and your AI CLIs are available globally for `dev`.
* Tool versions can be managed per-project using `mise` if desired (e.g., `mise use node@LTS`).

---

## Managing API Keys per Project with `.env.ai`

API keys are stored **per project** in `.env.ai` files on the host. These are mounted into the container alongside the project itself.

On the **host** (fish shell):

```fish
mkdir -p ~/Projects/my-project
cd ~/Projects/my-project

# Initialize or clone your project here
# git clone <repo-url> .   # if applicable

# Create a per-project AI env file and ensure it is ignored by git
touch .env.ai

if not grep -q ".env.ai" .gitignore ^/dev/null
    echo ".env.ai" >> .gitignore
end
```

Edit `.env.ai` with your API keys (on host):

```ini
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=...
GOOGLE_API_KEY=...
# Any other per-project API variables
```

Inside the container, when you are in `/workspace/my-project` **and using fish**:

```fish
ai-env <ai-cli-command> ...
```

Examples (inside container, fish shell):

```fish
cd /workspace/my-project

# Run an AI CLI with environment loaded from .env.ai
ai-env <ai-cli-command> --help
ai-env <ai-cli-command> some-subcommand --option value

# Or use mise and Poetry in combination
ai-env mise x <ai-cli-command> ...
ai-env poetry run <ai-cli-command> ...
```

Only `ai-env` reads `.env.ai`; other commands do not see those keys unless you deliberately export them.

---

## Wrapper Script `dev-sandbox` (Host)

Create a **single host-side wrapper** (bash script) to start the container with a project bind-mount, a read-only host-config mount, and an interactive shell as `dev`.

On the **host**:

```bash
mkdir -p "$HOME/bin"

cat > "$HOME/bin/dev-sandbox" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

MACHINE="dev-sandbox"
ROOT="/var/lib/machines/${MACHINE}"
HOST_CONFIG="${HOME}/.config"

# Check rootfs existence using sudo so permissions do not cause a false negative
if ! sudo test -d "$ROOT"; then
  echo "Error: container rootfs not found at $ROOT" >&2
  exit 1
fi

if [ ! -d "$HOST_CONFIG" ]; then
  echo "Error: host config dir '$HOST_CONFIG' does not exist." >&2
  exit 1
fi

if [ "$#" -ge 1 ]; then
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
  --bind-ro="${HOST_CONFIG}:/opt/host-config" \
  /usr/bin/fish -lc "
    mkdir -p /workspace/${PROJECT_NAME}
    cd /workspace/${PROJECT_NAME}

    # Minimal config linking (idempotent): add what you need
    mkdir -p \$HOME/.config
    [ -d /opt/host-config/fish ] && ln -snf /opt/host-config/fish \$HOME/.config/fish
    [ -d /opt/host-config/nvim ] && ln -snf /opt/host-config/nvim \$HOME/.config/nvim
    [ -f /opt/host-config/starship.toml ] && ln -snf /opt/host-config/starship.toml \$HOME/.config/starship.toml

    exec fish
  "
EOF

chmod +x "$HOME/bin/dev-sandbox"
```

Ensure `~/bin` is on your PATH in **host fish**:

```fish
if not contains $HOME/bin $PATH
    set -Ua fish_user_paths $HOME/bin
end
```

Usage on the host:

```fish
cd ~/Projects/my-project
dev-sandbox
# or explicitly:
dev-sandbox ~/Projects/my-project
```

This will:

* Bind-mount `~/Projects/my-project` to `/workspace/my-project` inside `dev-sandbox`.
* Bind-mount host `~/.config` (read-only) to `/opt/host-config` inside `dev-sandbox`.
* Create/update symlinks under `/home/dev/.config` to selected paths in `/opt/host-config`.
* Start `fish` as `dev`, with `PWD=/workspace/my-project`.

---

## Daily Workflow

1. **On the host: work on code**

   ```fish
   cd ~/Projects/my-project
   nvim .
   ```

2. **On the host: enter `dev-sandbox` for this project**

   In another terminal:

   ```fish
   cd ~/Projects/my-project
   dev-sandbox
   ```

3. **Inside the container as `dev` (fish)**

   You are now in `/workspace/my-project` with a fish shell.

   * First-time per project (optional tooling setup):

     ```fish
     # Example: configure per-project tool versions with mise
     mise use node@lts
     mise use python@3.12

     # Example: set up Poetry environment
     poetry init  # or `poetry install` if pyproject.toml already exists
     ```

   * Run AI CLIs with `.env.ai` loaded:

     ```fish
     # With environment from .env.ai
     ai-env <ai-cli-command> describe-file ./src/file.py
     ai-env <ai-cli-command> refactor --target src/
     ```

4. **Repeat per project**

   * Each project under `~/Projects/<project>`:

     * Has its own `.env.ai` with keys.
     * Is mounted as `/workspace/<project>`.
     * Uses the same `dev-sandbox` wrapper and `ai-env` helper.

5. **Exit**

   * Exit the container shell with `exit`.
   * Continue editing on host as usual.

---

## Security Considerations and Best Practices

### Isolation Model

* The container’s root filesystem lives under `/var/lib/machines/dev-sandbox`.
* Inside `dev-sandbox`, `dev` sees:

  * `/workspace/<project>` for the single bound project.
  * `/home/dev` and standard system paths.
  * `/opt/host-config` (read-only), plus whatever is symlinked into `/home/dev/.config`.
* AI CLIs only see:

  * The mounted project directory.
  * Container-local home and configuration.

They **do not see**, unless you explicitly mount:

* Host `$HOME`.
* `~/.ssh`.
* Browser profiles (`~/.mozilla`, `~/.config/chromium`, etc.).
* Other secret directories (`~/.aws`, `~/.gnupg`, etc.).
* Other projects under `~/Projects`.

### Practices to Avoid

Do not:

* Bind-mount your entire home directory:

  ```fish
  # Do NOT do this:
  sudo systemd-nspawn ... --bind "$HOME:/home/dev"
  ```

* Copy host secret directories into the container (`~/.ssh`, `~/.gnupg`, etc.).

* Export AI API keys in host-global shell configs (`~/.config/fish/config.fish` on host).

* Use `systemd-nspawn --setenv=OPENAI_API_KEY=...` from the host.

Keep secrets **only** in per-project `.env.ai` files and load them via `ai-env` inside the container.

### Optional Extra Hardening

Once the basic setup works, you can add extra hardening (all configured on the host when invoking `systemd-nspawn`):

* Use `--bind-ro` for mounts that do not need to be writable.
* Add `--private-dev` to restrict device nodes.
* Drop capabilities with `--drop-capability=all` and then selectively re-add only what is needed (via `--capability=`).
* Use `--private-network` if you want isolated networking and explicitly managed access.
* Consider `--private-users=yes` to leverage user namespaces, depending on your workflows.

These options are additive; they do not change the main workflow.

---

## Recap

* Host: openSUSE Tumbleweed, kitty, fish.

* Container: `dev-sandbox` under `/var/lib/machines/dev-sandbox`, built using openSUSE Tumbleweed via `zypper --root`.

* Inside the container:

  * User `dev`, default shell `fish`, workspace at `/workspace`.
  * Base tooling: `git`, `neovim`, `nodejs`, `npm`, `curl`, `python3-poetry`, `fish`, `rsync`.
  * Global tools: `mise`, AI CLIs installed via `npm install -g`.
  * Host configs are mounted read-only at `/opt/host-config` and linked into `/home/dev/.config` as needed.
  * Container-specific fish config lives in `~/.config/fish/conf.d/dev-sandbox-ai.fish`.
  * `ai-env` function is defined in `~/.config/fish/functions/ai-env.fish`, loads `.env.ai`, and runs AI CLIs with the correct environment.

* Host projects:

  * Live under `~/Projects/<project>`.
  * Each contains `.env.ai` (in `.gitignore`) for per-project API keys.

* Wrapper:

  * Host `~/bin/dev-sandbox` is a **bash** script that bind-mounts `~/Projects/<project>` to `/workspace/<project>`, mounts host `~/.config` read-only at `/opt/host-config`, links selected configs into `/home/dev/.config`, and starts `fish` as `dev`.

* Result:

  * Editing remains on the host (Neovim + fish).
  * AI CLIs execute in an isolated container, see only the bound project and the per-project `.env.ai`, and never see host-level sensitive directories.
