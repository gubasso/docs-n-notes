# 04 — Nix inside dctl devcontainers

dctl sandboxes run "full pure-nix": zypper provides only system/ABI libs; **Nix owns every user CLI
and every per-project toolchain**. In the container Nix runs single-user (daemonless), with the
store on a persistent volume.

## Architecture

```
zypper (image, root)          Nix single-user (/nix volume, $USER)         per-project flake
──────────────────────        ─────────────────────────────────────        ──────────────────
ABI/build/runtime libs        dctl GLOBAL flake via `nix profile`:          language toolchain +
+ bootstrap (curl, xz,        agent CLIs + shell UX + linters +             native/system deps
git, direnv)                  direnv/nix-direnv                             (swig, Playwright libs)
                                                                            + dev CLIs.
                                                                            Auto-activated by direnv.
```

There is a **single image** (`agents`) — no per-language images, and only two package managers
(Nix + zypper), no curl-pipe installers.

## How Nix gets into the container

- **Single-user, daemonless.** Installed by `images/agents/nix-bootstrap.sh` from the official
  installer with `--no-daemon` (the Determinate `--init none` variant is multi-user-without-daemon
  and needs root; our sudo is zypper-only).
- **Persistent `/nix` volume.** A named volume `dctl-nix-store-$USER` (declared in the `nix`
  devcontainer layer) holds the store; it is shared across sandboxes and survives weekly image
  rebuilds. The image pre-owns `/nix` (`mkdir -m 0755 /nix && chown $USER`) so a fresh empty volume
  inherits non-root ownership on first mount — enabling the daemonless install with no root.
- **Bootstrap at container-create.** The `nix` layer's `onCreateCommand` runs `nix-bootstrap.sh`,
  which (1) installs Nix if the profile is missing and (2)
  `nix profile install /opt/dctl/global-flake#default`. Both steps are idempotent.

### Ephemeral `$HOME` vs persistent `/nix`

The store, db, profiles and gcroots live on the volume and persist. But `~/.nix-profile` (a symlink)
and `~/.local/state/nix` live in the container's ephemeral layer and vanish on recreate. So the
bootstrap detects install via the **profile path** (`~/.nix-profile/etc/profile.d/nix.sh`), **not**
`command -v nix`, and re-runs the installer to self-heal the symlink (cheap — it skips store paths
already on the volume). Never set `use-xdg-base-directories` (it would move the profile off the
volume).

## The global toolset flake

`images/agents/global-flake/flake.nix` is a `buildEnv` (`config.allowUnfree = true` for
`claude-code`) exposing every global CLI: agent CLIs (`claude-code codex opencode
gemini-cli`),
shell UX (`starship zoxide eza bat fzf ripgrep fd yq-go neovim …`), linters
(`dprint taplo typos gitleaks shellharden ripsecrets ast-grep`), and `direnv`/`nix-direnv`. **Commit
its `flake.lock`** (generate on a host with Nix) and bump it deliberately on the weekly rebuild —
`claude-code`/`codex` ship ~weekly and lag nixpkgs; for a fresher Claude Code, add
`sadjow/claude-code-nix` as an input.

## Baked image config

- `/etc/nix/nix.conf`: `experimental-features = nix-command flakes`, **`build-users-group =`**
  (empty — required for single-user), `sandbox = false`, `ssl-cert-file = /etc/ssl/ca-bundle.pem`
  (the openSUSE curl-77 fix, which recurs in the Tumbleweed-based container), binary caches.
- `~/.config/direnv/direnv.toml`: `[whitelist] prefix = ["/workspaces/", "~/Projects/"]` so freshly
  bind-mounted project `.envrc` files are trusted **without `direnv allow`**.
- `~/.config/direnv/direnvrc`: sources `~/.nix-profile/share/nix-direnv/direnvrc` (wires `use flake`
  without Home Manager).

## Auto-activation on `dctl ws shell`

The requirement: entering a container shell at the project dir brings the devShell up automatically.
How it works:

- The base image deletes `~/.bashrc`; the `shell` layer mounts the dotfiles `~/.bashrc`
  - `bash/.config/bash`, whose `.bashrc` sources `rc.d/*.bash` **only when interactive**.
    `rc.d/01-nix.bash` puts single-user Nix on PATH, then `rc.d/30-direnv.bash` runs
    `eval "$(direnv hook bash)"`.
- `dctl ws shell` (no args) → `devcontainer exec … bash` = an **interactive** bash in
  `/workspaces/<proj>`. The direnv `PROMPT_COMMAND` hook fires before the first prompt → the
  whitelisted `.envrc` (`use flake`) loads the devShell. No `direnv allow` needed.
- **Non-interactive** command forms (`bash -ic 'cmd'`, `bash -lc 'cmd'`, lifecycle hooks) never draw
  a prompt, so the hook does not fire. Those must call **`direnv exec .`** explicitly. dctl's
  lifecycle hooks use the guarded pattern
  `bash -lc 'if [ -e .envrc ]; then direnv exec . <cmd>; fi'`, which uses the project toolchain when
  a flake exists and **no-ops gracefully** for flake-less projects. (For login shells,
  `/etc/profile.d/00-dctl-nix.sh` puts Nix on PATH, since the mounted `~/.bashrc` bails early for
  non-interactive shells.)

## Boundary: one image, deps in project flakes

There is a **single `agents` image** — zypper ABI/build/bootstrap libs + `direnv`; Nix owns
everything else. There are no per-language images: every stack inherits `agents`, and each project's
flake supplies its toolchain **and** any native/system deps:

- **Python**: `python` + `poetry` from the flake; native C-ext build deps (e.g. `swig`, `openssl`,
  `pkg-config`) go in the flake's `packages`/`buildInputs` (see the commented lines in
  [templates/python/flake.nix](templates/python/flake.nix)).
- **Node**: `nodejs` + `pnpm` from the flake. Playwright browser **system libs** come from the flake
  too (e.g. `pkgs.playwright-driver.browsers` + `PLAYWRIGHT_BROWSERS_PATH`, or the individual libs
  in `buildInputs`); browser binaries via `npx playwright install`.
- **Rust**: toolchain via oxalica reading `rust-toolchain.toml` (see
  [03-rust-toolchain](03-rust-toolchain.md)); `-sys` crates get `pkg-config` + libs in the flake.
- **Zig**: `zig` + `zls` from the flake.

Rule: native/system libraries a project needs live in that project's flake devShell — keeping the
image single and the deps reproducible.

## Gotchas

- **/nix volume ownership** only initializes from the image mountpoint on the _first_ mount of an
  _empty_ named volume; a root-first-write breaks it and zypper-only sudo can't fix it — destroy and
  recreate the volume.
- **First-ever create** downloads the whole global toolset (minutes); later creates are fast (volume
  warm).
- **nix-direnv gcroots**: don't `rm .direnv`; avoid `nix-collect-garbage -d`.
