# NixOS Modules & Home Manager

> $nix $nixos $home-manager

A NixOS machine is defined by **modules**. This is a second declarative layer built on the language
from `01-language-basics.md`.

## A module = a function returning `imports` / `options` / `config`

```nix
{ config, pkgs, lib, ... }:        # standard module args
{
  imports = [ ./other.nix ];       # pull in more modules

  options = {                      # DECLARE new settings (only if authoring a module)
    services.myapp.enable = lib.mkEnableOption "my app";
  };

  config = {                       # ASSIGN values to options
    services.openssh.enable = true;
    environment.systemPackages = [ pkgs.vim pkgs.git ];
    networking.hostName = "podbox-host";
  };
}
```

Mental model: **`options` declare what settings exist; `config` sets them.** NixOS _merges_ the
`config` from hundreds of modules into one giant `config` set — that's what
`config.services.openssh.enable` reads back.

## Priority / conditional helpers (needed because of merging)

```nix
lib.mkDefault x    # low priority — an overridable default
lib.mkForce   x    # high priority — wins over normal assignments
lib.mkIf cond { …} # include this config block only when cond
lib.mkOption  { …} # define an option's type/default/description
```

## `configuration.nix`

The classic entry module (`/etc/nixos/configuration.nix` on a normal install): one
`{ config, pkgs, ... }: { ... }` describing the whole system — bootloader, users, services,
packages, kernel.

## Flake for a machine

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";   # pin a RELEASE branch
  outputs = { self, nixpkgs }: {
    nixosConfigurations.mylaptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix ];
    };
  };
}
# deploy:  sudo nixos-rebuild switch --flake .#mylaptop
```

## Home Manager (per-user, declarative dotfiles) — works on NixOS + plain Linux/macOS

```nix
homeConfigurations."gustavo" = home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  modules = [{
    home.packages = [ pkgs.ripgrep ];
    programs.git.enable = true;
    programs.git.userName = "Gustavo Basso";
  }];
};
# deploy:  home-manager switch --flake .#gustavo
```

Same module system, same `options`/`config` idea.
