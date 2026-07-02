# 04 — Migrate one project off mise/rustup onto a Nix devShell

Do this per-project, incrementally. The dctl images already provide Nix + direnv; this just adds the
three files to a repo.

## Steps

1. **Pick the template.** Copy from [`templates/`](templates/) into the repo root:
   - Python (Poetry) → `templates/python/{flake.nix,.envrc}`
   - Rust → `templates/rust/{flake.nix,.envrc}` (keep the repo's existing `rust-toolchain.toml`)
   - Node → `templates/node/{flake.nix,.envrc}`
   - Zig → `templates/zig/{flake.nix,.envrc}`
   - Anything else → `templates/generic/{flake.nix,.envrc}`

2. **Tune `flake.nix`** to the runtime the project needs (e.g. `python314` vs `python312`,
   `nodejs_22`, add `pkgs.<system-lib>` for native builds).

3. **Generate the lock** on a host with Nix + network (never fabricate it):
   ```bash
   nix flake lock
   ```

4. **`.gitignore`** `/.direnv/` and `/result`.

5. **Trust + enter** (host): `direnv allow`. In a dctl sandbox it's trusted automatically by the
   whitelist — just `cd` in.

6. **Install deps inside the shell** (the language manager still owns them):
   ```bash
   poetry install        # or: pnpm install / cargo build
   pre-commit install
   direnv reload          # Python: re-scan so the venv layers onto PATH
   ```

7. **Drop non-Nix provisioning**: delete any `mise.toml` / `.tool-versions`, drop `mise install` /
   `rustup` steps from project scripts or CI, and point CI at the flake
   (`nix develop --command <task>`) or install the toolchain the flake pins.

8. **Verify**: open a fresh shell, `cd` in, confirm the runtime resolves into the Nix store
   (`which python` / `cargo --version` matches the pin) with no manual activation.

## dctl specifics

- Once the repo has `flake.nix` + `.envrc`, the dctl lifecycle hooks
  (`direnv exec . poetry install`, etc.) light up automatically; before that they no-op.
- Rust: keep `rust-toolchain.toml` — the flake reads it (see
  [03-rust-toolchain](03-rust-toolchain.md)); no `~/.rustup` volume anymore.
