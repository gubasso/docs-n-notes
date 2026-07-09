---
digest-of: tech/systems/linux/opensuse
last-synced: 2026-07-09
source-files:
  - README.md
  - linux-opensuse.md
  - opensuse-build-service-obs.md
  - opensuse-tumbleweed-installation-settings.md
  - opensuse-tumbleweed-minimal-workable-antivirus-antimalware-setup-clamav.md
  - opensuse-tumbleweed-partition-table.md
  - sles-cloud.md
token-estimate: 600
---

# AGENTS

## Scope

openSUSE and SLES reference notes: installation settings, OBS upstream-URL index, Tumbleweed
partition / install reference, ClamAV setup, SLES cloud notes.

## Key Points

- **OBS upstream-URL index** (`opensuse-build-service-obs.md`): curated upstream references — user
  guide chapters (current `cha-obs-*` slug convention, no `.html`), packaging guidelines, Python
  packaging portal, OBS user guide chapters on `osc`, basic workflow, source services, SCM/CI, `osc`
  example commands, and maintenance support. Pointer-only for the `osc` CLI reference: deep `osc`
  material lives at `tech/tools/osc-obs/`, single source of truth.
- **General openSUSE notes**: distro-specific tips.
- **Tumbleweed installation**: install settings + partition-table notes.
- **ClamAV**: minimal antivirus setup.
- **SLES cloud**: cloud-specific note.

## Source Map

| Topic                       | File                                                                         |
| --------------------------- | ---------------------------------------------------------------------------- |
| openSUSE index              | `README.md`                                                                  |
| General openSUSE notes      | `linux-opensuse.md`                                                          |
| OBS upstream-URL index      | `opensuse-build-service-obs.md`                                              |
| Tumbleweed install settings | `opensuse-tumbleweed-installation-settings.md`                               |
| Tumbleweed partition table  | `opensuse-tumbleweed-partition-table.md`                                     |
| Minimal ClamAV setup        | `opensuse-tumbleweed-minimal-workable-antivirus-antimalware-setup-clamav.md` |
| SLES cloud                  | `sles-cloud.md`                                                              |

## Maintenance Notes

- Keep the index aligned with the current markdown notes.
- Regenerate when any source file in this directory changes.
- For OBS/`osc` deep reference, point readers at `~/DocsNNotes/tech/tools/osc-obs/` rather than
  duplicating content here — `opensuse-build-service-obs.md` is intentionally an upstream-URL index
  plus a pointer (the older walkthrough sections were removed on 2026-06-09 to keep DRY).
