# Nix — canonical reference

Nix is the **source of truth for developer tooling** on my machines, alongside the distro package
manager (zypper on openSUSE) for system integration. This dir is the canonical, step-by-step
reference: install it once per host, add a flake devShell per project, and let direnv activate it
automatically on `cd`.

## The boundary (three package managers, three jobs)

| Manager              | Owns                                                                                        | Examples                                                                                 |
| -------------------- | ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| **zypper** (distro)  | Kernel, drivers, DE, system services, the Nix daemon itself, ABI/build libs                 | `gcc`, `glibc-devel`, `libopenssl-3-devel`, Playwright browser libs                      |
| **Nix** (this)       | Global user CLIs (lean profile) **+** each project's toolchain & dev tools (flake devShell) | global: `ripgrep`, `neovim`, `starship`; per-project: `python`, `rust`, `just`, `dprint` |
| **language pkg-mgr** | The project's dependency graph (runs _inside_ the devShell)                                 | `cargo`, `poetry`, `pnpm` own their lockfiles                                            |

Rule of thumb: needs root / boot / hardware / display → **zypper**. A user CLI or a project runtime
→ **Nix**. A library your code imports → the **language's** manager, invoked inside the Nix
devShell. Nix does **not** replace the language package manager (no poetry2nix / cargo2nix unless
you deliberately want Nix to _build_ the app).

Within Nix there's a second split — **lean global / rich per-project**. A small **global profile**
(via `nix profile` or Home Manager) holds only the CLIs you want in _every_ shell (`ripgrep`,
`neovim`, `starship`, agent CLIs). Everything a _specific_ project needs — its language toolchain
**and** its task runners, linters, formatters, and pre-commit hook tools (`just`, `dprint`,
`pre-commit`, …) — lives in that project's **flake devShell**, pinned per repo. Keep the global
profile lean: if only some projects need a tool, or it wants a project-pinned version, it belongs in
their flake, not the profile.

## Read in order

1. [00-overview](00-overview.md) — concepts, the three files, mental model.
2. [01-install-opensuse](01-install-opensuse.md) — host install (openSUSE daemon, NixOS).
3. [02-per-project-devshell](02-per-project-devshell.md) — flake + `.envrc` + direnv; the
   Poetry-venv layer.
4. [03-rust-toolchain](03-rust-toolchain.md) — the hybrid `rust-toolchain.toml` + oxalica approach.
5. [04-migrate-a-project](04-migrate-a-project.md) — step-by-step to move one repo off mise/rustup.

Copy-paste starting points live in [`templates/`](templates/) (python, rust, node, zig, generic).

## Related

- [development-tools-workflow](../../workflows/development-tools-workflow.md) — the three-role split
  (environment / dependencies / tasks).
- [mise](../../workflows/mise.md) — fallback tool-version manager for hosts where a flake is
  overkill.
- Language notes: [rust](../../languages/rust/), [python](../../languages/python/),
  [zig](../../languages/zig/).
