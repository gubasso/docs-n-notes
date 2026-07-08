# Runbook — bootstrap a new Rust project

The ordered, **once-per-project** Rust-specific steps, overlaying the general spine. Each step links
to the chapter that explains the _why_; this page is only the _what_ and _in what order_.

Do the general steps first (repo, license, governance, dev env, CI, security) from the
[general runbook](../../../programming/project-bootstrap/runbook.md); the steps below are the Rust
overlay that slots into it.

## Prerequisites

- The [general bootstrap runbook](../../../programming/project-bootstrap/runbook.md) is understood —
  repo created, foundations and governance in place.
- A Nix devShell exists (or will) to host the toolchain — see
  [nix/03-rust-toolchain](../../../tools/nix/03-rust-toolchain.md).

## Steps

1. **Scaffold the crate.** `cargo new <name>` for a binary or `cargo new --lib <name>` for a library
   (`cargo init` in an existing dir). → [00 — Toolchain & layout](00-toolchain-and-layout.md).
   _Automate:_ `bootstrap-rust`.

2. **Pin the toolchain.** Add a `rust-toolchain.toml` and wire it into the Nix devShell so local and
   CI use the same Rust version. → [00 — Toolchain & layout](00-toolchain-and-layout.md),
   [nix/03-rust-toolchain](../../../tools/nix/03-rust-toolchain.md).

3. **Configure quality gates.** `rustfmt.toml`, `clippy` with denied lints, and `cargo-deny` /
   `cargo-audit` for the security baseline. → [01 — Quality gates](01-quality-gates.md).

4. **Pick the implementation kind.** For a CLI, follow [`cli-project.md`](cli-project.md); other
   kinds are followups.

5. **Continue the general spine.** Return to the
   [general runbook](../../../programming/project-bootstrap/runbook.md) for governance, CI, and
   security if not already done.

6. **When ready to release,** hand off to
   [`../release-workflow-spec/runbook.md`](../release-workflow-spec/runbook.md) — the later Rust
   release phase (release-plz, Trusted Publishing, cargo-dist).

## Reference

- [00 — Toolchain & layout](00-toolchain-and-layout.md) · [01 — Quality gates](01-quality-gates.md)
  · [general runbook](../../../programming/project-bootstrap/runbook.md) ·
  [`../cli-spec/`](../cli-spec/README.md)
