# MicroVMs vs Containers: Containers Are Not Isolation

> Clipping / notes on:
> [MicroVM Isolation in 2026 — Emir B.](https://emirb.github.io/blog/microvm-2026/)

## Thesis

> "Containers are not a security boundary. They are a mechanism to control resource usage."

Containers share the host kernel (~40M lines of C, 450+ syscalls) — that is the attack surface. 8
container-escape CVEs in 18 months show the risk is real, not theoretical. MicroVMs enforce
isolation in hardware (KVM), making escapes orders of magnitude rarer (escape bounties:
$250K–$500K).

## Why now

- **Performance objection is dead:** microVMs boot in ~125ms with \<5 MiB overhead.
- **AI workloads are the catalyst:** LLM agents executing untrusted code created urgent demand for
  stronger-than-container isolation. The microVM tech (battle-tested in AWS Lambda, Fly.io for
  years) was already mature.

## Key tech

**VMMs (built on the rust-vmm ecosystem):**

- **Firecracker** — ~83K LOC Rust, minimal, ephemeral workloads, AWS Lambda standard.
- **Cloud Hypervisor** — ~106K LOC, richer features (nested KVM, GPU passthrough, Windows).

**AI sandbox platforms using microVMs:** E2B, Vercel Sandbox, Fly.io Sprites, Docker Sandboxes, Ona.
Modal uses gVisor (userspace kernel, Google) instead.

**Kubernetes integrations bringing hardware isolation:**

- **Kata Containers** — OCI runtime wrapping microVMs.
- **Edera** — Type-1 hypervisor + Falco runtime security.
- **KubeVirt** — full VMs as pods.

## Takeaway

The winning pattern is **container-inside-VM**: containers for dev ergonomics + packaging, VMs for
actual isolation. Neither replaces the other.

## Why this matters to me

Relevant when thinking about isolating AI dev environments and untrusted code execution — see also
[`isolated-ai-dev-environment-with-systemd-nspawn-dev-sandbox.md`](./isolated-ai-dev-environment-with-systemd-nspawn-dev-sandbox.md).
Containers/nspawn give _resource scoping_; microVMs are the upgrade when the threat model is hostile
code.
