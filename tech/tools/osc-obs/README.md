# osc-obs — Open Build Service workflows

> <https://openbuildservice.org/> · <https://en.opensuse.org/openSUSE:OSC>

Notes on running an OBS home/test project end-to-end with `osc` from the command line —
authentication, project setup, link-based overlays, and the diagnose/recover loop for the classes of
build-system errors that can't be inferred from prior context.

## Index

- [setup-home-project-from-upstream.md](setup-home-project-from-upstream.md) — from-scratch
  walkthrough for a home OBS project that overlays one or more upstream packages with local patches.
  Covers project meta, base-package import vs branch, satellite `_link` topology with
  `<apply name="…patch"/>`, branched providers, the orphan-patch trap, and the verification
  sequence.
- [broken-state-link-drift.md](broken-state-link-drift.md) — what OBS's `broken` lane state means,
  the diagnostic recipe (verbose results + `?expand=1` body), and the `osc add` / `osc rm` /
  `osc ci` recovery for `_link.apply` ↔ source-tree drift. The class of error that bites you the
  second time you rename an overlay patch.
- [auth-in-devcontainers.md](auth-in-devcontainers.md) — decision matrix and Tier 1 (obfuscated
  config file) walkthrough for `osc` auth in dctl / VS Code devcontainers without a host keyring.
  Covers all five tiers, the `osc vc` / `obs-build` dependency, and the troubleshooting section for
  the `NoneType` seed bug and the `trusted-certs` permission error.
- [common-mistakes-and-pitfalls.md](common-mistakes-and-pitfalls.md) — the "what not to do"
  companion to the setup guide. Five categories (auth, workspace, CLI foot-guns, patch/link
  evolution, diagnostic discipline) with one entry per real incident: what happened, why it bit, the
  rule that prevents recurrence. Read end-to-end the first time; cheat-sheet thereafter.
- [libexpat-source-naming.md](libexpat-source-naming.md) — concrete instance of the binary-vs-source
  naming convention: the `libexpat1` RPM ships from source pkg `expat`, not `libexpat`.
  Authoritative probe (`/search/published/binary/id`), the
  `osc branch <src-prj> <src-pkg> <tgt-prj> <tgt-pkg>` rename trick that keeps downstream consumers
  referring to `libexpat`, cross-project version + CVE patch matrix, and why
  `SUSE:SLE-15-SP<n>:Update` beats `openSUSE:Factory` as a branch source for SLES overlay work.

## Companion files

- `~/DocsNNotes/tech/systems/linux/opensuse/opensuse-build-service-obs.md` — curated upstream-URL
  index for OBS / osc / packaging documentation (kept in the openSUSE subtree because the curated
  links live there); cross-links into this `osc-obs` subtree.
- `~/DocsNNotes/tech/tools/dctl.md` — `dctl` CLI surface used by `auth-in-devcontainers.md` when the
  host runs containers via dctl rather than vanilla VS Code remote-containers.

## Audience

These notes are project-agnostic. Each home OBS project that uses this pattern carries its own
applied-version companion (a setup walkthrough pinned to its concrete project / package / patch
names, plus a chronological mistakes-log when one exists) in its own repo under `docs/` — keep those
there, not here.
