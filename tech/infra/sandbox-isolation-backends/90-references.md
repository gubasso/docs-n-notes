# References

Consolidated bibliography for this shelf. Each topic doc also carries its own inline citations; this
file is the deduplicated superset, grouped by subject.

## Runtimes and VMMs

- [Firecracker — homepage](https://firecracker-microvm.github.io/)
- [Firecracker — design.md](https://github.com/firecracker-microvm/firecracker/blob/main/docs/design.md)
- [Firecracker — repository](https://github.com/firecracker-microvm/firecracker)
- [Firecracker — production host setup](https://github.com/firecracker-microvm/firecracker/blob/main/docs/prod-host-setup.md)
- [Firecracker — network setup](https://github.com/firecracker-microvm/firecracker/blob/main/docs/network-setup.md)
- [Firecracker — getting started](https://github.com/firecracker-microvm/firecracker/blob/main/docs/getting-started.md)
- [Firecracker — FAQ](https://github.com/firecracker-microvm/firecracker/blob/main/FAQ.md)
- [Firecracker — issue #1180 (virtio-fs rejected)](https://github.com/firecracker-microvm/firecracker/issues/1180)
- [Firecracker — PR #1351 (virtio-fs WIP, rejected)](https://github.com/firecracker-microvm/firecracker/pull/1351)
- [AWS — Announcing Firecracker (open source)](https://aws.amazon.com/blogs/opensource/firecracker-open-source-secure-fast-microvm-serverless/)
- [Microarchitectural Security of AWS Firecracker VMM (arXiv:2311.15999)](https://arxiv.org/pdf/2311.15999)
- [Tal Hoffman — Firecracker internals](https://www.talhoffman.com/2021/07/18/firecracker-internals/)
- [Kata Containers — homepage](https://katacontainers.io/)
- [Kata Containers — releases](https://github.com/kata-containers/kata-containers/releases)
- [Kata Containers — PTG updates, October 2025](https://katacontainers.io/blog/kata-community-ptg-updates-october-2025/)
- [Kata + Firecracker how-to](https://github.com/kata-containers/kata-containers/blob/main/docs/how-to/how-to-use-kata-containers-with-firecracker.md)
- [Kata + Cloud Hypervisor](https://katacontainers.io/blog/kata-containers-with-cloud-hypervisor/)
- [Kata — issue #12558](https://github.com/kata-containers/kata-containers/issues/12558)
- [Kata — issue #8843](https://github.com/kata-containers/kata-containers/issues/8843)
- [Kata — issue #13008](https://github.com/kata-containers/kata-containers/issues/13008)
- [Cloud Hypervisor — repository](https://github.com/cloud-hypervisor/cloud-hypervisor)
- [Cloud Hypervisor — Landlock docs](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/landlock.md)
- [Cloud Hypervisor — release notes](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/release-notes.md)
- [libkrun/libkrun](https://github.com/libkrun/libkrun)
- [libkrun #538 — security-model discussion](https://github.com/libkrun/libkrun/discussions/538)
- [libkrunfw — Transparent Socket Impersonation patch](https://github.com/libkrun/libkrunfw/tree/main/patches)
- [containers/crun](https://github.com/containers/crun)
- [crun — `krun.1` manpage (openSUSE)](https://manpages.opensuse.org/Tumbleweed/crun/krun.1.en.html)
- [rust-vmm — shared VMM crates](https://github.com/rust-vmm)
- [The `containers/` organization](https://github.com/containers)
- [Apple — `container` repository](https://github.com/apple/container)
- [Apple — Virtualization.framework docs](https://developer.apple.com/documentation/virtualization)
- [InfoQ — Apple Containerization for macOS](https://www.infoq.com/news/2025/06/apple-container-linux/)
- [The Register — Apple Containerization](https://www.theregister.com/2025/06/10/apple_tries_to_contain_itself/)
- [Addo Zhang — Apple `container` 0.8.0](https://addozhang.medium.com/apple-container-0-8-0-seven-month-evolution-from-birth-to-maturity-1021e570bbb7)
- [Sergio López — enabling GPU containers on macOS](https://sinrega.org/2024-03-06-enabling-containers-gpu-macos/)

## Reference implementations and tooling

- [val4oss/ai-agents-sandbox](https://github.com/val4oss/ai-agents-sandbox)
- [libkrun #674 — Copilot HTTP/2 vsock `BufDescTooSmall`](https://github.com/libkrun/libkrun/issues/674)
- [libkrun — commit 757b080b (version-gate reference)](https://github.com/libkrun/libkrun/commit/757b080b4c5f5934f8e5320a38b401aaec116764)
- [libkrun/krunvm](https://github.com/libkrun/krunvm)
- [Red Hat Developer — RamaLama + libkrun (Jul 2025)](https://developers.redhat.com/articles/2025/07/02/supercharging-ai-isolation-microvms-ramalama-libkrun)
- [OSInside/flake-pilot](https://github.com/OSInside/flake-pilot)
- [flake-pilot — networking section](https://github.com/OSInside/flake-pilot#networking-)
- [SUSE Package Hub — flake-pilot](https://packagehub.suse.com/packages/flake-pilot/)
- [KIWI — documentation](https://osinside.github.io/kiwi/)
- [KIWI — building KIS images](https://osinside.github.io/kiwi/building_images/build_kis.html)
- [firecracker-containerd — snapshotter docs](https://github.com/firecracker-microvm/firecracker-containerd/blob/main/docs/snapshotter.md)
- [flintlock — repository](https://github.com/liquidmetal-dev/flintlock)
- [Ignite — repository (archived)](https://github.com/weaveworks/ignite)
- [firecracker-go-sdk](https://github.com/firecracker-microvm/firecracker-go-sdk)
- [firepilot — Rust FC SDK](https://github.com/rik-org/firepilot)
- [firectl](https://github.com/firecracker-microvm/firectl)
- [buildfs (crates.io)](https://crates.io/crates/buildfs)
- [iximiuz Labs — Firecracker hands-on](https://labs.iximiuz.com/courses/firecracker-hands-on/run-first-microvm)
- [Single-app rootfs for Firecracker (cloudkernels.net)](https://blog.cloudkernels.net/posts/fc-rootfs/)
- [Hyperlight — Microsoft introduction (Nov 2024)](https://opensource.microsoft.com/blog/2024/11/07/introducing-hyperlight-virtual-machine-based-security-for-functions-at-scale/)
- [youki — OCI runtime in Rust](https://github.com/youki-dev/youki)
- [Development Containers — spec and reference](https://containers.dev/)

## gVisor and userspace-kernel sandboxing

- [gVisor — docs](https://gvisor.dev/docs/)
- [gVisor — performance guide](https://gvisor.dev/docs/architecture_guide/performance/)

## Podman security and networking

- [Podman — rootless tutorial](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)
- [Red Hat — Rootless Podman user-namespace modes](https://www.redhat.com/en/blog/rootless-podman-user-namespace-modes)
- [podman-network — manpage](https://docs.podman.io/en/stable/markdown/podman-network.1.html)
- [libkrun on HVF — podman discussion #27679 (macOS bind-mount gaps)](https://github.com/containers/podman/discussions/27679)

## Upstream issues (podman + krun/crun; see also 60-podman-libkrun-operational-notes.md)

- [containers/crun #1098 — `podman exec` does not enter the VM](https://github.com/containers/crun/issues/1098)
- [libkrun/libkrun #104 — env dropped from image config](https://github.com/libkrun/libkrun/issues/104)
- [libkrun/libkrun #273 — `--` not forwarded correctly](https://github.com/libkrun/libkrun/issues/273)
- [containers/podman #28067 — TUI newline handling under krun](https://github.com/containers/podman/pull/28067)
- [containers/podman #21083 — `--init` unsupported under krun](https://github.com/containers/podman/pull/21083)
- [containers/podman #24618 — startup race on Fedora](https://github.com/containers/podman/pull/24618)

## Vulnerabilities and analyses

- [Sysdig — runc CVE-2025-31133, -52565, -52881 analysis](https://www.sysdig.com/blog/runc-container-escape-vulnerabilities)
- [CNCF — runc container breakout vulnerabilities, technical overview](https://www.cncf.io/blog/2025/11/28/runc-container-breakout-vulnerabilities-a-technical-overview/)
- [GHSA — CVE-2025-31133 advisory](https://github.com/advisories/GHSA-9493-h29p-rfm2)
- [GHSA — CVE-2025-52881 advisory](https://github.com/advisories/GHSA-cgrx-mc8f-2prm)
- [AWS — security bulletin 2026-015 (Firecracker CVE-2026-5747, virtio-pci OOB)](https://aws.amazon.com/security/security-bulletins/2026-015-aws/)
- [AWS — security bulletin 2026-003](https://aws.amazon.com/security/security-bulletins/rss/2026-003-aws/)
- [stack.watch — Firecracker CVEs](https://stack.watch/product/amazon/firecracker/)
- [Fedora advisory — libkrun 2025-f8be7978e3](https://linuxsecurity.com/advisories/fedora/fedora-41-libkrun-2025-f8be7978e3-security-advisory-updates-rh8lbifoalx6)
- [Fedora advisory — libkrun 2025-c53905e83d](https://linuxsecurity.com/advisories/fedora/fedora-41-libkrun-2025-c53905e83d-ohmxvt9uvrww)
- [emirb — Your Container Is Not a Sandbox: MicroVM Isolation in 2026](https://emirb.github.io/blog/microvm-2026/)
- [edera.dev — minimal is no longer enough](https://edera.dev/stories/minimal-is-no-longer-enough-why-ai-scale-vulnerability-discovery-changes-container-security)
- [Northflank — Best AI code-execution sandbox in 2026](https://northflank.com/blog/what-is-aws-firecracker)
- [Northflank — Kata vs Firecracker vs gVisor](https://northflank.com/blog/kata-containers-vs-firecracker-vs-gvisor)
- [Northflank — Firecracker vs QEMU](https://northflank.com/blog/firecracker-vs-qemu)
- [Northflank — guide to Cloud Hypervisor](https://northflank.com/blog/guide-to-cloud-hypervisor)
- [AWS — Enhancing Kubernetes workload isolation with Kata](https://aws.amazon.com/blogs/containers/enhancing-kubernetes-workload-isolation-and-security-using-kata-containers/)
