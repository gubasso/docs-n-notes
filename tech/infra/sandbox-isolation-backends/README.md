# Sandbox / isolation backends

A vendor-neutral reference for building a **secure, reproducible sandbox** that runs untrusted or
AI-agent-generated code inside a **KVM-class microVM** rather than a shared-kernel container. It
covers the threat model, the full runtime/VMM catalog, the decision to use libkrun (`crun --krun`)
on rootless Podman as the primary Linux backend, the comparisons that justify it, real reference
implementations, the orchestration decision, and the operational potholes of the podman+krun stack.

Nothing here is tied to a specific implementation — the material is a spec anyone could use to build
a backend in any language (Rust, Go, shell wrappers) or architecture.

## Contents

- [00-threat-model-and-principles](./00-threat-model-and-principles.md) — premises, why namespaces
  are not a security boundary, the AI-agent threat model, residual host-kernel surface under
  hardware virtualization, and the selection criteria. **Start here.**
- [10-runtimes-catalog](./10-runtimes-catalog.md) — the per-option encyclopedia: shared-kernel
  containers, gVisor, the hardware-virt microVMs (Firecracker, Kata+FC, Kata+CH, libkrun, QEMU,
  Apple `container`), and specialized/wrong-shaped options, each with a verdict, plus a comparison
  matrix.
- [20-decision-libkrun-linux](./20-decision-libkrun-linux.md) — why libkrun via `crun --krun` on
  rootless Podman is the primary Linux backend: criteria, device-surface analysis, why-not
  Kata/bare-FC/gVisor-primary, the egress-enforcement pattern, and risks accepted.
- [30-libkrun-vs-firecracker](./30-libkrun-vs-firecracker.md) — libkrun vs bare Firecracker (via
  flake-pilot): same KVM class, different engineering cost, networking, and distribution model.
- [40-reference-implementations](./40-reference-implementations.md) — prior art of the
  libkrun-on-Podman pattern: `val4oss/ai-agents-sandbox`, RamaLama, Microsandbox, krunvm.
- [50-native-orchestration-decision](./50-native-orchestration-decision.md) — why to parse
  `devcontainer.json` natively and use argv-vector exec instead of a heavyweight orchestrator whose
  multi-line `sh -c` shim breaks under `crun --krun`.
- [60-podman-libkrun-operational-notes](./60-podman-libkrun-operational-notes.md) — living
  operational reference for rootless `podman run --runtime krun`: environment baseline, the
  `\n`-mangling bug (KI-01) and its orchestrator fallout (KI-02), working patterns, and the drafted
  upstream bug report.
- [90-references](./90-references.md) — consolidated bibliography.

## Reading order

- **First-time / why microVMs at all:** `00` → `10` → `20`.
- **"Why libkrun and not X":** `20`, then `30` (vs Firecracker) and the catalog `10`.
- **Building an implementation:** `40` (prior art) → `50` (orchestration) → `60` (the potholes).
- **Just hit a krun bug:** jump to `60`.
