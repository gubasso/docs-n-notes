# openSUSE Build Service

> <https://build.opensuse.org/> <https://openbuildservice.org/>

- Tutorials:
  - *** [Open Build Service: User Guide](https://openbuildservice.org/help/manuals/obs-user-guide/)
  - [openSUSE:Build Service Tutorial](https://en.opensuse.org/openSUSE:Build_Service_Tutorial)

- [openSUSE Build Service Cheat Sheet](https://en.opensuse.org/images/d/df/Obs-cheat-sheet.pdf)
- [openSUSE:Packaging guidelines](https://en.opensuse.org/openSUSE:Packaging_guidelines)
  - [openSUSE:Packaging checks](https://en.opensuse.org/openSUSE:Packaging_checks)
  - [openSUSE:Specfile guidelines](https://en.opensuse.org/openSUSE:Specfile_guidelines)
    - Specfile Template
    - [openSUSE:Packaging Conventions RPM Macros](https://en.opensuse.org/openSUSE:Packaging_Conventions_RPM_Macros)
    - [openSUSE:Package source verification](https://en.opensuse.org/openSUSE:Package_source_verification)
      - keyring
      - hello example: `So looking at GNU Hello (RPM package "hello"):`

## Companion subtree (canonical OBS/osc notes)

- [`~/DocsNNotes/tech/tools/osc-obs/`](../../tools/osc-obs/README.md) — dedicated OBS/osc subtree:
  - [`setup-home-project-from-upstream.md`](../../tools/osc-obs/setup-home-project-from-upstream.md)
    — from-scratch home-project walkthrough (project meta, base import vs branch, satellite
    `_link` + `<apply>`, branched providers, verification sequence).
  - [`broken-state-link-drift.md`](../../tools/osc-obs/broken-state-link-drift.md) — the `broken`
    lane state (pre-build link-expansion failure), diagnostic recipe, and
    `osc add`/`osc rm`/`osc ci` recovery.
  - [`auth-in-devcontainers.md`](../../tools/osc-obs/auth-in-devcontainers.md) — auth / `oscrc` /
    KWallet-free credential setup in devcontainers.
  - [`common-mistakes-and-pitfalls.md`](../../tools/osc-obs/common-mistakes-and-pitfalls.md) —
    distilled lessons from real incidents (auth, workspace, CLI foot-guns, patch/link evolution,
    diagnostic discipline).
  - [`libexpat-source-naming.md`](../../tools/osc-obs/libexpat-source-naming.md) — the `libexpat1`
    binary RPM ships from source pkg `expat`; `osc branch` with target-rename trick; cross-project
    version / CVE-2025-59375 patch matrix; why `SUSE:SLE-15-SP<n>:Update` beats `openSUSE:Factory`
    for SLES overlay work.
  - [`case-studies/`](../../tools/osc-obs/case-studies/README.md) — narrative reflections on real
    OBS home-project incidents (goal → mistakes → fix → rule distilled → happy path → final result).
    Read once per topic to install the lesson; the topic notes above are the reference cards. Covers
    `broken` link drift after a patch rename, and overriding a buildroot ABI by branching a SUSE
    Update package into the home project.

## More upstream references

- [openSUSE Packaging Portal](https://en.opensuse.org/Portal:Packaging) — comprehensive index of
  packaging topics.
- [openSUSE Python Packaging](https://en.opensuse.org/Portal:Packaging_Python) — Python-specific
  packaging guidance.
- [openSUSE Patch Guidelines](https://en.opensuse.org/openSUSE%3APackaging_Patches_guidelines) — how
  to annotate and manage patches.
- [openSUSE Git Packaging Workflow](https://en.opensuse.org/openSUSE%3AGit_Packaging_Workflow).
- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/) — spec file syntax, macros.
- [Fedora RPM Macros](https://docs.fedoraproject.org/en-US/packaging-guidelines/RPMMacros/) —
  applies broadly to RPM-based distros.
- [Fedora — Staying Close to Upstream](https://docs.fedoraproject.org/en-US/package-maintainers/Staying_Close_to_Upstream_Projects/).
- [OBS User Guide — `osc`, the Command Line Tool](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-osc).
- [OBS User Guide — Basic Workflow](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-basicworkflow).
- [OBS User Guide — Using Source Services](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-source-services).
- [OBS User Guide — SCM/CI Integration](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-scm-ci-workflow-integration).
- [OBS User Guide — `osc` Example Commands](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-best-practices-oscexamples).
- [OBS User Guide — Maintenance Support](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-maintenance-setup).
- [How to Modify a Package in OBS (quilt + osc)](https://documentation.suse.com/sbp/systems-management/html/SBP-Quilting-OSC/index.html)
  — SUSE Best Practices walkthrough.

## Talks & videos

- [openSUSE Conference 2025 — OBS to Git](https://www.youtube.com/watch?v=x9LXrFDhoBE).

## General

```text
Sometimes, you will see the obs://DOMAIN/PROJECT notation. The obs:// schema is a shorthand to abbreviate the long URL and needs to be replaced by the real OBS instance URL.
```

## openSUSE Commander (OSC) — pointer

> `osc`

For the `osc` verb cheat sheet (branch / co / build / commit / sr / etc.), home-project setup,
patch/link mechanics, build-state diagnostics, and metadata templates, see the dedicated subtree:
**[`~/DocsNNotes/tech/tools/osc-obs/`](../../tools/osc-obs/README.md)**.

Upstream references:

- [openSUSE:OSC](https://en.opensuse.org/openSUSE:OSC) — wiki overview.
- [openSUSE/osc](https://github.com/openSUSE/osc) — source.
- [osc(1) manpage (Tumbleweed)](https://manpages.opensuse.org/Tumbleweed/osc/osc.1.en.html).
- [oscrc(5) manpage (Tumbleweed)](https://manpages.opensuse.org/Tumbleweed/osc/oscrc.5.en.html).

## Contribution flow at a glance

The standard openSUSE contribution path, from a home project:

1. Browse the source package page on `build.opensuse.org`.
2. Create a personal branch into your home project (`osc branch`).
3. Edit the spec / add a `PatchN:` for your fix.
4. Build locally to verify (`osc build`).
5. Commit (`osc commit`) and wait for the OBS build to go green.
6. Submit a request back to the origin project (`osc sr`).

Detailed walkthroughs are in `~/DocsNNotes/tech/tools/osc-obs/setup-home-project-from-upstream.md`
(full home-project setup) and `~/DocsNNotes/tech/tools/osc-obs/obs-github-coordination.md`
(upstream-PR-vs-OBS-patch lifecycle).
