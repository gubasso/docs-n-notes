# Threat model and first principles for sandboxing untrusted code

> The premises and threat model that motivate everything else in this shelf. Read this first; the
> runtime catalog ([10-runtimes-catalog.md](10-runtimes-catalog.md)) and the libkrun decision
> ([20-decision-libkrun-linux.md](20-decision-libkrun-linux.md)) are downstream of the reasoning
> here.

## 0. Purpose — the workload being isolated

The motivating use case is a **secure, reproducible sandbox for running AI coding agents** (Claude
Code, Codex CLI, Gemini CLI, and similar) or, more generally, any process that executes
attacker-influenced code. These agents run model-generated commands against arbitrary repository
content, untrusted dependencies, and remote services. **They must be assumed to be executing
attacker-controlled code at all times** — through prompt injection from scraped documentation,
dependency READMEs, untrusted tool output, or `npm install` post-install scripts.

This document states what such a sandbox must achieve, the threat model it faces, and the principles
that determine which isolation boundaries are acceptable. It is written for anyone building a
sandbox backend — in any language, with any orchestration wrapper — not for one specific tool.

## 1. Premises

This section is load-bearing. Every later decision in this shelf must be traceable to a premise
here; any deviation must be called out explicitly.

### 1.1 Functional premises (what the sandbox must achieve)

- **Hardware-virtualization boundary against adversarial code.** A serious attempt at host
  compromise must require a hypervisor-class bug, not a routine syscall trick or a known kernel CVE.
  Anything weaker than a KVM-class boundary (or a platform equivalent such as Apple
  Virtualization.framework) is unacceptable as the _primary_ isolation, regardless of how cleanly it
  integrates.
- **Cross-platform.** Linux is the primary target. macOS is a first-class secondary target. Windows
  is best-effort via WSL2.
- **OCI-image-driven authoring surface.** Existing OCI images (Containerfiles) and the
  `devcontainer.json` schema are the user-authoring surface. The runtime may convert OCI images into
  other formats internally (rootfs tarballs, ext4, and so on); the user never authors anything other
  than OCI/devcontainer artifacts.
- **Acceptable cold-start.** A few hundred milliseconds to a few seconds to bring a workspace up.
  Sub-second is preferred; multi-second is the upper bound for laptop ergonomics.

### 1.2 Security goals

- The host kernel **must not** be reachable from agent-executed code through anything weaker than a
  hypercall + KVM (or HVF) boundary.
- A single container/runtime/kernel CVE **must not** be a host-compromise event by itself.
- Long-lived OAuth tokens (`gh`, `glab`, model-provider session tokens) **must not** be live-mounted
  into the agent. Forwarding is short-lived, scoped, and ephemeral.
- Default container egress **must** be allowlisted to model APIs, package mirrors, and the user's
  git remotes; everything else is denied by default.
- The host `/tmp` **must not** be bind-mounted into the agent.
- `no-new-privileges` and `--cap-drop=ALL` are present in the default run arguments.

### 1.3 Ergonomics premises

- The user-facing schema (`devcontainer.json`, composition layers, leaf-project overrides) is
  **runtime-agnostic** — it does not name a runtime.
- Runtime selection composes through the same precedence as other config keys: leaf-project pin →
  user default → environment / flag override.
- **A thin per-runtime adapter is the only place runtime-specific code lives.** Everything else in
  the tool stays runtime-agnostic. The adapter implements a small interface (run, exec, ps, rm,
  build); swapping runtimes is swapping one adapter module.
- Workflows stay simple, declarative, composable, and shareable across machines and teams.
- It is acceptable to **implement parts of the build/run plumbing yourself** if that buys a stronger
  boundary — provided the scope is bounded and the user-facing surface stays declarative. See the
  bare-Firecracker cost estimate in [10-runtimes-catalog.md](10-runtimes-catalog.md) (~3–5 weeks
  one-time plus ongoing rootfs/kernel maintenance).

### 1.4 Anti-premises (what is explicitly rejected)

- **Bare containers (rootful or rootless) as the primary boundary.** See §1.5. Hardened seccomp,
  AppArmor, and `cap-drop` are defense-in-depth, not the boundary.
- **`--privileged`, container-socket bind-mount, `--cap-add` for non-essential capabilities.**
  Disallowed across all configurations.
- **A runtime that requires re-implementing the OCI ecosystem from scratch** with a permanent
  maintenance burden the size of containerd. Targeted plumbing (rootfs builder, in-guest init, vsock
  channel) is acceptable; rebuilding containerd is not.
- **Hardware-attested isolation against the host (Confidential Containers / TDX / SEV-SNP)** as the
  threat-model framing. The host is trusted; the workload is not. The problem is workload isolation,
  not host distrust.
- **Language-level sandboxes** (V8 isolates, WebAssembly) as the boundary. They cannot host the
  agent's full toolchain (`pytest`, `cargo`, `git`, native compilers).
- **CI-only / cluster-only runtimes** (firecracker-containerd, flintlock, AWS Nomad FC driver) as
  the laptop default. Useful as components; wrong shape for a per-developer CLI.
- **Larger-TCB hypervisors when a smaller-TCB one is available.** Full-fat QEMU is rejected as the
  laptop default for this reason; see [10-runtimes-catalog.md](10-runtimes-catalog.md).

### 1.5 Why bare containers are insufficient

The shared-kernel container model is a resource-isolation boundary, not a security boundary. Three
observations make it unacceptable as the _primary_ boundary for the AI-agent threat model:

1. **Recurring container breakouts.** November 2025 alone produced **three back-to-back runc CVEs**
   — CVE-2025-31133, CVE-2025-52565, CVE-2025-52881 — each delivering full container breakout via
   mount races and procfs symlink tricks. These affect **Podman, Kubernetes, and every other
   runc-based runtime alike**. See the
   [Sysdig analysis](https://www.sysdig.com/blog/runc-container-escape-vulnerabilities) and the
   [CNCF technical overview](https://www.cncf.io/blog/2025/11/28/runc-container-breakout-vulnerabilities-a-technical-overview/).
2. **Kernel LPE cadence.** Linux kernel local-privilege-escalation surfaces at roughly monthly
   cadence (bpf, io_uring, netfilter, page-cache aging, and so on). Each one is a host compromise on
   shared-kernel runtimes. Hypervisor escapes, by contrast, are a $250K–$500K bug class (see
   [emirb — MicroVM Isolation in 2026](https://emirb.github.io/blog/microvm-2026/)).
3. **Namespaces are a resource-control mechanism, not a security boundary.** This is a design fact,
   not a bug. Namespaces let the kernel partition resources for non-malicious tenants; they do not
   constitute a barrier against an adversary running code on the same kernel.

Rootless mode reduces _blast radius_ (an escape lands as the invoking user instead of host root) but
does not change the _probability_: every kernel LPE still lands on the host, and the November 2025
runc CVEs explicitly affect rootless Podman. Rootless Podman remains valuable as a **controller
around** a microVM (see libkrun + `crun --krun` in
[10-runtimes-catalog.md](10-runtimes-catalog.md)); it is not the boundary.

## 2. Defense-in-depth posture inside the boundary

The hardware boundary is the primary control, but the container configuration _inside_ the microVM
should still be hardened — a compromise inside the guest should gain as little as possible before it
even reaches the (much harder) hypervisor boundary. A sound posture:

- **Non-root from PID 1.** The image creates a normal user with host-matched UID/GID; the runtime
  sets `remoteUser`.
- **Narrowed sudo.** Passwordless sudo only for the package manager (or nothing), never
  `NOPASSWD: ALL`. A crafted local package `%post` script can still gain root _inside_ the guest,
  which is acceptable precisely because the surrounding boundary is a microVM, not the host kernel.
- **`--cap-drop=ALL` and `--security-opt=no-new-privileges`** in the default run arguments.
- **Strict seccomp/AppArmor by default.** A permissive profile is an explicit, named opt-in (for
  example to host an inner `bwrap` sandbox), never the default.
- **No long-lived OAuth token directories bind-mounted.** Tokens are forwarded as short-lived
  environment values (`GH_TOKEN`, `GITLAB_TOKEN`) or copied into a per-session ephemeral tmpdir,
  never as a live mount of `~/.config/gh`, `~/.claude*`, and similar.
- **`/tmp` is a tmpfs**, never a host bind.
- **Egress allowlisted by default** — only model APIs, package mirrors, and the workspace's git
  remotes are reachable. Under libkrun's TSI networking this policy lives _inside_ the guest as an
  nftables ruleset; see [20-decision-libkrun-linux.md](20-decision-libkrun-linux.md).
- **Per-workspace identity.** Each container carries a workspace-folder label so that work-clones of
  the same repository produce distinct containers.

Once the outer boundary is a hypervisor, the _inner_ constraints can be relaxed with confidence
(package installs, nested container runtimes, build sandboxes) because the boundary is a hypervisor
rather than a syscall filter.

## 3. Threat model

The workload is **AI agents executing model-generated commands**. Every command must be treated as
if it originated from an adversary. The realistic attack tree, in order of frequency and skill
required:

### 3.1 Token exfiltration without escape (highest frequency, lowest skill)

The agent reads token files and environment values that are mounted/injected by design
(`~/.config/gh/hosts.yml`, model-provider credential files, `$GH_TOKEN`, `$GITLAB_TOKEN`) and POSTs
them to an attacker-controlled URL over the open egress.

**This works today and is unrelated to the container boundary. No escape is required.** Switching
the runtime does not address it — it is a configuration and policy problem (the defense-in-depth
hygiene of §2: scoped ephemeral token forwarding plus a default-deny egress allowlist).

### 3.2 Host filesystem reach via configured mounts

A host `/tmp` bind, a read-only `~/.gitconfig` (reveals identity), a read-only projects mount. None
of these are escapes — they are configured access surfaces the threat model must treat as
adversarially read. Addressed by tightening mount policy, independent of runtime choice.

### 3.3 Container → host privilege escalation

Requires either an OCI-runtime (runc / crun) bug or a kernel LPE:

- **November 2025** brought three back-to-back runc CVEs (CVE-2025-31133, CVE-2025-52565,
  CVE-2025-52881), each delivering full container breakout via mount races and procfs symlink
  tricks, affecting Podman, Kubernetes, and every other runc-based runtime alike.
- **Continuous background:** a steady stream of bpf / io_uring / netfilter / page-cache LPEs in the
  upstream kernel.

This is the class of risk that shared-kernel container runtimes cannot structurally eliminate. For
this class, **only a hardware-virtualization boundary qualitatively changes the picture** — every
kernel LPE and runc CVE keeps applying as long as the kernel is shared.

### 3.4 Lateral abuse of the agent's footprint (no escape required)

Even without a kernel or runtime bug: writing malicious `pre-commit` hooks (attractive because
sandboxes often run `pre-commit install` in a lifecycle hook), modifying shell rc files in a
persisted home directory, dropping a binary in a host-bound `/tmp` that survives a restart, or
poisoning `.git/config` / `.gitignore` to leak files on the next commit. Addressed by tightening
persistence and mount policy.

### 3.5 Implications

- **(3.1)** is the most under-mitigated risk and is **not** addressed by any runtime swap.
- **(3.3)** is the risk that requires a stronger boundary; only hardware virtualization changes it.
- **(3.2)** and **(3.4)** are addressed by tightening mount and persistence policy, independent of
  runtime.

## 4. Boundary classes and residual surface

The viable boundaries fall into three classes, examined per-option in
[10-runtimes-catalog.md](10-runtimes-catalog.md):

- **Shared-kernel** (plain containers, hardened containers, bubblewrap/Landlock/seccomp) — rejected
  as primary; defense-in-depth only.
- **Userspace-kernel** (gVisor) — a different, weaker class than hardware virtualization; a viable
  no-KVM fallback, not a primary workstation boundary.
- **Hardware-virtualization microVM** (Firecracker, Kata+FC, Kata+CH, libkrun, QEMU-microvm, Apple
  `container`) — the only class that satisfies §1.1.

### 4.1 Residual host-kernel surface under a hardware-virt boundary

A hardware-virt boundary **shifts** the host-kernel attack surface; it does not reduce it to zero.
Every KVM-based VMM retains two well-defined host-facing surfaces: (a) `/dev/kvm` ioctls (the
hypercall path), and (b) the VMM's virtio device backends (block, net, vsock, fs, optionally gpu).
This is a different category from the shared-kernel case — a compromise here is a hypervisor- or
virtio-class bug ($250K–$500K bounty class per
[emirb — MicroVM Isolation in 2026](https://emirb.github.io/blog/microvm-2026/)), not a routine
kernel LPE or syscall trick — but it is not the empty set. Recent precedent:
[CVE-2026-5747](https://aws.amazon.com/security/security-bulletins/2026-015-aws/) (Firecracker
virtio-pci OOB write, opt-in flag) shows that "small VMM" is not "no VMM CVEs."

The size and shape of (b) varies between VMMs and is an operational trade-off rather than a
boundary-class difference:

- **Firecracker** ships the smallest device set by design: virtio-net, virtio-blk, serial, no
  virtio-fs, no virtio-gpu. (Kata-on-FC is forced into the devmapper snapshotter for the same
  reason.)
- **Cloud Hypervisor** adds virtio-fs, virtio-mem, PCI hotplug, VFIO, and GPU passthrough
  (Landlock-sandboxed host-side).
- **libkrun** uses virtio-fs as the default rootfs path (how `crun --krun` mounts the OCI bundle),
  and its TSI (Transparent Socket Impersonation) feature terminates per-connection TCP state on the
  **host's** TCP/IP stack via a userspace proxy in the VMM process — different from Firecracker's
  TAP/bridge path, neither strictly smaller. virtio-gpu is available but off by default.

The critique "krun shares the kernel with the host" conflates (b) with shared-kernel namespacing and
is **wrong on the boundary class** — the guest runs its own kernel (`init.krun` as guest PID 1;
`libkrunfw` bundles it), runc-class breakouts do not reach the host, and kernel LPEs inside the
guest stay inside the guest. But the underlying intuition (libkrun's host-side device-backend
surface is non-zero and **wider** than bare Firecracker's) is correct; it is accepted as a
documented trade-off in [20-decision-libkrun-linux.md](20-decision-libkrun-linux.md) and
[30-libkrun-vs-firecracker.md](30-libkrun-vs-firecracker.md). The bare-Firecracker escape hatch
remains documented for cases where minimizing this surface is worth the plumbing cost.

### 4.2 Selection criteria

When choosing a hardware-virt backend, decide on, in priority order:

1. **Security.** Boundary class (hypervisor vs userspace-kernel vs shared-kernel), TCB size, CVE
   history, supply-chain trust. All microVM candidates clear the bar; the rest are tie-breakers.
2. **Operational simplicity for the user.** Cold-start, mount UX, feature parity, error messages.
3. **What the integrating tool must own.** Adapter glue is fine; rootfs builders, kernel-image
   lifecycle, in-guest agents, and containerd shims are real ongoing costs and must be budgeted
   explicitly.
4. **Cross-platform parity.** A single mental model across Linux and macOS beats two unrelated
   backends.

The concrete outcome of applying these criteria to a shippable Linux backend is recorded in
[20-decision-libkrun-linux.md](20-decision-libkrun-linux.md).

## References

See [90-references.md](90-references.md) for the consolidated bibliography covering runc CVEs, the
microVM VMMs, and the microarchitectural-security literature cited above.
