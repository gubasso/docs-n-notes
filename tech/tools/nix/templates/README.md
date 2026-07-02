# Templates

Copy the matching dir's files into a project root, tune the runtime, then `nix flake lock` on a host
with Nix. See [../05-migrate-a-project](../05-migrate-a-project.md).

| Dir        | For             | Files                                              |
| ---------- | --------------- | -------------------------------------------------- |
| `python/`  | Python + Poetry | `flake.nix`, `.envrc` (with the Poetry-venv layer) |
| `rust/`    | Rust (hybrid)   | `flake.nix`, `.envrc`, `rust-toolchain.toml`       |
| `node/`    | Node + pnpm     | `flake.nix`, `.envrc`                              |
| `zig/`     | Zig + zls       | `flake.nix`, `.envrc`                              |
| `generic/` | Anything else   | `flake.nix`, `.envrc`                              |

`flake.lock` is intentionally **not** shipped — generate it per project (`nix flake lock`).
