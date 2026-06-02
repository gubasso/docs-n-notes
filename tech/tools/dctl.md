---
last-synced: 2026-06-02
source-of-truth:
  - https://github.com/devcontainerctl/devcontainerctl
  - ~/Projects/_sources/devcontainerctl-develop  # local clone, treat as authoritative
upstream-version-seen: develop branch @ 2026-05-27
refresh-triggers:
  - bin/dctl, lib/dctl/*.sh, or images/*/Dockerfile changed upstream
  - any spec/ document changes
  - any new top-level command group added
  - any CLI flag added/removed/renamed
refresh-procedure: re-read bin/dctl + lib/dctl/*.sh in the source tree, then update the CLI surface tables below verbatim from the actual `usage_*` heredocs and case branches; bump last-synced
audience: AI coding agents and humans setting up / debugging dctl-managed devcontainers
---

# dctl — devcontainerctl CLI reference

> **AI-friendly reference for `dctl`** (devcontainerctl). The repository
> at `$DOCS_NOTES_REPO/tech/tools/dctl.md` is the **digest**; the
> authoritative source is the **shell library itself**
> (`bin/dctl` + `lib/dctl/*.sh`) under the dctl source tree. When in
> doubt, `grep` the source — never guess CLI flags or subcommand names.
>
> **Common wrong assumptions to unlearn:**
>
> - There is **no** `dctl image rebuild`. The verb is `dctl image build`,
>   and a clean rebuild is `dctl image build --full-rebuild`.
> - There is **no** `dctl image build --no-cache`. The equivalent is
>   `--full-rebuild` (which sets `--no-cache` internally and implies
>   `--all`).
> - `dctl ws reup` does **not** rebuild images. It recreates the
>   *container* from the existing image. To get a fresh image into a
>   running workspace you must `dctl image build … && dctl ws reup`.
> - Editing `~/.dotfiles/dctl/.config/dctl/images/<image>/Dockerfile`
>   only changes what dctl builds **if** that path is the same inode as
>   `~/.config/dctl/images/<image>/Dockerfile` (i.e. stowed). If the
>   user config is a real copy, you must re-deploy with
>   `dctl deploy image <image> --reset` before rebuilding.

## What dctl is

`dctl` (devcontainerctl) is a thin bash wrapper around the Dev
Container CLI (`devcontainer`) and `docker buildx`. It does three
things the upstream tools don't:

1. **Composable devcontainer manifests** — YAML manifests under
   `~/.config/dctl/devcontainer/<name>.yaml` declare an ordered
   `layers:` list. `dctl init` resolves each layer's
   `devcontainer.json` and merges them into a single cached config
   under `~/.cache/dctl/`.
2. **Managed image catalog** — Dockerfiles under
   `~/.config/dctl/images/<name>/Dockerfile` are built with
   `docker buildx`, tagged `devimg/<name>:latest`, and built with the
   build-time args `USERNAME`, `USER_UID`, `USER_GID` set from the
   host's `$USER` / `id -u` / `id -g`.
3. **Credential and term env forwarding** — every `dctl ws exec/shell/run`
   extracts `gh auth token` / `glab auth status --show-token` and
   forwards `GH_TOKEN` / `GITLAB_TOKEN` plus `TERM*` / `COLORTERM` /
   Kitty env vars into the container.

The XDG layout below is the **non-negotiable invariant**: changes to
installed seed assets do not affect runtime; runtime is fed exclusively
from user config + cache.

## XDG layout (the 3-tier model)

| Path | Role | Written by | Read by |
| --- | --- | --- | --- |
| `~/.local/share/dctl/devcontainers/`, `~/.local/share/dctl/images/`, `~/.local/share/dctl/schemas/` | **Installed seeds.** Shipped templates and Dockerfiles. *Never used at runtime.* | `make install` | `dctl deploy` only |
| `~/.config/dctl/devcontainer/`, `~/.config/dctl/images/`, `~/.config/dctl/projects.yaml`, `~/.config/dctl/default/` | **User config — runtime source of truth.** Editable. | `dctl deploy`, the user | `dctl image build`, `dctl init`, `dctl ws *`, `dctl test` |
| `~/.cache/dctl/devcontainer/<manifest>/devcontainer.json` | **Generated merged config.** Output of `dctl init`. | `dctl init`, `dctl ws reup` (auto-regen) | `dctl ws up`, `devcontainer` CLI |

All three honor `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`.

`dctl image build` resolves Dockerfiles **only** from
`~/.config/dctl/images/<target>/Dockerfile` — never from the installed
seed. To use a freshly-edited Dockerfile, it must live at (or be
stowed to) the user-config path.

## CLI surface — exhaustive

Source: `bin/dctl` + `lib/dctl/*.sh` in the upstream tree. Quoted
inline from the live `usage_*` heredocs.

### Global

```text
dctl [--config <path>] <command-group> [command] [options]
dctl help
dctl version
```

`--config <path>` overrides the devcontainer.json resolution chain
(see [resolution chain](#devcontainerjson-resolution-chain) below)
for the current invocation and exports `DCTL_CLI_CONFIG`.

Command groups: `init`, `deploy`, `test`, `ws`, `image`, `config`,
`help`, `version`.

### `dctl deploy`

Copies installed seed assets into user config. **Required** before
`dctl image build` or `dctl init` can see new images or manifests.

```text
Usage: dctl deploy [selector] [options]

Selectors:
  devcontainer <name>             Deploy one devcontainer template
  image <name>                    Deploy one image
  --all                           Deploy all devcontainers and images
  --all-devcontainers             Deploy all devcontainers
  --all-images                    Deploy all images

Options:
  --reset                         Back up and overwrite shipped files
  --dry-run                       Print the per-file plan and change nothing
  --list                          List deployment state for both categories
  --list-devcontainers            List devcontainer deployment state
  --list-images                   List image deployment state
  --help, -h                      Show this help text

Interactive:
  dctl deploy                     Pick a category, pick item(s), confirm, deploy
```

Semantics:

- Manifest files (`<name>.yaml`) are **always** reconciled on every
  devcontainer deploy.
- Non-leaf layers (everything except the last entry in a manifest's
  `layers:`) are **always** reconciled.
- **Leaf layers are user-protected.** They are only overwritten when
  `--reset` is passed; otherwise an existing deployed leaf is skipped
  with `skipped <category> '<name>': <dest> (exists; pass --reset to overwrite)`.
- `--reset` writes a `.bak.<timestamp>` next to the original before
  overwriting.
- `--dry-run` and `--reset` are **mutually exclusive**
  (`Cannot use --dry-run with --reset`).

### `dctl init`

```text
Usage: dctl init [options]

Register the current project against a deployed devcontainer config and run
the workspace smoke test.

Options:
  --devcontainer <name>                Use a specific deployed devcontainer
  --force                              Rebuild cached merged config and re-register
  --help, -h                           Show this help text
```

What `dctl init` actually does, in order:

1. Resolves the manifest from `~/.config/dctl/devcontainer/<name>.yaml`.
2. Merges every layer's `devcontainer.json` in manifest order and
   writes the merged result to
   `~/.cache/dctl/devcontainer/<name>/devcontainer.json`.
3. If the merged config references a managed image
   (`devimg/<name>:latest`) and that image is not present locally,
   **auto-builds it** via `dctl image build <name>`. Requires
   `~/.config/dctl/images/<name>/Dockerfile` to exist.
4. Writes the project → manifest mapping to
   `~/.config/dctl/projects.yaml` (registry).
5. Runs `dctl test` and exits non-zero on smoke-test failure.

### `dctl ws`

```text
Usage: dctl ws <command> [options]

Commands:
  up [-- <devcontainer up args...>]
  reup [-- <devcontainer up args...>]
  exec [-- <command...>]
  shell [<command...>]
  run [--] <command...>
  status
  down
  help
```

| Verb | What it does | Backing call |
| --- | --- | --- |
| `up` | Start or attach (idempotent) | `devcontainer up --workspace-folder ... --config ...` |
| `reup` | **Recreate** the container (mounts and env are re-applied). Regenerates the cached merged config first if a manifest is registered. | `devcontainer up ... --remove-existing-container` |
| `exec [-- cmd...]` | Run `cmd` non-login. Defaults to `bash`. Auto-starts if no container running. | `devcontainer exec -- cmd` |
| `shell [cmd...]` | Interactive login shell. With `cmd`, runs `bash -lic "<cmd>"`. | `devcontainer exec -- bash` / `bash -lic` |
| `run -- cmd...` | Run `cmd` via `bash -lc`. Errors if no command given. | `devcontainer exec -- bash -lc "..."` |
| `status` | `docker ps -a` filtered by workspace label | `docker ps` |
| `down` | Stop + remove all containers labeled for this workspace | `docker rm -f` |

Critical detail: containers are **matched by workspace label**, not
by directory name. Linked git worktrees of the same repo get
**separate containers**.

Credentials forwarded by `exec` / `shell` / `run` (silently skipped if
unavailable):

- `GH_TOKEN`: from `$GH_TOKEN` → `$GITHUB_TOKEN` → `gh auth token`
- `GITLAB_TOKEN`: from `$GITLAB_TOKEN` → `glab auth status --show-token`

Terminal env forwarded: `TERM`, `COLORTERM`, `TERM_PROGRAM`,
`TERM_PROGRAM_VERSION`, `KITTY_WINDOW_ID`, `KITTY_LISTEN_ON`.

Linked-worktree handling: if `WORKSPACE_FOLDER` is a `git worktree`,
the shared `.git` common dir is bind-mounted into the container at
the same absolute host path so the gitdir reference resolves.

### `dctl image`

```text
Usage: dctl image <command> [options]

Commands:
  build [OPTIONS] [IMAGE...]
      Build devcontainer base images from $XDG_CONFIG_HOME/dctl/images.
      If no image is specified, launches an interactive fzf picker over
      the deployed managed images under ~/.config/dctl/images/.

      Options:
        --all              Build all discovered images
        --full-rebuild     Rebuild all images from scratch
        --refresh-agents   Cache-bust the agents CLI layer
        --dry-run, -n      Show what would be built without building
        --help, -h         Show build help

  list
      List available images and exit.
```

**Flag semantics** (from `lib/dctl/image.sh:cmd_image_build`):

| Flag | Effect |
| --- | --- |
| `--all` | Builds every image under `~/.config/dctl/images/` |
| `--full-rebuild` | **Sets `--all=true` AND `--no-cache=true`.** This is the only way to invalidate the buildx layer cache. |
| `--refresh-agents` | Adds `--build-arg CACHEBUST_AGENTS=<unix-ts>` to the `agents` build (re-runs the AI-CLI install layer only). No-op for non-`agents` targets. |
| `--dry-run`, `-n` | Print the plan, build nothing. |
| (no target, no `--all`) | Interactive `fzf` picker over deployed targets. Errors out if not a TTY. |

**`--pull` is implicit and only added when** the target is `agents` AND
`--all` is true. So `dctl image build --all` does `docker buildx build
--pull --no-cache` for the agents image (when `--full-rebuild` is set)
or `--pull` only for agents (without `--full-rebuild`).

**Build args always passed:**

```bash
--build-arg USERNAME="$USER" \
--build-arg USER_UID="$(id -u)" \
--build-arg USER_GID="$(id -g)"
```

This is why running `dctl image build` **as root** is hard-refused
(`Do not run as root (would bake UID 0 into images)`). Run from your
host user account.

**GitHub token secret:** if `gh auth token` returns a token, it is
written to a tmpfile and passed as `--secret id=gh_token,src=…`.
Dockerfiles can read it via `--mount=type=secret,id=gh_token` to avoid
the 60 req/hr anonymous GitHub API rate limit during mise installs.

**Image tag format:** `devimg/<target>:latest`. Hard-coded.

### `dctl test`

```text
Usage: dctl test [options]
```

The workspace smoke test: prerequisite checks, auto-build of any
missing managed image, `devcontainer up`, `devcontainer exec` (a
trivial command), cleanup. Called automatically by `dctl init`.

### `dctl config`

Currently a stub — only `help` is implemented. Project registry lives
at `~/.config/dctl/projects.yaml`; edit that file directly to
inspect or change manifest assignments.

## devcontainer.json resolution chain

`dctl` resolves `devcontainer.json` in this exact order (first hit wins):

1. `--config` CLI flag (`DCTL_CLI_CONFIG`)
2. `DCTL_CONFIG` environment variable
3. Project registry `~/.config/dctl/projects.yaml`
   (`devcontainer-manifest: <name>` → merged cache file)
4. Local `.devcontainer/devcontainer.json` in `WORKSPACE_FOLDER`
5. Work-clone sibling discovery (for linked worktrees: resolve from the
   main repo's config)
6. User global default at `~/.config/dctl/default/devcontainer.json`

## Bind-mount mechanics (the part that breaks devcontainer setups)

The Dev Containers spec leaves Docker to auto-create missing **parent
directories** of a bind-mount target. **Docker creates them as
`root:root 0755`, at container-start time, before the remoteUser
runs.** This bites file mounts in particular, because the parent dir
must exist to host the bind point.

**Pattern that fails:** mount host file `~/.config/foo/bar` →
container `~/.config/foo/bar`, where the image does not pre-create
`/home/<user>/.config/foo`. Docker silently makes `/home/<user>/.config/foo`
as `root:root 0755`, and any subsequent attempt by the non-root user
to write a sibling (e.g. a `cache/` subdir) inside fails with
`PermissionError: [Errno 13] Permission denied`.

**Fix in the agents Dockerfile** (must run before `USER $USERNAME`):

```dockerfile
RUN install -d -m 0755 -o $USERNAME -g $USERNAME \
        /home/$USERNAME/.local/lib \
        /home/$USERNAME/.config/osc
```

After editing the Dockerfile, **a `dctl ws reup` alone is not enough**
— that only recreates the container against the existing image. You
must rebuild the image first:

```bash
dctl image build agents              # picks up Dockerfile changes
dctl image build --full-rebuild      # if the cached layer was reused incorrectly
dctl ws reup                         # recreate the container against the new image
```

**Verification (inside the new container):**

```bash
# Birth time should be the IMAGE BUILD time (days/weeks old).
# If it's the container-start time, the image is stale and Docker
# auto-created the dir at start.
stat -c '%U:%G %a  Birth=%w' ~/.config/<dir>
```

Detailed worked example for `~/.config/osc`: see
[`osc-obs-auth-in-devcontainers.md`](osc-obs-auth-in-devcontainers.md).

## Common gotchas

### "I edited the Dockerfile but `dctl image build agents` shows no change"

dctl reads from `~/.config/dctl/images/agents/Dockerfile` (user
config), **not** from the dotfiles repo or the installed seed.
Confirm with:

```bash
realpath ~/.config/dctl/images/agents/Dockerfile
ls -l ~/.config/dctl/images/agents/Dockerfile   # is it a symlink?
diff ~/.config/dctl/images/agents/Dockerfile \
     ~/.dotfiles/dctl/.config/dctl/images/agents/Dockerfile
```

If the user-config file is not a stow symlink, re-deploy:

```bash
dctl deploy image agents --reset
```

`--reset` is required because the leaf image is user-protected.

### "Layer cache reused the old version even after Dockerfile edits"

`docker buildx` invalidates layers based on the literal text of the
`RUN` instruction plus referenced build-context files. Trivial edits
(comment changes, whitespace) **do** invalidate the layer. Layers
*after* an edited line all rebuild. If somehow you still see cache
hits where you don't want them:

```bash
dctl image build --full-rebuild   # adds --no-cache, applies to all targets
```

Last-ditch: `docker rmi devimg/agents:latest && dctl image build agents`.

### "dctl image rebuild not found"

It doesn't exist. The verb is **build**:

```bash
dctl image build [target]            # build (cached)
dctl image build --full-rebuild      # clean rebuild, all targets
dctl image build --refresh-agents agents   # bust only the agent CLI install layer
```

### "I want to bump just the AI-agent CLIs (Claude Code, Codex, etc.)"

```bash
dctl image build --refresh-agents agents
dctl ws reup
```

Sets `--build-arg CACHEBUST_AGENTS=<timestamp>`, which the agents
Dockerfile uses as a cache buster before the `curl … claude.ai/install.sh
| bash` and `bun add -g @openai/codex …` layers. Re-runs only those
final layers.

### "`dctl image build` says 'Do not run as root'"

Build args bake `USERNAME=root`, `USER_UID=0` into the image, which
makes the resulting container useless for any uid 1000 mounts. The
command refuses. Run as your normal host user.

### "No GitHub token found — builds may hit API rate limits"

dctl extracts the token from `$GH_TOKEN` → `$GITHUB_TOKEN` →
`gh auth token`. If none is available, the build proceeds without
the `--secret id=gh_token` and may hit the 60 req/hr anonymous
ceiling on mise's GitHub-backed installs. Fix: `gh auth login`.

### Worktrees and shared `.git`

If `WORKSPACE_FOLDER` is a git linked worktree (i.e. `git rev-parse
--git-dir` ≠ `git rev-parse --git-common-dir`), `dctl ws up/reup`
auto-mounts the common dir at the same host path inside the container
so the worktree's `.git` file resolves. You don't have to do anything
— but if the container can't see git history, check that the host
path of the common dir actually exists inside the container.

## Recipes

### First-time project setup

```bash
make install                              # in the dctl source tree, once per host
dctl deploy --all                         # seed user config (no --reset)
dctl init --devcontainer <manifest>       # registers project, auto-builds image, runs smoke test
dctl ws shell                             # drop into the container
```

### Pick up a Dockerfile change

```bash
# After editing ~/.config/dctl/images/agents/Dockerfile (or via stow)
dctl image build agents
dctl ws reup
```

### Pick up a devcontainer.json (mounts / env) change

```bash
# After editing ~/.config/dctl/devcontainer/<layer>/devcontainer.json
dctl init --force         # regenerate cached merged config
dctl ws reup              # recreate container with new mounts/env
```

### Forcibly rebuild everything from scratch

```bash
dctl image build --full-rebuild     # --no-cache + --all
dctl ws reup
```

### Inspect what dctl would build / deploy

```bash
dctl image build --dry-run
dctl deploy --dry-run --all
dctl deploy --list
dctl image list
```

## Source-of-truth files (read these before guessing)

When you don't trust this digest, read these in order:

| Topic | File in the dctl tree |
| --- | --- |
| Top-level command dispatch | `bin/dctl` |
| `image` flag semantics, build args, secrets | `lib/dctl/image.sh` |
| `ws` lifecycle, credential extraction, worktree mounts | `lib/dctl/ws.sh` |
| `deploy` selectors, leaf protection, reset/backup | `lib/dctl/deploy.sh` |
| `init` merge logic, auto-build, registry write | `lib/dctl/init.sh` |
| `test` smoke-test phases | `lib/dctl/test.sh` |
| Config resolution chain, project registry helpers | `lib/dctl/config.sh` |
| Token extraction (`_extract_gh_token`, etc.) | `lib/dctl/auth.sh` |
| Shared utils (`err`, `log`, `warn`, `require_cmd`) | `lib/dctl/common.sh` |
| Compose manifest schema | `schemas/compose.schema.yaml` |
| Per-template Dockerfiles | `images/<name>/Dockerfile` |
| Shipped layer `devcontainer.json` files | `devcontainers/<name>/devcontainer.json` |
| Manifest YAMLs | `devcontainers/<name>.yaml` |
| Spec docs (deeper rationale) | `spec/00-resolution-model.md` and siblings |

## References

- [devcontainerctl source](https://github.com/devcontainerctl/devcontainerctl) — upstream
- Local clone: `~/Projects/_sources/devcontainerctl-develop` — used as SoT for this digest
- [README.md](https://github.com/devcontainerctl/devcontainerctl/blob/develop/README.md) — product overview, XDG layout, install
- [docs/QUICKSTART.md](https://github.com/devcontainerctl/devcontainerctl/blob/develop/docs/QUICKSTART.md)
- [docs/ARCHITECTURE.md](https://github.com/devcontainerctl/devcontainerctl/blob/develop/docs/ARCHITECTURE.md)
- [docs/WORKFLOW-COMPARISON.md](https://github.com/devcontainerctl/devcontainerctl/blob/develop/docs/WORKFLOW-COMPARISON.md)
- [spec/README.md](https://github.com/devcontainerctl/devcontainerctl/blob/develop/spec/README.md)
- [Dev Container spec — mounts/containerEnv schema](https://containers.dev/implementors/spec/)
- [Docker bind mounts — file-vs-directory semantics](https://docs.docker.com/engine/storage/bind-mounts/)

## Maintenance

This file is a **human-curated digest**. Refresh when any of the
`refresh-triggers` in the frontmatter occur. The refresh procedure is:

1. `cd ~/Projects/_sources/devcontainerctl-develop && git pull`
2. `head -50 lib/dctl/{image,ws,deploy,init,test,config}.sh` to capture
   updated `usage_*` heredocs.
3. Diff against the CLI surface tables above; update verbatim.
4. Bump `last-synced` in the frontmatter.
5. If a new command group appeared, add a new section under
   [CLI surface](#cli-surface--exhaustive).
6. If the source repo moved (e.g. published to a registry, renamed
   branch), update `source-of-truth:` and `upstream-version-seen:`.
