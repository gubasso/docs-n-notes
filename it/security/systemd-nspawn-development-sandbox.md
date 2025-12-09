# Develpment Sandbox with Systemd-nspawn

## 1. High-level architecture

We will set up:

* A **single shared `systemd-nspawn` container**:

  * Machine name: `dev-sandbox`
  * Root filesystem: `/var/lib/machines/dev-sandbox`
* A **non-root user** inside the container:

  * Username: `dev`
  * Home: `/home/dev`
* A **workspace directory** inside the container:

  * `/workspace`
* Your **host projects** live under:

  * `~/Projects/<project-name>`
* When you work on a project:

  * The host directory `~/Projects/my-project` is bind-mounted into the container as `/workspace/my-project`.
  * Inside the container, you run AI CLIs against `/workspace/my-project`.
* No bind mount of:

  * Your host `$HOME`
  * `~/.ssh`
  * Browser profiles
  * Other unrelated directories

All tools (Node, npm, AI CLIs) live **inside** the container, not on the host.

---

## 2. Preparing the base root filesystem for `dev-sandbox`

We will create a minimal root filesystem at `/var/lib/machines/dev-sandbox` for:

* Arch Linux (using `pacstrap`)
* openSUSE Tumbleweed (using `zypper --root`)

### 2.1. Arch Linux: rootfs via `pacstrap`

On the host (Arch):

1. Create the rootfs directory:

   ```bash
   sudo mkdir -p /var/lib/machines/dev-sandbox
   ```

2. Install a minimal Arch base into it:

   ```bash
   sudo pacstrap -c /var/lib/machines/dev-sandbox base base-devel
   ```

3. Optionally add some useful tools now (or later):

   ```bash
   sudo pacstrap -c /var/lib/machines/dev-sandbox git vim neovim
   ```

4. Ensure there is an `os-release` file in the rootfs (some tools expect it):

   ```bash
   if [ ! -f /var/lib/machines/dev-sandbox/usr/lib/os-release ] && \
      [ ! -f /var/lib/machines/dev-sandbox/etc/os-release ]; then
     sudo cp /usr/lib/os-release /var/lib/machines/dev-sandbox/usr/lib/os-release
   fi
   ```

---

### 2.2. openSUSE Tumbleweed: rootfs via `zypper --root`

On the host (openSUSE Tumbleweed):

1. Create the rootfs directory:

   ```bash
   sudo mkdir -p /var/lib/machines/dev-sandbox
   ```

2. Install a minimal system into that directory:

   ```bash
   sudo zypper --root /var/lib/machines/dev-sandbox \
     --non-interactive \
     install --no-recommends --type pattern minimal_base
   ```

3. Add useful tools:

   ```bash
   sudo zypper --root /var/lib/machines/dev-sandbox install git neovim
   ```

4. Copy DNS config so the container can access the network initially:

   ```bash
   sudo cp -L /etc/resolv.conf /var/lib/machines/dev-sandbox/etc/resolv.conf
   ```

5. Ensure `os-release` exists (similar to Arch):

   ```bash
   if [ ! -f /var/lib/machines/dev-sandbox/usr/lib/os-release ] && \
      [ ! -f /var/lib/machines/dev-sandbox/etc/os-release ]; then
     sudo cp /usr/lib/os-release /var/lib/machines/dev-sandbox/usr/lib/os-release
   fi
   ```

---

### 2.3. Sanity check with a temporary shell

On **either** distro, confirm the rootfs is usable:

```bash
sudo systemd-nspawn -D /var/lib/machines/dev-sandbox /bin/bash
```

If you get a shell, the base system is good.

Exit:

```bash
exit
```

---

## 3. Creating and configuring the `systemd-nspawn` container

### 3.1. Create the `dev` user and workspace inside the container

Enter the container as root:

```bash
sudo systemd-nspawn -D /var/lib/machines/dev-sandbox /bin/bash
```

Inside the container:

```bash
# Create non-root user "dev"
useradd -m -s /bin/bash dev
passwd dev      # set a password (even if you rarely use it)

# Create workspace directory for projects
mkdir -p /workspace
chown dev:dev /workspace

exit
```

Now the container has:

* User: `dev`
* Directory: `/workspace` owned by `dev`

---

### 3.2. Basic `systemd-nspawn` run command with bind mounts

Assume a project on the host:

```bash
mkdir -p ~/Projects/my-project
```

To start a container shell for that project:

```bash
sudo systemd-nspawn \
  -D /var/lib/machines/dev-sandbox \
  -M dev-sandbox \
  --user=dev \
  --chdir=/workspace/my-project \
  --bind="$HOME/Projects/my-project:/workspace/my-project" \
  /bin/bash
```

Effect:

* The host `~/Projects/my-project` appears in the container as `/workspace/my-project`.
* You start as user `dev` in `/workspace/my-project`.
* Nothing else from your host home is visible unless you explicitly bind it.

---

### 3.3. Optional `.nspawn` file for defaults

You can configure default options in `/etc/systemd/nspawn/dev-sandbox.nspawn` on the host:

```bash
sudo mkdir -p /etc/systemd/nspawn
sudo tee /etc/systemd/nspawn/dev-sandbox.nspawn >/dev/null <<'EOF'
[Exec]
User=dev
WorkingDirectory=/workspace

[Files]
# Binds are still provided dynamically at runtime.

[Network]
Private=no
EOF
```

With this file in place, you can omit `--user=dev` and `--chdir=/workspace` from the command if you prefer; they become defaults. You still pass the `--bind` arguments at runtime or via a wrapper script.

---

## 4. Installing AI CLIs and tooling inside the container

We will:

* Install Node.js and npm inside the container.
* Use them to install AI-related CLIs.
* Keep the tools in the container; your host remains clean.

### 4.1. Install base tooling (Node, npm, etc.)

Enter the container as root:

```bash
sudo systemd-nspawn -D /var/lib/machines/dev-sandbox /bin/bash
```

Inside the container:

* On **Arch**:

  ```bash
  pacman -Syu --noconfirm
  pacman -S --noconfirm nodejs npm git curl
  ```

* On **openSUSE Tumbleweed**:

  ```bash
  zypper refresh
  zypper install -y nodejs npm git curl
  ```

You can also install `fish` and/or `neovim` inside the container if you want:

```bash
# Arch
pacman -S --noconfirm fish neovim

# openSUSE
zypper install -y fish neovim
```

Optionally change `dev`’s shell:

```bash
chsh -s /usr/bin/fish dev
```

Exit when done:

```bash
exit
```

---

### 4.2. Installing AI CLIs (shared vs per-project layout)

You have two practical patterns:

#### Pattern A – Shared CLIs under `dev`’s home

Install once as user `dev`, available in all projects.

```bash
sudo systemd-nspawn -D /var/lib/machines/dev-sandbox --user=dev /bin/bash
```

Inside container as `dev`:

```bash
# Configure user-local npm prefix
mkdir -p "$HOME/.local/npm"
npm config set prefix "$HOME/.local/npm"

# Ensure the bin dir is in PATH (bash example)
echo 'export PATH="$HOME/.local/npm/bin:$PATH"' >> ~/.bashrc
# For fish (inside container), you might add:
# set -Ux PATH $HOME/.local/npm/bin $PATH

# Restart shell or source config, then:
npm install -g <openai-cli-package> <claude-cli-package> <gemini-cli-package>
```

Now commands like `openai-codex`, `claude`, `gemini`, etc. (whatever the actual binary names are) are globally available in the container.

#### Pattern B – Per-project local installs

Inside the container as `dev`, after mounting a project:

```bash
cd /workspace/my-project

npm init -y
npm install --save-dev <openai-cli-package> <claude-cli-package> <gemini-cli-package>
```

Then invoke them with:

```bash
npx <cli-name> ...
# or via npm scripts defined in package.json
npm run ai:codex
```

For AI-specific workflows tied to each repo (prompt config, project scripts, etc.), **Pattern B (per-project)** typically works better because:

* Versions are locked in the project.
* The container remains a reusable runtime layer.

You can still use Pattern A for generic helpers and Pattern B for the main AI CLIs.

---

## 5. Managing API keys and secrets securely

The goal is:

* No API keys on the host in global shell configs.
* Per-project secrets stored inside each project directory.
* Only the currently mounted project’s secrets are visible in the container.

### 5.1. Per-project `.env` file alongside code

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

This file is:

* Under `~/Projects/my-project` on the host.
* Visible as `/workspace/my-project/.env.ai` in the container when that project is mounted.
* Ignored by git.

### 5.2. Simple helper to load env in the container

Inside the container as `dev`, add a helper to your shell config.

For bash (inside container):

```bash
# in ~/.bashrc

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

Now, when you are in `/workspace/my-project`:

```bash
ai-env npx openai-codex --help
ai-env npm run ai:codex
ai-env npx claude ...
```

The environment variables are loaded only for that command, from the `.env.ai` in the current directory.

You can create an equivalent function in `fish` inside the container if desired.

### 5.3. Keep secrets out of host-global configs

Avoid:

* Exporting API keys in host-level shells (`~/.config/fish/config.fish`, `~/.bashrc`, etc.).
* Passing secrets via `systemd-nspawn --setenv=...` from the host.

Everything sensitive should live in per-project `.env.ai` files under `~/Projects/<project>`.

---

## 6. Daily workflow with `dev-sandbox`

This is how you use the setup day-to-day.

### 6.1. Typical workflow for a single project

On the host:

1. Create or clone a project:

   ```bash
   mkdir -p ~/Projects/my-project
   cd ~/Projects/my-project
   git init   # or git clone ...
   ```

2. Prepare `.env.ai`:

   ```bash
   touch .env.ai
   echo ".env.ai" >> .gitignore
   # edit .env.ai with your API keys
   ```

3. Open Neovim on the host:

   ```bash
   nvim .
   ```

   You edit code using your usual host fish + Neovim setup.

4. Enter the sandbox for this project (using a wrapper script, see below):

   ```bash
   dev-sandbox       # uses current directory
   # or
   dev-sandbox ~/Projects/my-project
   ```

5. Inside the container:

   ```bash
   cd /workspace/my-project

   # First time:
   npm init -y
   npm install --save-dev <ai-cli-packages>

   # After that:
   ai-env npx openai-codex ...
   ai-env npx claude ...
   ai-env npx gemini ...
   ```

You can open multiple host terminals: one for Neovim, one for the container shell.

---

### 6.2. Wrapper script: `dev-sandbox`

On the host, create a script to streamline entering the container:

```bash
mkdir -p ~/bin
cat > ~/bin/dev-sandbox <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

MACHINE="dev-sandbox"
ROOT="/var/lib/machines/${MACHINE}"

if [ ! -d "$ROOT" ]; then
  echo "Error: container rootfs not found at $ROOT" >&2
  exit 1
fi

# If a path is given, use it; otherwise, default to current directory.
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

# Run systemd-nspawn and bind-mount the project into /workspace/<name>
sudo systemd-nspawn \
  -M "$MACHINE" \
  -D "$ROOT" \
  --user=dev \
  --chdir="/workspace/${PROJECT_NAME}" \
  --bind="${PROJECT_PATH}:/workspace/${PROJECT_NAME}" \
  /bin/bash
EOF

chmod +x ~/bin/dev-sandbox
```

Make sure `~/bin` is in your PATH (in fish on the host, something like):

```fish
set -Ux PATH $HOME/bin $PATH
```

Usage examples:

```bash
# From inside a project:
cd ~/Projects/my-project
dev-sandbox

# Or pass the path explicitly:
dev-sandbox ~/Projects/my-project
```

This gives you a single, easy command to “enter the AI/dev sandbox” for a given project.

---

## 7. Security considerations and best practices

### 7.1. Why your SSH keys and other secrets are safe

* The container filesystem is rooted at `/var/lib/machines/dev-sandbox`.
* Inside the container, the only host paths you expose are the ones passed via `--bind`.
* Because you **only** bind `~/Projects/<project>`, AI CLIs running inside the container cannot see:

  * `~/.ssh`
  * Browser profiles (`~/.mozilla`, `~/.config/chromium`, etc.)
  * Other project directories
  * Host-level secrets (e.g. `~/.aws`, `~/.gnupg`)
* Secrets live in per-project `.env.ai` files that are only visible when that project is bind-mounted.

### 7.2. Things to avoid

* Do not bind-mount your entire home:

  ```bash
  # Bad: exposes everything, including ~/.ssh and browser data
  --bind="$HOME:/home/dev"
  ```

* Do not store API keys in host-global shell configuration.

* Do not copy host secret directories into the container.

* Avoid running AI CLIs as root inside the container.

### 7.3. Optional hardening ideas

If you want to go further (optional):

* Make some mounts read-only (`--bind-ro` instead of `--bind`) when you do not need to write.
* Use `--private-dev` to hide unnecessary host device nodes from the container.
* Drop unnecessary capabilities (`--drop-capability=all` plus selectively re-enable if something breaks).
* Use `--private-network` with a dedicated bridge if you want more network separation.

These are incremental improvements; the main isolation comes from:

* Separate rootfs
* Very restricted bind mounts
* Per-project secrets

---

## 8. Recap

You now have a concrete pattern:

1. **Rootfs** at `/var/lib/machines/dev-sandbox` (Arch or openSUSE minimal system).
2. Inside it:

   * User `dev`
   * `/workspace` for mounted projects
   * Node, npm, git, curl, optional fish/neovim
3. **Host projects** live under `~/Projects/<project>`.
4. A **wrapper script** `dev-sandbox`:

   * Binds `~/Projects/<project>` to `/workspace/<project>`
   * Drops you into the container as `dev` in that directory
5. **AI CLIs** installed inside the container (globally for `dev` and/or per-project via `npm`).
6. **Per-project `.env.ai`** files hold API keys; loaded inside the container with `ai-env`.

From your perspective, the workflow becomes:

* Edit in Neovim on the host in `~/Projects/<project>`.
* Run `dev-sandbox` to enter an isolated environment.
* Inside, use AI tools safely on `/workspace/<project>` without exposing `~/.ssh` or other host secrets.
