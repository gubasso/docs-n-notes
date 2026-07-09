# Reference implementations of the libkrun sandbox pattern

The "AI agent in a KVM microVM" pattern — rootless Podman fronting `crun --krun` fronting libkrun —
is not theoretical. Several shipping projects already run it in production, and anyone building
their own agent sandbox can study them as prior art rather than starting from a blank page. This
document surveys those implementations, leading with the closest complete reference and then noting
the broader ecosystem that exercises the same stack.

For the runtime rationale behind this stack see
[20-decision-libkrun-linux.md](./20-decision-libkrun-linux.md); for the microVM-vs-jailer trade-off
see [30-libkrun-vs-firecracker.md](./30-libkrun-vs-firecracker.md); for the threat model that
motivates a hardware-virt boundary see
[00-threat-model-and-principles.md](./00-threat-model-and-principles.md).

## The closest complete reference: ai-agents-sandbox

[val4oss/ai-agents-sandbox](https://github.com/val4oss/ai-agents-sandbox) is the most directly
studyable end-to-end implementation of the pattern. It is small enough to read in an afternoon —
roughly 419 lines of POSIX shell driving `podman build` and `podman run`, plus a single
openSUSE-Tumbleweed `Containerfile`. Its stated goal is a secure, isolated environment for running
AI coding agents (GitHub Copilot CLI, Gemini CLI, Claude Code) on rootless Podman with a libkrun
microVM. Because it targets one narrow job, every design decision is legible and portable.

### Runtime stack and boundary

On the primary path it runs `podman --runtime krun` → `crun --krun` → libkrun, giving each agent a
KVM microVM with its own guest kernel. Networking uses TSI (transparent socket impersonation), so
there is no host-side TAP, bridge, NAT, or `slirp4netns` in microVM mode. When `/dev/kvm` or libkrun
is unavailable it drops to a `no-microvm` fallback: plain rootless Podman plus `slirp4netns`
user-mode NAT, a shared-kernel container hardened by namespaces and seccomp. The fallback is an
explicit opt-out (or an automatic degradation), not the default — the microVM is the intended
boundary.

### Preflight probe and version gate

A `_check_microvm` routine performs the preflight the pattern requires: it probes for the `krun`
binary, checks libkrun against a minimum version, verifies `/dev/kvm` is present, confirms `kvm`
group membership, and warns when nested virtualization is missing. Each failure emits a specific,
human-readable error rather than a generic "microVM unavailable".

The version gate is worth copying verbatim as a lesson in _why_ you pin a floor. It requires libkrun
≥ 1.18 specifically because that release contains the vsock fix in commit
[`757b080b`](https://github.com/libkrun/libkrun/commit/757b080b4c5f5934f8e5320a38b401aaec116764);
older libkrun will load but misbehave under load. A minimum-version constant is declared near the
top of the driver and enforced by the probe.

### A concrete known-bug workaround

One agent, Copilot CLI, trips a libkrun defect: HTTP/2 over vsock returns `BufDescTooSmall`. Rather
than failing opaquely, the driver detects this case and routes the `copilot` agent to the
`no-microvm` fallback while keeping the other agents in the microVM. It tracks the upstream issue at
[libkrun/libkrun#674](https://github.com/libkrun/libkrun/issues/674). This is a useful template for
any implementation: encode per-agent quirks as targeted, documented fallbacks tied to an upstream
tracker, not as blanket disabling of the fast path.

### Security posture actually enforced

The `podman run` invocation applies a hardened posture by default. The concrete flag set is worth
reproducing because it is a known-good baseline:

```sh
podman run \
  --cap-drop ALL \
  --security-opt no-new-privileges \
  --userns=keep-id \
  --tmpfs /tmp:rw,nosuid,size=1g \
  --pids-limit 1024 \
  --annotation krun.ram_mib=4096 \
  --annotation krun.cpus=2 \
  ...
```

Podman's default seccomp profile stays in force. The `krun.ram_mib` / `krun.cpus` annotations are
the libkrun-specific way to size the guest; they can also be set per-image via a `.krun_vm.json`
config file baked into the image. Note the credential model: there are no host-config bind-mounts at
all. Authentication happens _inside_ the container and is persisted to a sandbox volume, so host
secrets are never exposed to guest code.

### Per-agent slim builds and image sizes

Instead of one fat image, the project drives a single `AGENT=<copilot|claude|gemini|all>` build-arg
through `case` blocks in one `Containerfile`, installing only the tooling a given agent needs. This
keeps images small and the build inputs auditable. The reported sizes:

| Image      | Size    | Notes                                       |
| ---------- | ------- | ------------------------------------------- |
| copilot    | 588 MB  | Copilot CLI installed at runtime after auth |
| gemini     | 1.76 GB |                                             |
| claude     | 1.92 GB |                                             |
| all-in-one | 2.12 GB | every agent in one image                    |

The lesson for a builder: a single parameterized `Containerfile` plus a build-arg is enough to ship
per-agent variants without maintaining parallel image definitions.

### macOS coverage

The stack is Linux-first, but the driver also handles macOS explicitly: it detects the platform and
runs the agents inside a Podman Machine VM, where Apple's Hypervisor.framework provides the
hardware-virt boundary in place of `/dev/kvm`. This is informational for a Linux-only target but
shows the pattern is portable to a Podman-Machine host.

## What this reference teaches — and what a fuller implementation adds

Because ai-agents-sandbox deliberately does one thing, its capabilities and its omissions are both
instructive. Its shipping capabilities:

- A working KVM/libkrun preflight with a version floor tied to a specific upstream fix.
- A targeted, documented per-agent bug workaround (Copilot HTTP/2 vsock → `no-microvm`).
- A hardened default posture (`--cap-drop ALL`, `no-new-privileges`, `keep-id` userns, `nosuid`
  tmpfs, PID limit, default seccomp) plus microVM resource annotations.
- Per-agent slim builds from one parameterized `Containerfile`.
- In-container auth persisted to a volume, keeping host secrets off the guest.
- A macOS path via Podman Machine + Hypervisor.framework.

The gaps below are not defects for its scope; they are the axes a broader, devcontainer-oriented
tool would need to add on top of this same runtime core:

- **Egress allowlist / network policy.** Outbound traffic is unfiltered in both microVM (TSI) and
  fallback (`slirp4netns`) modes. A fuller implementation layers a runtime-agnostic egress
  allowlist.
- **Host-side scoped/ephemeral token forwarding.** Here auth lives inside the container and persists
  to a volume; a fuller design forwards short-lived, scoped tokens from the host instead, so no
  standing credential lives in guest state.
- **Multi-project workspace identity.** The reference keeps a single persistent home volume shared
  across all projects, with cloning done inside the container. A multi-project tool gives each
  project (and each work-clone) its own workspace and container identity.
- **Layered / composable config.** Image selection is a build-arg switch, not a composition system;
  a fuller tool composes reusable layers into a manifest.
- **No-KVM CI parity.** There is no equivalent to running the same image under a software-isolation
  runtime for KVM-less CI. A fuller implementation designates gVisor (`runsc`) for that slot; see
  [10-runtimes-catalog.md](./10-runtimes-catalog.md).

Critically, none of these gaps live in the runtime/security layer — that layer is fully shared with
any richer tool. They are all product-surface concerns layered _above_ an identical
libkrun-on-Podman core. A builder can adopt this reference's runtime code wholesale and add the
composition surface separately.

## Further production users of the same stack

The same libkrun-under-Podman/`crun --krun` stack underpins several other shipping projects, which
serve as additional evidence that the boundary is production-viable rather than experimental.
libkrun is developed within the container-tools ecosystem alongside Podman and crun (the crun
`--krun` handler ships in [`containers/crun`](https://github.com/containers/crun)).

- **RamaLama (Red Hat).** Runs LLM inference workloads inside libkrun microVMs, using the same
  `crun --krun` path. Red Hat's own write-up details the isolation rationale and the microVM
  integration; see
  [Supercharging AI isolation: microVMs with RamaLama and libkrun](https://developers.redhat.com/articles/2025/07/02/supercharging-ai-isolation-microvms-ramalama-libkrun).
  This is the strongest "vendor-blessed, in-production" data point for the stack.

- **Microsandbox.** A general-purpose sandbox that uses libkrun microVMs to isolate untrusted code
  execution — a broader take on the same primitive, useful for seeing the pattern applied outside
  the coding-agent niche.

- **krunvm.** The [`libkrun/krunvm`](https://github.com/libkrun/krunvm) CLI creates and runs
  microVMs from OCI images directly on top of libkrun, without Podman in front. It is the closest
  thing to a "reference driver" for libkrun and is worth reading to understand what Podman's
  `--runtime
  krun` is delegating to underneath.

Together these show the stack is not a single project's bet: an inference server, a general code
sandbox, a bare microVM launcher, and an agent runner all sit on the same libkrun core. For
operational specifics of running libkrun under Podman see
[60-podman-libkrun-operational-notes.md](./60-podman-libkrun-operational-notes.md); for why native
orchestration was chosen over a heavier stack see
[50-native-orchestration-decision.md](./50-native-orchestration-decision.md).

## References

- [val4oss/ai-agents-sandbox](https://github.com/val4oss/ai-agents-sandbox) — the closest complete
  reference implementation: ~419 LOC POSIX shell + one openSUSE-Tumbleweed `Containerfile`.
- [libkrun/libkrun](https://github.com/libkrun/libkrun) — the microVM library at the base of the
  stack.
- [libkrun/libkrun#674 — Copilot HTTP/2 vsock `BufDescTooSmall`](https://github.com/libkrun/libkrun/issues/674)
  — the upstream bug the Copilot workaround tracks.
- [libkrun/libkrun commit `757b080b` — vsock fix](https://github.com/libkrun/libkrun/commit/757b080b4c5f5934f8e5320a38b401aaec116764)
  — the fix that motivates the libkrun ≥ 1.18 version floor.
- [libkrun/krunvm](https://github.com/libkrun/krunvm) — bare microVM launcher over libkrun.
- [`containers/` org](https://github.com/containers) — crun and the broader container-tools OCI
  ecosystem.
- [crun `krun.1` manpage (openSUSE Tumbleweed)](https://manpages.opensuse.org/Tumbleweed/crun/krun.1.en.html)
  — the `crun --krun` runtime handler.
- [Red Hat Developer — Supercharging AI isolation: microVMs with RamaLama and libkrun (Jul 2025)](https://developers.redhat.com/articles/2025/07/02/supercharging-ai-isolation-microvms-ramalama-libkrun)
  — production use of the stack for inference workloads.
- [podman-network man page (rootless networking, `pasta` / `slirp4netns`)](https://docs.podman.io/en/stable/markdown/podman-network.1.html)
  — the fallback networking the `no-microvm` path relies on.
- [gvisor.dev — docs](https://gvisor.dev/docs/) — the software-isolation runtime used for no-KVM CI
  parity.
- [Sysdig — runc container escape vulnerabilities (Nov 2025)](https://www.sysdig.com/blog/runc-container-escape-vulnerabilities)
  — CVE-2025-31133, CVE-2025-52565, CVE-2025-52881; why shared-kernel containers are not the
  boundary.
- [CNCF — runc container breakout vulnerabilities: a technical overview (Nov 2025)](https://www.cncf.io/blog/2025/11/28/runc-container-breakout-vulnerabilities-a-technical-overview/)
- [emirb — microvm-2026](https://emirb.github.io/blog/microvm-2026/) — hypervisor-escape bug-class
  economics.

See also [90-references.md](./90-references.md) for the shelf-wide source list.
