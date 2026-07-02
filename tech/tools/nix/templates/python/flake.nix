{
  description = "python (poetry) dev shell";

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
            # Match your project's requires-python (nixos-unstable ships 3.14;
            # drop to python313/python312 if the project floor predates it).
            pkgs.python314
            pkgs.poetry
            pkgs.pre-commit
            pkgs.just
            # native build deps for C-extensions, uncomment as needed:
            # pkgs.swig pkgs.openssl pkgs.pkg-config
          ];
          shellHook = ''echo "dev shell ready — run: poetry install"'';
        };
      }
    );
}
