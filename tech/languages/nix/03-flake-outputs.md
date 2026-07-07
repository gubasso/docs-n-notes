# Flake Output Schema

> $nix $nix-flakes

The standard outputs Nix understands. Most are keyed by system; `.default` is used when you omit
`#name`.

| Output                       | What                                 | Invoked by                            |
| ---------------------------- | ------------------------------------ | ------------------------------------- |
| `packages.<sys>.<name>`      | Buildable derivations                | `nix build .#name`                    |
| `devShells.<sys>.<name>`     | Dev environments                     | `nix develop .#name`                  |
| `apps.<sys>.<name>`          | Runnable program (path + type)       | `nix run .#name`                      |
| `checks.<sys>.<name>`        | Must build/pass in `nix flake check` | CI                                    |
| `formatter.<sys>`            | Formatter for `nix fmt`              | `nix fmt`                             |
| `overlays.<name>`            | Function extending nixpkgs           | other flakes                          |
| `nixosModules.<name>`        | Reusable NixOS module                | imported by a system                  |
| `nixosConfigurations.<host>` | A whole machine                      | `nixos-rebuild switch --flake .#host` |
| `homeConfigurations.<name>`  | Home Manager user config             | `home-manager switch --flake .#name`  |
| `templates.<name>`           | Project scaffold                     | `nix flake init -t <flake>#name`      |
| `lib`                        | Pure functions you expose            | `theirflake.lib.foo`                  |

> `nixosConfigurations` and `homeConfigurations` are **NOT** per-system — the system is baked inside
> them.

## A real `packages.default` (Rust example)

```nix
packages.default = pkgs.rustPlatform.buildRustPackage {
  pname = "podbox";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
};
# → nix build produces ./result/bin/podbox
```

Other ecosystems: `buildGoModule`, `buildNpmPackage`, or the generic base `stdenv.mkDerivation`.

## An `apps.default`

```nix
apps.x86_64-linux.default = {
  type = "app";
  program = "${self.packages.x86_64-linux.default}/bin/podbox";
};
```
