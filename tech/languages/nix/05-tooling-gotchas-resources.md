# Tooling, Gotchas & Resources

> $nix $nix-lang

## Tooling you'll keep meeting

- `nix flake show` — print any flake's output tree (best learning tool).
- `nix repl` → `:lf .` — interactive; poke at `outputs`, `pkgs`, `lib`.
- `nix shell nixpkgs#hello` / `nix run nixpkgs#cowsay` — ad-hoc env / one-off run.
- `nix path-info -S ./result` / `nix why-depends` — closure size & dependency debugging.
- `nix build .#x --print-build-logs` — see full build logs.
- **direnv + nix-direnv** — auto-load `nix develop` on `cd` (`.envrc` = `use flake`).

### Ecosystem inputs you'll see in bigger repos

- `flake-parts` — module-system way to structure large flakes (modern standard for complex projects;
  step up from `flake-utils`).
- `flake-utils` — lightweight per-system helper.
- `crane` / `naersk` — better Rust builds than `buildRustPackage`.
- `rust-overlay` / `fenix` — Rust toolchains.
- `treefmt-nix` — multi-language formatting; `pre-commit-hooks.nix` — git hooks.
- `devenv` — batteries-included dev environments.

## Gotchas that bite newcomers

1. **Flakes only see git-tracked files.** New/untracked files are invisible to `src = ./.;` builds.
   `git add` them (even `git add -N`).
2. **Pinning matters — commit `flake.lock`.** It's what makes builds reproducible.
   `nix flake update` bumps everything; `--update-input <x>` bumps one.
3. **Two nixpkgs = trouble.** Use `inputs.<x>.inputs.nixpkgs.follows = "nixpkgs"`.
4. **`//` is shallow**, not a deep merge (use `lib.recursiveUpdate` for deep).
5. **`if` requires `else`** — it's an expression, must yield a value both ways.
6. **Pure evaluation.** No current time, no arbitrary env vars, no undeclared network fetches during
   flake eval — the price (and point) of reproducibility.
7. **`nixos-unstable` vs `nixos-24.11`** — rolling vs stable release; pin a release branch for
   machines, unstable is fine for dev shells.
8. **Eval ≠ build ≠ runtime.** Evaluating produces a _description_; building realizes derivations;
   `shellHook`/`apps` run later. A stored bash string isn't executed at eval.

## Best resources (roughly in order)

- **[nix.dev](https://nix.dev)** — modern, maintained tutorials. Start here.
- **[Zero to Nix](https://zero-to-nix.com)** (Determinate Systems) — friendliest flakes-first intro.
- **Reference manuals** — [Nix](https://nixos.org/manual/nix/stable/),
  [Nixpkgs](https://nixos.org/manual/nixpkgs/stable/),
  [NixOS](https://nixos.org/manual/nixos/stable/).
- **[Nix Pills](https://nixos.org/guides/nix-pills/)** — deeper derivation-level model.
- **Search (daily):** [search.nixos.org](https://search.nixos.org) — packages **and** NixOS options;
  [Noogle](https://noogle.dev) — search `lib`/`builtins` by name.
- **[Flakes wiki](https://nixos.wiki/wiki/Flakes)**;
  **[Home Manager options](https://home-manager-options.extranix.com/)**.
- **Community:** [discourse.nixos.org](https://discourse.nixos.org); read real `flake.nix` files on
  GitHub ("nixos configuration flake") to absorb idioms.
