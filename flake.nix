{
  description = "docs-n-notes dev shell (documentation SoT: markdown notes + generated AGENTS.md)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.just         # per-project task runner
            pkgs.pre-commit   # drives .pre-commit-config.yaml hooks
            pkgs.dprint       # markdown formatter (the `language: system` hook binary)
          ];
          shellHook = ''echo "docs-n-notes dev shell ready"'';
        };
      }
    );
}
