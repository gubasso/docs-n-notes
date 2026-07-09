# OBS `broken` lane state — link / source-tree drift

> <https://en.opensuse.org/openSUSE:Build_Service_Concept_SourceService>
> <https://en.opensuse.org/openSUSE:OSC>

## tl;dr

`broken` is a **pre-build** state. The OBS scheduler reports it when the source service cannot
produce an expanded source tree, so neither the resolver nor the build ever ran. For `_link`-based
packages, the dominant trigger is **`_link.apply` references a file that isn't in the package's
source tree** (or vice versa).

Diagnose with `osc results -v …` — the precise message lands in the status column. Confirm
authoritatively with `osc api '/source/<prj>/<pkg>?expand=1'` — HTTP 400 body carries the same
message. Then recover with `osc add` / `osc rm` / `osc ci` in the package's local workspace.

## Signatures

| Status column from `osc -v results`     | Root cause                                                                                                                |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `broken: patch '<file>' does not exist` | `_link.apply` references a `*.patch` that was never `osc ci`'d (or was removed).                                          |
| `broken: file '<file>' does not exist`  | `_link` references a base file (tarball, spec) missing from the source tree.                                              |
| `broken: bad link: …`                   | Generic link-expansion failure — wrong source project, wrong `linkrev`, malformed `_link` XML.                            |
| `broken: patch '<file>' does not apply` | Patch present, but `patch -p1` fails against the expanded link source (context drift after the linked-from source moves). |

## Diagnostic recipe

```bash
PRJ=home:<you>:<project>
PKG=<package>
OBS_API=https://api.opensuse.org

osc -A "${OBS_API}" -v results "${PRJ}" "${PKG}"
osc -A "${OBS_API}" api "/source/${PRJ}/${PKG}?expand=1" 2>&1 | head -20
osc -A "${OBS_API}" api "/source/${PRJ}/${PKG}"
( cd "${WORKSPACE}/${PRJ}/${PKG}" && osc -A "${OBS_API}" status )
osc -A "${OBS_API}" log "${PRJ}" "${PKG}" | head
osc -A "${OBS_API}" api "/source/${PRJ}/${PKG}?rev=<prev>"
```

The (`api /source/...`) listing tells you what's actually tracked on the server; `osc status` tells
you what the local workspace thinks. Compare against `_link.apply` (`cat _link`) to spot the drift.

## Recovery — `patch '…' does not exist`

The most common path: `_link.apply` was bumped to a new patch filename but the new patch was never
uploaded and/or the old patch was never removed. From the workspace:

```bash
cd "${WORKSPACE}/${PRJ}/${PKG}"
osc -A "${OBS_API}" add <new>.patch        # local `?` → `A`
osc -A "${OBS_API}" rm  <old>.patch        # local `!`-tracked → `D`
osc -A "${OBS_API}" ci  -m "Sync source tree with _link: add <new>, drop <old> (recover from broken link state)"
osc -A "${OBS_API}" results --watch "${PRJ}" "${PKG}"
```

`osc rm` handles a locally-missing tracked file (`!`) without `--force`. Lanes transition from
`broken` → `scheduled` → `building` in seconds.

## How to prevent this in your bootstrap / converger script

If you have a script that converges OBS overlay state (overwrites `_link`, drops in `${patch_name}`,
commits), the asymmetry that caused this incident is: the script `osc add`s the new patch but never
`osc rm`s the old one. Enumerate the server-tracked files filtered to `*.patch` and remove any that
aren't the current `${patch_name}`:

```bash
while IFS= read -r tracked_patch; do
  [[ -z "${tracked_patch}" ]] && continue
  [[ "${tracked_patch}" == "${patch_name}" ]] && continue
  case "${tracked_patch}" in
    *.patch)
      osc rm "${tracked_patch}" 2>/dev/null \
        || osc rm --force "${tracked_patch}"
      ;;
  esac
done < <(osc ls "${HOME_PROJECT}" "${pkg}" 2>/dev/null || true)
```

## Caveat: `osc vc` requires `obs-build`

`osc vc -m …` updates `.changes` via `/usr/lib/build/vc`, which ships in the `obs-build` package. In
a stripped-down container that has `osc` but not `obs-build`, `osc vc` fails with
`Error: vc ('/usr/lib/build/vc') command not found / Install the
build package from
http://download.opensuse.org/repositories/openSUSE:/Tools/`.
`osc ci` itself works fine — only the changelog entry is skipped. Real package-maintenance flows
should run on a host with `obs-build` installed.

## When this typically happens

Most often when an overlay patch is renamed (e.g. to reflect a widened `%if 0%{?sle_version}` gate,
or a different distro target) and the rename commit updates `_link.apply` + adds the new patch but
forgets to `osc rm` the old one — so the source tree has the old `*.patch` still tracked,
`_link.apply` points at the new name, and the source service can't reconcile the two. Every lane
goes `broken: patch '<new>' does not exist` simultaneously. The recovery (above) is one extra
`osc rm` + a re-commit.

The same class of failure also catches converger scripts that `osc add` the new patch but never
enumerate / `osc rm` orphan patches. If your converger automates patch evolution, audit it for this
asymmetry — see also [`common-mistakes-and-pitfalls.md`](./common-mistakes-and-pitfalls.md) §2.2
("Converger script that `osc add`s but never `osc rm`s").
