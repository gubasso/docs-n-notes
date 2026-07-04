# Decision: libkrun (crun --krun) as the primary Linux backend

> Status: Decided. Scope: selection and implementation contract for the primary sandbox/isolation
> runtime backend on Linux. The broader multi-slot catalog view (macOS, escape hatches, contingency
> adapters) lives in [10-runtimes-catalog.md](10-runtimes-catalog.md); this document narrows that
> catalog to the single shippable Linux backend and states why.

The primary default backend on Linux is **libkrun via `crun --krun`, fronted by rootless Podman.**
The no-KVM fallback, used only on CI runners without hardware virtualization, is **gVisor
(`runsc`).**

This ships **one** working Linux backend plus **one** CI-only fallback. Every other candidate — bare
Firecracker, Kata-Firecracker, Kata-Cloud-Hypervisor, Apple `container` on macOS, libkrun-on-HVF —
remains a catalog item that can be added later behind the same adapter interface without changing
the user-facing surface. See [10-runtimes-catalog.md](10-runtimes-catalog.md).

| Slot                              | Pick                        | One-line rationale                                                                                                                                 |
| --------------------------------- | --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Primary (Linux, KVM available)    | **libkrun + `crun --krun`** | KVM-class boundary, OCI-native, smallest adapter footprint among hardware-virt candidates; production-proven via RamaLama / Microsandbox / krunvm. |
| Fallback (CI runners without KVM) | **gVisor**                  | Userspace-kernel sandbox; the only viable answer for CI runners and cloud VMs without nested virtualization.                                       |

## Decision criteria

A hardware-virtualization boundary (KVM-class, no shared host kernel) is a **precondition**, not a
criterion — only options that already clear it are ranked here. See
[00-threat-model-and-principles.md](00-threat-model-and-principles.md). Given that, the criteria, in
priority order:

1. **Security is the primary goal.** The sandbox exists to run LLM agents that may execute
   attacker-controlled or model-generated instructions. A **KVM-class hardware-virtualization
   boundary** — separate guest kernel, no shared-kernel namespace boundary — is the hard
   requirement. The November 2025 runc CVE cluster
   ([Sysdig](https://www.sysdig.com/blog/runc-container-escape-vulnerabilities),
   [CNCF](https://www.cncf.io/blog/2025/11/28/runc-container-breakout-vulnerabilities-a-technical-overview/))
   is the reference precedent: shared-kernel containers are not a sufficient boundary for this
   threat model.
2. **Production-proven and well-maintained.** Active upstream, real production users, stable
   cadence, healthy CVE-response track record.
3. **Enables clean UX with minimal owned plumbing.** Simple commands and declarative, composable,
   shareable manifests. The amount of plumbing the integrating tool itself has to own is the
   dominant UX cost.
4. **Single working Linux implementation.** Ship **one** solution that works fully on Linux.
   Multi-platform parity, escape hatches, and alternative backends are deferred.
5. **Migration is cheap.** A future rewrite (e.g. moving the adapter from a shell script to a Rust
   binary) is acceptable; do not over-weight switching cost when picking now.

Two things are explicitly **not** criteria:

- **Editor / IDE integration.** Compatibility with VS Code Remote-Containers, GitHub Codespaces, or
  the `devcontainer up` CLI is a _side-effect_ of preserving the OCI/devcontainer authoring schema,
  never a requirement. The product goal is sandboxing LLM agents; do not couple the runtime to a
  heavyweight upstream orchestrator. If `devcontainer.json` compatibility keeps working as a
  downstream consequence, that is welcome but does not drive the runtime choice. See
  [50-native-orchestration-decision.md](50-native-orchestration-decision.md).
- **A multi-backend catalog at runtime.** This implementation ships one backend value plus the
  documented CI fallback; alternatives remain catalog-only.

## Why libkrun wins on each criterion

### What it is

[`libkrun/libkrun`](https://github.com/libkrun/libkrun) is a Rust user-space VMM whose code is
partly derived from Firecracker, Cloud Hypervisor, and the [`rust-vmm`](https://github.com/rust-vmm)
crates. [`crun`](https://github.com/containers/crun) is a fast OCI runtime; passing `--krun` makes
`crun` boot the OCI bundle inside a libkrun microVM instead of a namespaces-only container. Podman
drives the whole thing as a normal OCI runtime:

```bash
podman --runtime krun run <image>
```

The guest boots **its own kernel** — libkrun bundles the guest kernel and an init (`init.krun`)
through the `libkrunfw` firmware package — so the host kernel is not part of the in-guest attack
surface.

Networking uses **TSI (Transparent Socket Impersonation)**: in-guest sockets are transparently
forwarded to host sockets through libkrun, with **no TAP device, bridge, NAT, or `slirp4netns`
plumbing on the host side.**

### Criterion 1 — security

- **KVM-class boundary.** The guest runs its own kernel; shared-kernel escape classes (runc,
  namespaces, seccomp bypasses) do not apply at this boundary.
- **No published hypervisor-escape CVEs in libkrun, 2024–2026.** The two libkrun CVEs that surfaced
  in 2025 were transitive Rust dependency rolls (`rust-openssl`, `crossbeam-channel`), patched
  through the normal Fedora pipeline; neither was a VMM escape. References:
  [FEDORA-2025-f8be7978e3](https://linuxsecurity.com/advisories/fedora/fedora-41-libkrun-2025-f8be7978e3-security-advisory-updates-rh8lbifoalx6),
  [FEDORA-2025-c53905e83d](https://linuxsecurity.com/advisories/fedora/fedora-41-libkrun-2025-c53905e83d-ohmxvt9uvrww).
- **Boundary class vs. trust-path size.** libkrun + crun + Podman is more code on the host-side
  trust path than a minimal bare-VMM stack, but the boundary class is identical (KVM). Boundary
  class is the security-relevant variable; trust-path size is a secondary consideration weighed
  against engineering cost. The detailed device-surface analysis is in the next section and in
  [30-libkrun-vs-firecracker.md](30-libkrun-vs-firecracker.md).

### Criterion 2 — production-proven and well-maintained

- Part of the container-tools ecosystem alongside Podman, crun, Buildah, and Skopeo — one of the
  deepest investments in OCI-native rootless workflows anywhere. The crun `--krun` handler ships in
  [`containers/crun`](https://github.com/containers/crun); libkrun and its firmware/CLI siblings are
  developed in the [`libkrun`](https://github.com/libkrun) org.
- **v1.18.0** shipped **2026-04-24**; active commit cadence; cross-platform (Linux KVM and macOS HVF
  backends).
- Concrete production users (see
  [40-reference-implementations.md](40-reference-implementations.md)):
  - **RamaLama** — Red Hat's primary AI-isolation story for local model execution. See
    [Red Hat Developer — "Supercharging AI isolation: microVMs with RamaLama and libkrun" (Jul 2025)](https://developers.redhat.com/articles/2025/07/02/supercharging-ai-isolation-microvms-ramalama-libkrun).
  - **Microsandbox** — an open-source sandboxing platform built on libkrun.
  - **krunvm** — the [`libkrun/krunvm`](https://github.com/libkrun/krunvm) CLI for libkrun microVMs.

### Criterion 3 — clean UX, minimal owned plumbing

- `podman --runtime krun run <image>` consumes existing OCI image artifacts directly. **No rootfs
  builder, no kernel-image lifecycle, no in-guest agent, no containerd shim, no devmapper
  snapshotter.**
- The per-runtime adapter collapses to roughly **80–150 lines of Bash** that add `--runtime krun` to
  existing Podman calls.
- TSI eliminates the entire host-side networking plumbing class (TAP/bridge/NAT/`slirp4netns`).
- The authoring surface (`devcontainer.json`, manifest layers, the `runtime:` field) does not
  change. The composition schema keeps working.

### Criterion 4 — single working Linux implementation

- KVM is available on essentially every modern Linux developer workstation; for the rare KVM-less CI
  runner, gVisor covers the gap.
- One adapter, one manifest field value, one OCI build pipeline. No cross-platform shim, no
  escape-hatch maintenance, no parallel backend to keep at feature parity.

### Criterion 5 — migration is cheap

- The adapter is small enough to rewrite as a Rust binary later without discarding domain knowledge:
  the OCI image artifacts, the manifest schema, the layer composition, the baseline egress/mount
  policies, and the runtime-agnostic modules all stay.
- Swapping libkrun for a different backend is a single new adapter module behind the same interface
  — the adapter's `run` / `exec` / `ps` / `rm` / `build` operations are the contract everything else
  hangs on.

## What the adapter owns vs. what is upstream

The integrating tool owns a thin per-runtime adapter and a small set of runtime-agnostic policies;
everything VMM-shaped is upstream.

| Owned by the integrating tool                                                                                                   | Owned upstream                                                |
| ------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- |
| The `crun --krun` adapter (~80–150 LOC Bash) that adds `--runtime krun` to Podman calls.                                        | Rootfs construction (handled inside `crun --krun`).           |
| The accepted `krun` runtime value in the composition schema.                                                                    | Kernel image (libkrun bundles or fetches it via `libkrunfw`). |
| A KVM-detection probe with a clear error message when KVM is missing.                                                           | In-guest init / agent (`init.krun`).                          |
| Baseline policies (egress allowlist, scoped/ephemeral mounts, `no-new-privileges`, `cap-drop=ALL`). These are runtime-agnostic. | KVM interface, virtio devices.                                |
| Rootless-Podman defaults (pasta networking, `userns=auto:size=65536`).                                                          | TSI networking (no TAP/bridge plumbing).                      |
| Choice of which `devcontainer.json` keys are honored vs. produce a clear error under `krun`.                                    | OCI runtime spec compliance via `crun`.                       |

Illustrative plumbing cost, drawn from the catalog:

| Option                             | Owned plumbing surface                                                                                                                     |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| libkrun via `crun --krun` (chosen) | A flag and an adapter (~80–150 LOC Bash).                                                                                                  |
| Bare Firecracker                   | Rootfs builder + TAP/NAT + in-guest init + vsock channel + kernel updates → ~3–5 calendar weeks one-time and a permanent maintenance tail. |
| Kata + Firecracker                 | containerd shim + runtime-class registration + **devmapper snapshotter** (no virtio-fs on FC) → real laptop friction.                      |
| Kata + Cloud Hypervisor            | containerd shim + runtime-class registration; cleaner than Kata-FC; still containerd.                                                      |

## Device-surface and security analysis

Every KVM VMM keeps `/dev/kvm` ioctls plus a set of virtio device backends as its host-facing
surface. libkrun's guest runs its own kernel via `init.krun` / `libkrunfw`, so a guest-kernel local
privilege escalation stays a guest-kernel compromise, not a host compromise. The security-relevant
question is the residual host-kernel surface _outside_ the guest.

libkrun's host-facing device surface is **wider than bare Firecracker's** in three concrete ways:

1. **virtio-fs is the default rootfs path.** It is how `crun --krun` mounts the OCI bundle into the
   guest. Firecracker has no virtio-fs at all and forces a devmapper-snapshotter detour in
   Kata-on-FC for the same job.
2. **TSI's host-side proxy** opens real host `AF_INET` / `AF_INET6` / `AF_UNIX` sockets on behalf of
   the guest, terminating per-connection TCP state on the **host** kernel. Firecracker uses TAP +
   netfilter instead. See the
   [libkrunfw TSI patch](https://github.com/libkrun/libkrunfw/tree/main/patches).
3. **virtio-gpu (virgl/venus)** is available via `krun_set_gpu_options`. It is **off by default** in
   this implementation and gated behind an explicit profile opt-in to keep the surface bounded.

This delta is the technical content behind the maintainer's framing in
[libkrun #538](https://github.com/libkrun/libkrun/discussions/538) — "guest and VMM pertain to the
same security context." It is a **different** host-side surface from a TAP+netfilter microVM, not a
strictly smaller one. None of these surfaces converts the boundary back to shared-kernel, but they
are exactly the right thing to evaluate when comparing libkrun against a minimal bare-VMM stack. The
full side-by-side is in [30-libkrun-vs-firecracker.md](30-libkrun-vs-firecracker.md).

The first two surfaces are unavoidable under this design; the third is off by default. All three are
accepted as the cost of the smaller adapter footprint.

## Why not Kata-FC or Kata-CH

Kata Containers (Firecracker or Cloud Hypervisor variant) is the technically closest alternative on
the boundary axis — same KVM class. Kata-CH in particular avoids the devmapper trap that hurts
Kata-FC and is the path the Kata community actively exercises in production
([Northflank](https://northflank.com/blog/kata-containers-vs-firecracker-vs-gvisor),
[AWS — Kata workload isolation](https://aws.amazon.com/blogs/containers/enhancing-kubernetes-workload-isolation-and-security-using-kata-containers/)).
It is nonetheless not built here:

- **Containerd dependency.** Both Kata-FC and Kata-CH assume a containerd + runtime-class
  registration on the host. That is the largest piece of cluster-shaped infrastructure in the
  candidate set and directly violates criterion 3 — the integrating tool would have to own a
  containerd lifecycle on developer workstations and CI runners. Their UX wins lean on `nerdctl` and
  Kubernetes, not a laptop workflow.
- **No security delta over libkrun.** Both deliver a KVM-class boundary; choosing Kata trades
  adapter simplicity for cluster-shaped tooling without isolating against any additional attack
  class relevant to the stated threat model.
- **Kata-FC adds devmapper-snapshotter friction** (no virtio-fs on Firecracker).
- **Status.** Kata-CH remains a **deferred contingency adapter** in the catalog — implement it only
  if libkrun's governance or maintenance posture deteriorates (see Risks Accepted). Kata-FC is
  dropped outright.

## Why not bare Firecracker

Bare Firecracker has the **smallest TCB** of any candidate — ~50–83K LoC of Rust, zero published
hypervisor-escape CVEs in 2024–2026, and an
[arXiv microarchitectural-security analysis](https://arxiv.org/pdf/2311.15999) to back the claim.
Its recent CVEs are scoped, not hypervisor escapes:

- **CVE-2026-5747** is in virtio-pci and only affects the opt-in `--enable-pci` flag (default MMIO
  is unaffected), per
  [AWS bulletin 2026-015](https://aws.amazon.com/security/security-bulletins/2026-015-aws/).
- **CVE-2026-1386** is a host-side jailer symlink LPE, per
  [AWS bulletin 2026-003](https://aws.amazon.com/security/security-bulletins/rss/2026-003-aws/).

It is not the primary because:

- **Boundary class is identical to libkrun (KVM).** A smaller VMM TCB tightens the host-side trust
  path but does not raise the isolation class.
- **Implementation cost violates criteria 3 and 4.** The integrating tool would own the rootfs
  builder, kernel-image lifecycle, in-guest init, vsock exec channel, TAP/NAT plumbing, and a
  controller binary (~3–5 calendar weeks one-time plus a permanent maintenance tail) — exactly the
  work libkrun lets us avoid while landing on the same boundary class.

Bare Firecracker stays in the catalog as a documented **escape hatch** for users who explicitly want
the smallest host-side TCB, built on the same adapter interface but never the default.

## Why not gVisor as primary

gVisor is a _different_ boundary class — a userspace kernel rather than hardware virtualization —
used in production by Modal and Cloud Run. It is excellent for its niche, but criterion 1 requires a
hardware-virtualization boundary as the primary, and gVisor's `runsc` bugs land host-side. It is
therefore used only where KVM is unavailable, and only on CI runners.

## Cross-platform aside

This implementation is Linux-only, but the catalog tracks the wider picture:

- **macOS: Apple `container`.** [`apple/container`](https://github.com/apple/container) runs one
  lightweight Linux VM per OCI container via
  [Virtualization.framework](https://developer.apple.com/documentation/virtualization) (macOS 26+).
  HVF/Virtualization.framework is the macOS equivalent of a KVM-class boundary, and the same OCI
  image artifacts work. libkrun's own macOS HVF backend exists but, as of 2026, has documented
  bind-mount permission gaps relative to Apple's `applehv` driver
  ([podman #27679](https://github.com/containers/podman/discussions/27679),
  [Sergio López on macOS GPU + virtio-fs](https://sinrega.org/2024-03-06-enabling-containers-gpu-macos/)),
  so Apple `container` is the cleaner Mac story until those close.
- **No-KVM: gVisor.** The fallback described above, for CI runners and cloud VMs without nested
  virtualization.

## Egress enforcement

TSI removes host-side TAP and bridge plumbing, but it does not apply an outbound policy on its own.
Two options were considered:

- **Option A (chosen): an in-guest nftables allowlist.** A per-VM egress policy is installed inside
  the guest with nftables, driven by an in-guest bootstrap script. Because the egress proxy lives in
  the VMM process and terminates connections on the host stack, per-VM allowlisting inside the guest
  is the right control point for this design.
- **Option B (rejected): a userspace proxy.** A dedicated proxy binary would add HTTP/TLS
  interception semantics and a larger support surface without changing the underlying isolation
  class. Revisit it only if DNS rotation or wildcard-host ergonomics prove untenable in practice.

Operational detail — pasta networking defaults, the unpinned rootless network backend on the `krun`
path, and the egress bootstrap — is in
[60-podman-libkrun-operational-notes.md](60-podman-libkrun-operational-notes.md).

## CI vs. adversarial threat distinction

gVisor is a **CI-only fallback**, not a second supported backend for developer workstations. The
distinction is deliberate: the CI threat model explicitly accepts a weaker boundary class **because
the workload there is the project's own test code, not adversarial LLM-generated code.** The
dev-workstation threat model — running LLM agents that may execute attacker-controlled instructions
— requires the hardware-virtualization boundary that libkrun provides. The documented default is
therefore **gVisor on KVM-less CI environments, libkrun everywhere else.**

## Resolved questions

| Question                                             | Resolution                                                                                                                                                                                                        |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Final backend choice                                 | **libkrun via `crun --krun`** on Linux.                                                                                                                                                                           |
| CI parity default                                    | **gVisor** on no-KVM CI runners; **libkrun** where KVM is available.                                                                                                                                              |
| Image distribution: a libkrun-specific build target? | **No new build target.** libkrun consumes the existing OCI image artifacts unchanged via `crun --krun`.                                                                                                           |
| Multi-backend selection at the manifest level        | Schema-ready but **not exposed** in this implementation. Only the `krun` runtime value is accepted; the gVisor CI fallback is documented in prose and will be added to the schema enum together with its adapter. |

These remain open and apply runtime-agnostically:

- **Token forwarding** — independent of runtime.
- **Egress allowlist UX** — independent of runtime.
- **Cross-runtime feature parity** — the adapter must define which `devcontainer.json` keys are
  portable; the rest must error explicitly rather than silently degrade.

## Risks accepted

Each risk is logged so it can be re-evaluated if conditions change.

1. **Trust path is longer than a minimal bare-VMM stack, and libkrun's host-facing device set is
   wider than Firecracker's.** Two separable facets:
   - _Host-side TCB outside the VMM._ libkrun + crun + Podman is more code on the host-side trust
     path than `jailer` + `firecracker`. Same boundary class (KVM); larger TCB outside the VMM.
   - _Host-facing device-backend surface._ The three surfaces above — virtio-fs default rootfs,
     TSI's host-side proxy, and (off-by-default) virtio-gpu. The first two are unavoidable under
     this design; the third is gated behind an explicit profile opt-in.

   Both facets are accepted in exchange for ~3–5 calendar weeks of plumbing the integrating tool
   does not have to own. The bare-FC escape hatch remains documented for future opt-in where
   minimizing this surface is worth the cost.
2. **KVM is a hard requirement on developer workstations.** Hosts without KVM are not supported as
   workstation targets. CI runners without KVM fall back to gVisor, with the understood weaker
   boundary class.
3. **Single-vendor / single-ecosystem concentration.** Podman, crun, libkrun, Buildah, and Skopeo
   share maintainer lineage and a common origin in the container-tools ecosystem (historically the
   `containers/` GitHub org, since split across several orgs). Healthy in 2026; if funding or
   governance shifts, several dependencies move at once. Mitigation: the Kata-CH adapter remains
   specified in the catalog as a backup with different governance (CNCF incubating).
4. **Shared `rust-vmm` lineage.** libkrun is derived from Firecracker, Cloud Hypervisor, and the
   `rust-vmm` crates. A class bug in shared `rust-vmm` crates would land on libkrun, Firecracker,
   **and** Cloud Hypervisor simultaneously — a runtime swap is not a mitigation. The mitigation is
   an active CVE-watch and a quick path to apply upstream patches. Recent precedent: the Firecracker
   virtio-pci OOB write in **CVE-2026-5747**
   ([AWS bulletin 2026-015](https://aws.amazon.com/security/security-bulletins/2026-015-aws/)) is a
   reminder that "small VMM" is not "no VMM CVEs."
5. **Token-exfiltration and credential-leakage risks are runtime-independent.** Runtime selection
   does not solve credential leakage from bind-mounted host config (`~/.config/gh`,
   `~/.config/glab-cli`, `~/.claude*`). Those risks are addressed by the baseline policies —
   scoped/ephemeral token forwarding, no host-`/tmp` bind, `no-new-privileges`, `cap-drop=ALL` — and
   apply equally to any runtime.

## References

Full annotated bibliography: [90-references.md](90-references.md).

### libkrun / `crun --krun` / Podman

- [libkrun/libkrun](https://github.com/libkrun/libkrun) — upstream repository.
- [rust-vmm](https://github.com/rust-vmm) — shared VMM crates libkrun derives from.
- [containers/crun](https://github.com/containers/crun) — the OCI runtime.
- [containers/ org](https://github.com/containers) — Podman, crun, libkrun, Buildah, Skopeo.
- [crun `krun.1` manpage](https://manpages.opensuse.org/Tumbleweed/crun/krun.1.en.html) —
  `crun --krun` invocation contract.
- [libkrun/krunvm](https://github.com/libkrun/krunvm) — reference CLI built on libkrun.
- [libkrunfw TSI patch](https://github.com/libkrun/libkrunfw/tree/main/patches) — Transparent Socket
  Impersonation implementation.
- [libkrun discussion #538 — security model](https://github.com/libkrun/libkrun/discussions/538) —
  "guest and VMM pertain to the same security context."
- [Red Hat Developer — "Supercharging AI isolation: microVMs with RamaLama and libkrun" (Jul 2025)](https://developers.redhat.com/articles/2025/07/02/supercharging-ai-isolation-microvms-ramalama-libkrun)
  — production-use evidence.
- [Sergio López — "Enabling containers GPU on macOS" (Mar 2024)](https://sinrega.org/2024-03-06-enabling-containers-gpu-macos/)
  — libkrun macOS background.
- [containers/podman discussion #27679 — libkrun vs `applehv` bind mounts](https://github.com/containers/podman/discussions/27679)
  — the macOS parity gap.

### libkrun CVE evidence

- [Fedora FEDORA-2025-f8be7978e3 — libkrun (rust-openssl dependency roll)](https://linuxsecurity.com/advisories/fedora/fedora-41-libkrun-2025-f8be7978e3-security-advisory-updates-rh8lbifoalx6).
- [Fedora FEDORA-2025-c53905e83d — libkrun (crossbeam-channel dependency roll)](https://linuxsecurity.com/advisories/fedora/fedora-41-libkrun-2025-c53905e83d-ohmxvt9uvrww).

### Kata + Cloud Hypervisor (deferred contingency references)

- [Kata Containers homepage](https://katacontainers.io/).
- [Kata Containers — "Kata + Cloud Hypervisor" blog](https://katacontainers.io/blog/kata-containers-with-cloud-hypervisor/).
- [Northflank — "Kata vs Firecracker vs gVisor"](https://northflank.com/blog/kata-containers-vs-firecracker-vs-gvisor).
- [Northflank — "Cloud Hypervisor 2026 guide"](https://northflank.com/blog/guide-to-cloud-hypervisor).
- [AWS — "Enhancing Kubernetes workload isolation with Kata"](https://aws.amazon.com/blogs/containers/enhancing-kubernetes-workload-isolation-and-security-using-kata-containers/).
- [Cloud Hypervisor — Landlock docs](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/landlock.md).
- [Cloud Hypervisor release notes](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/release-notes.md).

### Firecracker (escape-hatch references; CVE precedent)

- [Firecracker design.md](https://github.com/firecracker-microvm/firecracker/blob/main/docs/design.md).
- [AWS — "Firecracker open source secure fast microVM serverless"](https://aws.amazon.com/blogs/opensource/firecracker-open-source-secure-fast-microvm-serverless/).
- [Microarchitectural Security of AWS Firecracker VMM (arXiv 2311.15999)](https://arxiv.org/pdf/2311.15999).
- [AWS bulletin 2026-015 — CVE-2026-5747 (virtio-pci OOB write; opt-in `--enable-pci`)](https://aws.amazon.com/security/security-bulletins/2026-015-aws/).
- [AWS bulletin 2026-003 — CVE-2026-1386 (jailer symlink LPE; host-side)](https://aws.amazon.com/security/security-bulletins/rss/2026-003-aws/).
- [edera.dev — "Minimal is no longer enough: why AI-scale vulnerability discovery changes container security"](https://edera.dev/stories/minimal-is-no-longer-enough-why-ai-scale-vulnerability-discovery-changes-container-security).

### Apple `container` (macOS cross-platform aside)

- [apple/container](https://github.com/apple/container) — upstream repository.
- [Virtualization.framework](https://developer.apple.com/documentation/virtualization) — Apple's
  macOS VM API.
- [Addo Zhang — "Apple container 0.8.0: seven-month evolution from birth to maturity" (Feb 2026)](https://addozhang.medium.com/apple-container-0-8-0-seven-month-evolution-from-birth-to-maturity-1021e570bbb7).
- [InfoQ — "Apple Containerization brings Linux containers to macOS" (Jun 2025)](https://www.infoq.com/news/2025/06/apple-container-linux/).
- [The Register — "Apple Containerization" (Jun 2025)](https://www.theregister.com/2025/06/10/apple_tries_to_contain_itself/).

### gVisor (no-KVM fallback)

- [gvisor.dev — docs](https://gvisor.dev/docs/).
- [gvisor.dev — performance guide](https://gvisor.dev/docs/architecture_guide/performance/).

### Shared-kernel CVE precedent (why bare containers are not the boundary)

- [Sysdig — "runc container escape vulnerabilities" (Nov 2025)](https://www.sysdig.com/blog/runc-container-escape-vulnerabilities)
  — CVE-2025-31133, CVE-2025-52565, CVE-2025-52881.
- [CNCF — "runc container breakout vulnerabilities: a technical overview" (Nov 2025)](https://www.cncf.io/blog/2025/11/28/runc-container-breakout-vulnerabilities-a-technical-overview/).
- [emirb — "microvm-2026"](https://emirb.github.io/blog/microvm-2026/) — hypervisor-escape bug-class
  economics.
