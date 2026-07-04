---
digest-of: tech/infra/sandbox-isolation-backends
last-synced: 2026-07-04
source-files:
  - README.md
  - 00-threat-model-and-principles.md
  - 10-runtimes-catalog.md
  - 20-decision-libkrun-linux.md
  - 30-libkrun-vs-firecracker.md
  - 40-reference-implementations.md
  - 50-native-orchestration-decision.md
  - 60-podman-libkrun-operational-notes.md
  - 90-references.md
token-estimate: 1500
---

# AGENTS

## Scope

Vendor-neutral reference for building a secure, reproducible sandbox that runs untrusted or
AI-agent-generated code inside a KVM-class microVM instead of a shared-kernel container. Covers the
threat model, the runtime/VMM catalog, the libkrun decision and its justification, comparisons,
reference implementations, the orchestration decision, and the operational reality of the
rootless-Podman + `crun --krun` stack. Not tied to any specific product.

## Key Points

- **Primary boundary must be hardware virtualization (KVM / HVF).** Shared-kernel containers are a
  resource-isolation boundary, not a security boundary; namespaces do not stop an adversary on the
  same kernel. Evidence: the November 2025 runc CVE cluster (CVE-2025-31133/-52565/-52881) and the
  ~monthly kernel-LPE cadence, versus hypervisor escapes as a $250K–$500K bug class.
- **Chosen Linux backend: libkrun via `crun --krun`, fronted by rootless Podman.** It gives a
  KVM-class boundary (own guest kernel via `init.krun`/`libkrunfw`) at the lowest owned-plumbing
  cost — `podman run --runtime krun` consumes existing OCI images directly. libkrun v1.18.0
  (2026-04-24); production users RamaLama, Microsandbox, krunvm.
- **Accepted trade-off:** libkrun's host-facing device surface is wider than bare Firecracker's
  (virtio-fs default rootfs, TSI host-side proxy on the host TCP stack, virtio-gpu off by default),
  and it shares the `rust-vmm` lineage (a class bug hits libkrun + Firecracker + Cloud Hypervisor
  together; cf. CVE-2026-5747). Bare Firecracker is the smallest-TCB escape hatch at ~3–5 weeks of
  owned plumbing for the same boundary class.
- **gVisor** is a weaker (userspace-kernel) class — a no-KVM CI fallback only, never the primary
  workstation boundary.
- **Orchestration:** parse `devcontainer.json` natively and drive lifecycle with argv-vector
  `podman exec`. A heavyweight orchestrator whose keep-alive shim is a multi-line `sh -c` entrypoint
  is broken by the libkrun `\n`-mangling bug. Invariant: never emit a multi-line `sh -c` entrypoint
  under `--runtime krun`.
- **Egress** under libkrun's TSI networking is enforced _inside_ the guest (nftables allowlist),
  because TSI removes the host-side network plumbing.

## Source Map

| Topic                                        | File                                     |
| -------------------------------------------- | ---------------------------------------- |
| Index and reading order                      | `README.md`                              |
| Threat model, premises, residual surface     | `00-threat-model-and-principles.md`      |
| Per-option runtime/VMM catalog + matrix      | `10-runtimes-catalog.md`                 |
| libkrun Linux decision and justification     | `20-decision-libkrun-linux.md`           |
| libkrun vs bare Firecracker (flake-pilot)    | `30-libkrun-vs-firecracker.md`           |
| Reference implementations / prior art        | `40-reference-implementations.md`        |
| Native parsing vs heavyweight orchestrator   | `50-native-orchestration-decision.md`    |
| podman+krun operational notes & known issues | `60-podman-libkrun-operational-notes.md` |
| Consolidated bibliography                    | `90-references.md`                       |

## Maintenance Notes

- Content migrated 2026-07-04 from an upstream sandbox-runtime spec set plus two prior docs
  (`podman-libkrun.md`, `libkrun-crun-newline-mangling-upstream-issue.md`) that were removed from
  `tech/infra/containers/` in the same change.
- The upstream `\n`-mangling bug report in `60-*` is drafted but not yet filed; update it with the
  issue URL once filed.
- Regenerate this digest if any numbered doc changes materially; recompute `token-estimate`.
