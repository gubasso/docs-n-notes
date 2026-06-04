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
- [blocked-state-is-transient.md](blocked-state-is-transient.md) — `osc results` reporting
  `blocked: <dep>` on a lane is a scheduler-waiting state (not terminal). Default 15–20 min wait
  before any intervention; `osc rebuild` is harmful when issued over an in-flight auto-rebuild.
  Decision table for wait vs probe vs escalate.
- [sle-update-pool-vs-standard.md](sle-update-pool-vs-standard.md) — `SUSE:SLE-15-SP<n>:Update` (and
  other `kind="maintenance_release"` projects) typically has project-level publish disabled; its
  `standard` repo is empty. Maintenance binaries live under the `pool` repo. The canonical
  consumer-side resolver `<path>` is
  `<path project="<source-distro>:<version>:Update" repository="pool"/>`. Includes the probe recipe
  and the trade-off vs `osc branch` for the same purpose.
- [case-studies/](case-studies/) — narrative reflections on real incidents (goal → mistakes → fix →
  rule distilled → happy path → final result). Read once per topic to install the lesson; the topic
  notes above are the reference cards you grep for afterwards. Current entries:
  - [`01-broken-link-drift-after-patch-rename.md`](case-studies/01-broken-link-drift-after-patch-rename.md)
    — every lane went `broken: patch '<new>' does not exist` after a converger renamed an overlay
    patch but didn't `osc rm` the old one. The `broken` state is pre-build, distinct from
    `unresolvable` / `failed`, with its own diagnostic recipe and one-commit workspace recovery.
  - [`02-libexpat-abi-override-via-sles-update-branch.md`](case-studies/02-libexpat-abi-override-via-sles-update-branch.md)
    — overriding a buildroot ABI by branching a SUSE Update package into the home project. Two
    foot-guns: binary RPM name ≠ source pkg name (`libexpat1` ships from `expat`), and
    `openSUSE:Factory` is rarely the right branch source for SLES overlay work. The 4-arg
    `osc branch` rename form solves both.

## Companion files

- `~/DocsNNotes/tech/systems/linux/opensuse/opensuse-build-service-obs.md` — curated upstream-URL
  index for OBS / osc / packaging documentation (kept in the openSUSE subtree because the curated
  links live there); cross-links into this `osc-obs` subtree.
- `~/DocsNNotes/tech/tools/dctl.md` — `dctl` CLI surface used by `auth-in-devcontainers.md` when the
  host runs containers via dctl rather than vanilla VS Code remote-containers.
- [`runbook-template.md`](runbook-template.md) — generic shape for a per-lane convergence runbook
  driven by a Claude self-debug loop. Placeholder-based so it can be copied into any OBS overlay
  project's `docs/` tree.
- [`../../workflows/claude-self-debug-loop.md`](../../workflows/claude-self-debug-loop.md) —
  architecture of the self-debug loop that consumes the runbook above (driver, log persistence,
  failure handling, budget guardrails). Pairs with the `osc-obs` Claude Code skill in dotfiles for
  side-effecting OBS verbs.

## Audience

These notes are project-agnostic. Each home OBS project that uses this pattern carries its own
applied-version companion (a setup walkthrough pinned to its concrete project / package / patch
names, plus a chronological mistakes-log when one exists) in its own repo under `docs/` — keep those
there, not here.
