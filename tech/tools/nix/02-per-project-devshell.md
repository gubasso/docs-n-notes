# 02 — Per-project devShell (flake + `.envrc` + direnv)

## Automatic activation (direnv)

`.envrc` only auto-loads if **direnv is hooked into your shell** — this is the piece people miss
(without it nothing activates on `cd`). Install direnv + nix-direnv and add the hook once,
host-level, not per-project:

```bash
# install direnv + nix-direnv (OS package or Home Manager `programs.direnv`), then
# hook the shell — for bash, in ~/.bashrc (zsh/fish have their own hook line):
eval "$(direnv hook bash)"
```

nix-direnv caches the flake evaluation so re-entry is fast. On NixOS / Home Manager,
`programs.direnv = { enable = true; nix-direnv.enable = true; };` installs the hook for you. (In
dctl sandboxes both the hook and a `[whitelist]` prefix are baked in.)

## Enter the shell

```bash
nix develop          # explicit, one-off
direnv allow         # once; nix-direnv then auto-enters on cd (.envrc = use flake)
```

## Minimal `flake.nix`

Values in angle brackets are placeholders. Copy-paste starting points per language are in
[`templates/`](templates/).

```nix
{
  description = "<project> dev shell";

  inputs = {
    # nixos-unstable = rolling branch (better-tested than nixpkgs-unstable);
    # or pin a stable release, e.g. nixos-26.05. Avoid the bare `nixpkgs`
    # registry shorthand — it resolves per-machine and is not reproducible.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.<language-runtime>   # e.g. python314, nodejs_22, zig
            pkgs.<package-manager>    # e.g. poetry, pnpm
          ];
          shellHook = ''echo "dev shell ready"'';
        };
      });
}
```

## Layering a language venv (Python / Poetry)

`use flake` puts `python`/`poetry` on PATH; layer the project's Poetry venv on top so
console-scripts resolve without a manual activation. `layout poetry` is **not** in direnv's stdlib,
so inline the logic in `.envrc`:

```bash
use flake

# use flake must stay first — it provides `poetry`. `poetry env info --path` locates
# the venv (stable on Poetry 1.x/2.x; works for in-project .venv or the cache dir).
watch_file pyproject.toml poetry.lock
venv="$(poetry env info --path 2>/dev/null || true)"
if [[ -n "$venv" && -d "$venv" ]]; then
  export VIRTUAL_ENV="$venv"
  export POETRY_ACTIVE=1
  PATH_add "$venv/bin"
fi
```

Do **not** use `poetry shell` or `eval "$(poetry env activate)"` — neither fits direnv, which
mutates PATH declaratively and reverses it on `cd` out. The venv must exist first
(`poetry install`); after creating it, run `direnv reload`.

## Git hooks (pre-commit)

`pre-commit` is **per-project**, not a global tool: declare it — and any `language: system` hook
tools it shells out to (`dprint`, `taplo`, `typos`, `ruff`, …) — in the project's devShell, so hooks
run with the same pinned toolchain as the shell and CI. pre-commit self-manages
`language: python|node|rust|…` hook environments, so only `system` hooks need their tool on the
devShell PATH.

```nix
devShells.default = pkgs.mkShell {
  packages = [
    pkgs.pre-commit
    pkgs.dprint # a `language: system` hook tool → must be on PATH
  ];
};
```

Install the git hook once inside the shell (idempotent):

```bash
pre-commit install
```

Make it automatic on shell entry with a `shellHook` running `pre-commit install`, or go fully
Nix-native with [cachix/git-hooks.nix](https://github.com/cachix/git-hooks.nix) (formerly
`pre-commit-hooks.nix`), which generates `.pre-commit-config.yaml` from Nix and installs the hook
from the devShell's `shellHook`. In a sandbox that auto-activates direnv (e.g. dctl), a
non-interactive lifecycle step must call it project-scoped: `direnv exec . pre-commit install`.

## Maintaining the pin

```bash
nix flake lock              # generate flake.lock the first time (needs network)
nix flake update            # bump ALL inputs
nix flake update nixpkgs    # bump one input only
```

## Notes

- Ignore `.direnv/` and `/result` in `.gitignore`.
- Nix supplies runtimes and non-language system tools; it does **not** replace the project's package
  manager by default (no poetry2nix / cargo2nix unless you specifically want Nix to build the app).
- Offline / no-nix host: author `flake.nix` + `.envrc`, but `flake.lock` can only be generated where
  `nix` and network are available. **Do not fabricate a lock.**
